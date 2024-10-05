package states;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSpriteExt;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import objects.*;
import objects.ui.*;
import song.*;
import song.Chart.ChartEvents;
import song.Chart.ChartNote;
import song.Chart.ChartParser;
import song.Song;
import util.CoolUtil;
import util.HscriptHandler;
import util.Options;

typedef NoteGroup = FlxTypedGroup<Note>;
typedef InGameEvent = {t:Float, e:String, data:Dynamic, ?spawned:Bool}

class PlayState extends FlxState {
	public static var instance:PlayState;

	var strumGroup = new FlxTypedGroup<StrumLine>();
	var noteGroup:NoteGroup = new NoteGroup();
	var vocals:Array<FlxSound> = [];

	var options:Options;

	var health(default, set):Float = 0.5;

	function set_health(v:Float):Float {
		health = FlxMath.bound(v, 0, 1);
		healthBar.percent = health;
		if (health <= 0)
			initDeath();
		return health;
	}

	var score(default, set):Int = 0;

	function set_score(v:Int):Int {
		var oldScore = score;
		var diff = v - oldScore;

		scoreNum.number = v;

		scoreNum.updateHitbox();

		FlxTween.cancelTweensOf(scoreNum);
		FlxTween.cancelTweensOf(scoreNum.colorTransform);

		scoreNum.offset.y += 3;
		if (diff > 0)
			scoreNum.setColorTransform(1, 1, 1, 1, 20, 125, 90);
		else if (diff < 0)
			scoreNum.setColorTransform(1, 0.8, 0.9, 1, 125, 0, 90);

		FlxTween.tween(scoreNum, {"offset.y": scoreNum.offset.y - 7}, 0.4, {ease: FlxEase.elasticOut});
		FlxTween.tween(scoreNum.colorTransform, {redOffset: 0, greenOffset: 0, blueOffset: 0}, 1, {ease: FlxEase.expoOut});

		return score = v;
	}

	var healthBar:HealthBar = new HealthBar();
	var scoreNum:Counter = new Counter();
	var timeNum:Counter = new Counter();

	var camGame:FlxCamera;
	var camHUD:FlxCamera;
	var camOverlay:FlxCamera;

	var defaultZoom:Float = 1;
	var defaultHudZoom:Float = 1;

	var currentZoom:Float = 1;
	final defaultCamIntensity:Float = 1.023;
	var camBopData = {
		_mult: 1.0,
		rate: 4,
		intensity: 1.023,
		lerp: 2.4,
		enabled: true
	};

	var scripts:Array<HscriptHandler> = [];

	public function call(f:String, ?args:Array<Dynamic>):Dynamic {
		for (i in scripts) {
			if (i != null) {
				i.call(f, args);
			}
		}
		// ??????
		FunkinStage.call(f, args);
		return 0;
	}

	public function addScript(file:String, ?root:String = 'data/scripts'):HscriptHandler {
		var h:HscriptHandler = new HscriptHandler(file, root);
		h.setVariable('this', instance);
		scripts.push(h);

		return h;
	}

	public function addScriptPack(root:String) {
		for (i in Paths.read(root)) {
			if (i.endsWith('.hx')) {
				addScript(i.replace('.hx', ''), root);
			}
		}
	}

	public function new() {
		super();
		instance = this;
	}

	var ratingSpr:FlxSprite;
	var comboNum:Counter;

	var eventsList:Array<InGameEvent> = [];

	var followPoint:FlxObject;

	override public function create() {
		super.create();

		camGame = FlxG.camera;
		camGame.bgColor = FlxColor.fromHSB(0, 0, 0.4);

		camHUD = new FlxCamera();
		camHUD.bgColor = 0x00000000;
		FlxG.cameras.add(camHUD, false);

		camOverlay = new FlxCamera();
		camOverlay.bgColor = 0x00000000;
		FlxG.cameras.add(camOverlay, false);

		followPoint = new FlxObject(0, 0, 1, 1);
		followPoint.screenCenter();

		camGame.follow(followPoint, LOCKON, 0.06);

		FunkinStage.init(Song.meta.stage);

		var chars:Array<{char:Character, pos:Array<Float>, flip:Bool}> = [];

		for (idx => i in Song.chart.lanes) {
			var lane = new StrumLine(i);
			var shit = {char: lane.char, pos: FunkinStage.positions.get(i.pos) ?? [0, 0], flip: FunkinStage.flipPos.contains(i.pos)};
			if (~/[0-9]+\s*,\s*[0-9]+/g.match(i.pos)) {
				shit.pos = i.pos.split(',').map((a) -> {
					return Std.parseFloat(a);
				});
			}
			chars.insert(0, shit);
			if (lane.vocals != null)
				vocals.push(lane.vocals);
			lane.ID = idx;
			lane.y = 50;
			lane.screenCenter(X);
			if (lane.data.strumPos != null) {
				switch (lane.data.strumPos) {
					case 'left':
						lane.x = 50;
					case 'right':
						lane.x = (FlxG.width * .5) + 50;
					default:
						lane.x += 0;
				}
			}
			lane.visible = lane.data.visible ?? true;
			strumGroup.add(lane);
		}

		add(strumGroup);
		add(noteGroup);

		noteGroup.memberAdded.add(function(note) {
			@:privateAccess {
				note.parentGroup = noteGroup;
			}
		});

		for (i in Song.parsedNotes) {
			i.spawned = false;
		}

		Conductor.bpm = Song.chart.bpm[0].bpm;
		Conductor.paused = false;
		Conductor.tracker = FlxG.sound.music;
		Conductor.beatHit.add(beatHit);

		defaultZoom = currentZoom = camGame.zoom = FunkinStage.zoom;

		add(healthBar);
		healthBar.x = 50;
		healthBar.y = FlxG.height - healthBar.frameHeight - 50;
		healthBar.rightToLeft = true;
		healthBar.percent = health;

		add(scoreNum);
		scoreNum.scale.set(0.5, 0.5);
		scoreNum.updateHitbox();
		scoreNum.x = 50;
		scoreNum.y = healthBar.y - scoreNum.height - 15;

		add(timeNum);
		timeNum.scale.set(0.25, 0.25);
		timeNum.updateHitbox();
		timeNum.x = scoreNum.x;
		timeNum.y = scoreNum.y - timeNum.height - 15;
		timeNum.display = TIME;
		timeNum.setColorTransform(-1, -1, -1, 1, 255, 255, 255);

		// help
		ratingSpr = new FlxSprite();
		ratingSpr.antialiasing = true;
		ratingSpr.loadGraphic(Paths.image('ui/ratings/shit'));
		Paths.image('ui/ratings/good');
		Paths.image('ui/ratings/bad');
		Paths.image('ui/ratings/sick');
		insert(0, ratingSpr);
		ratingSpr.scale.set(0.55, 0.55);
		ratingSpr.updateHitbox();

		comboNum = new Counter();
		comboNum.scale.set(0.5, 0.5);
		comboNum.updateHitbox();
		comboNum.alignment = CENTER;
		insert(0, comboNum);

		ratingSpr.alpha = comboNum.alpha = 0.001;

		for (i in [strumGroup, healthBar, scoreNum, timeNum, ratingSpr, comboNum]) {
			i.camera = camHUD;
		}

		doNoteTransition();

		for (idx => i in chars) {
			if (i.char != null) {
				var char = i.char;
				char.setStagePosition(i.pos[0], i.pos[1]);
				add(char);
				if (char.script != null) {
					scripts.push(char.script);
				}
				if (i.flip) {
					char.flipX = !char.flipX;
				}
			}
		}

		for (idx => i in Song.events.events) {
			for (ev in (i : Array<Dynamic>)) {
				eventsList.push({
					t: ev[0],
					e: Song.events.order[idx],
					data: ev[2],
					spawned: false
				});
			}
		}

		FlxG.sound.playMusic(Paths.song(Song.song, 'Inst', Song.variation), 0);

		FlxG.sound.music.time = Conductor.time = 0;
		resyncVox();
		FlxG.sound.music.volume = 1;

		addScriptPack('songs/${Song.song}/scripts');

		for (str in strumGroup.members) {
			str.forEach((i) -> {
				i.noteHit.add(noteHit);
				i.noteHeldStep.add(noteHeldStep);
				i.noteHeld.add(noteHeldUpdate);
				i.noteMiss.add(noteMiss);
			});
		}

		call('create');
	}

	static function resyncVox() {
		for (v in instance.vocals) {
			if (v != null) {
				v.pause();
				v.time = Conductor.time;
				v.play();
			}
		}
	}

	function beatHit() {
		if (camBopData.rate > 0 && Conductor.beat % camBopData.rate == 0) {
			camBopData._mult += (camBopData.intensity - 1);
			camHUD.zoom += (camBopData.intensity - 1) * 2;
		}
	}

	var combo:Int = 0;

	function popupScore(rating:String) {
		comboNum.number = combo;
		ratingSpr.loadGraphic(Paths.image('ui/ratings/$rating'));
		ratingSpr.updateHitbox();
		ratingSpr.screenCenter();
		ratingSpr.y = 100 - (ratingSpr.height * .5);

		comboNum.x = FlxG.width * .5;
		comboNum.y = 150;

		// fnf
		ratingSpr.x -= 42;
		comboNum.x -= 42;

		ratingSpr.moves = comboNum.moves = ratingSpr.active = comboNum.active = true;
		ratingSpr.velocity.y = -60;
		ratingSpr.acceleration.y = ratingSpr.maxVelocity.y = 200;

		comboNum.velocity.y = -80;
		comboNum.acceleration.y = comboNum.maxVelocity.y = 150;

		for (idx => bleh in [ratingSpr, comboNum]) {
			FlxTween.cancelTweensOf(bleh);
			bleh.alpha = 1;
			FlxTween.tween(bleh, {alpha: 0}, 0.3, {
				startDelay: 0.4 + (idx * 0.1),
				onComplete: (_) -> {
					bleh.moves = bleh.active = false;
				}
			});
		}
		call('popupScore', []);
	}

	function noteHit(note:Note) {
		var lane = note.strum.parentLane;
		var char:Character = note.character;
		call('preNoteHit', [note, lane]);
		if (!lane.autoHit) {
			var gwa = 0.01;
			score += note?.score(Conductor.time - note.strumTime) ?? 0;
			health += gwa;
			combo += 1;
			if (lane.vocals != null)
				lane.vocals.volume = 1;

			var judge = note.judge(Conductor.time - note.strumTime);
			note.rating = judge;
			popupScore(judge ?? 'sick');
		}

		if (note.anim != null && char != null) {
			char.holdTime = Conductor.stepCrochetSec * char.holdDur;
			char.playAnim(note.anim, true);
		}

		call('noteHit', [note, lane]);
	}

	function noteHeldStep(note:Note) {
		var lane = note.strum.parentLane;
		var char:Character = note.character;

		if (note.anim != null && char != null) {
			char.holdTime = Conductor.stepCrochetSec * char.holdDur;
			char.playAnim(note.anim, true);
		}

		call('noteHeld', [note, lane]);
	}

	function noteHeldUpdate(note:Note) {
		var lane = note.strum.parentLane;
		if (!lane.autoHit) {
			health += (7.5 / 100) * FlxG.elapsed;
			var tempS:Float = score + (250 * FlxG.elapsed);
			score = Std.int(tempS);
		}

		call('noteHeldUpdate', [note, lane]);
	}

	var lastMissChar:Character;

	function noteMiss(note:Note) {
		var lane = note.strum.parentLane;
		if (!lane.autoHit) {
			var gwa = 0.02;
			score -= 10;
			health -= gwa;
			combo = 0;
			if (lane.vocals != null)
				lane.vocals.volume = 0;
		}

		if (note.character != null && note.anim != null && note.character.animation.exists(note.anim + 'miss')) {
			note.character.playAnim(note.anim + 'miss', true);
			note.character.holdTime = Conductor.stepCrochetSec * note.character.holdDur;
		}

		lastMissChar = note.character;

		call('noteMiss', [note, lane]);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		camBopData._mult = FlxMath.lerp(camBopData._mult, 1, elapsed * camBopData.lerp);
		camGame.zoom = currentZoom * camBopData._mult;
		camHUD.zoom = FlxMath.lerp(camHUD.zoom, defaultHudZoom, elapsed * camBopData.lerp);
		if (!died) {
			for (idx => note in Song.parsedNotes) {
				if (Conductor.time >= note.time - (3000 / Song.chart.speed) && !note.spawned) {
					note.spawned = true;
					spawnNote(note);
				}
			}

			for (idx => event in eventsList) {
				if (Conductor.time >= event.t && !event.spawned) {
					event.spawned = true;
					triggerEvent(event);
				}
			}

			timeNum.number = Math.floor(Conductor.time * 0.001);

			if (FlxG.keys.justPressed.R)
				health = 0;

			// todo: rework chartingstate maybe
			if (FlxG.keys.justPressed.SEVEN) {
				FlxG.sound.music.stop();
				FlxG.switchState(new states.ChartingState(Song.chart));
			}

			if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.ENTER) {
				openSubState(new substates.PauseSubstate());
			}

			call('update', [elapsed]);
		} else {
			call('deadUpdate', [elapsed]);
		}

		if (FlxG.keys.justPressed.F5)
			FlxG.resetState();
	}

	function spawnNote(i:ChartNote):Note {
		var group = strumGroup.members[i.lane] ?? strumGroup.members[0];
		var strum = group.members[i.index % group.members.length];

		var note = noteGroup.recycle(Note);
		note.strumIndex = i.index % group.members.length;
		note.strumTime = i.time;
		note.strum = strum;
		note.sustain.length = i.length;
		note.speed = Song.chart.speed;
		if (note.strum != null)
			note.rgb.copy(strum.rgb);
		note.y -= 2000;
		note.sustain.x -= 2000;

		note.camera = note.sustain.camera = camHUD;

		note.anim = switch (i.index) {
			case 0: 'singLEFT';
			case 1: 'singDOWN';
			case 2: 'singUP';
			case 3: 'singRIGHT';
			case _: null;
		}

		note.character = strum.parentLane.char;
		strum.notes.push(note);
		noteGroup.add(note);

		call('spawnNote', [note, i]);

		return note;
	}

	function triggerEvent(event:InGameEvent) {
		// trace('event !!!! $event');

		final data = event.data;
		switch (event.e) {
			case 'FocusCamera':
				var resultX:Float = FlxG.width * .5;
				var resultY:Float = FlxG.height * .5;
				var charNum:Int = (data is Int) ? cast(data, Int) : (data.char : Int);

				if (data.x != null)
					resultX = data.x;

				if (data.y != null)
					resultY = data.y;

				if (charNum != -1) {
					final lane:StrumLine = strumGroup.members[charNum];
					final char:Character = lane.char;
					if (char != null) {
						final mid = char.getMidpoint();
						resultX += mid.x;
						resultY += mid.y;

						if (FunkinStage.camOffsets.exists(lane.data.pos)) {
							final awa:Array<Float> = FunkinStage.camOffsets.get(lane.data.pos) ?? [0, 0];
							resultX += awa[0];
							resultY += awa[1];
						}
					}
				}

				followPoint.setPosition(resultX, resultY);

			case 'ZoomCamera':
				var resultZoom:Float = defaultZoom;
				if (data.mode == 'stage')
					resultZoom *= data.zoom;
				else {
					resultZoom = data.zoom;
				}

				final ease = Reflect.field(FlxEase, data.ease) ?? FlxEase.linear;
				if (data.duration > 0) {
					FlxTween.cancelTweensOf(this, ['currentZoom']);
					FlxTween.tween(this, {currentZoom: resultZoom}, Conductor.stepCrochetSec * data.duration, {ease: ease});
				}
			case 'SetCameraBop':
				camBopData.rate = (data.rate : Int) ?? 4;
				camBopData.intensity = (defaultCamIntensity - 1) * ((data.intensity : Float) ?? 1.0) + 1;
		}

		call('event', [event]);
	}

	public static var cachedTransNotes:Array<Array<Dynamic>> = [];

	public function cacheTransNotes() {
		cachedTransNotes = [];
		noteGroup.forEach((n) -> {
			final time = (n.strumTime - Conductor.time);
			if ((time <= (Conductor.crochet * 3)) && (time >= Conductor.crochet * -1)) {
				if (n.strum.parentLane.visible) {
					cachedTransNotes.push([n.x, n.y, n.strumIndex, n.sustain.length, n.speed, n.rgb.r]);
					// trace('a ${n.strumTime}');
				}
			}
		});
	}

	var fakeNoteGroup:NoteGroup;

	// im not adding note splashes :3
	var fakeSplashGroup:FlxSpriteGroup;

	public function doNoteTransition() {
		fakeSplashGroup = new FlxSpriteGroup();
		insert(0, fakeSplashGroup);

		fakeNoteGroup = new NoteGroup();
		insert(0, fakeNoteGroup);

		fakeNoteGroup.camera = fakeSplashGroup.camera = camHUD;

		// order: x, y, index, length, speed, rgb
		for (bleh in cachedTransNotes) {
			var note = fakeNoteGroup.recycle(Note);
			note.strumIndex = bleh[2];
			note.setPosition(bleh[0], bleh[1]);
			note.sustain.length = bleh[3];
			note.speed = bleh[4];
			note.moves = true;
			note.acceleration.y = FlxG.random.float(500, 800);
			note.velocity.y = FlxG.random.float(-140, -240);
			note.velocity.x = FlxG.random.float(-1, 1) * 50;
			note.angularVelocity = note.scrollAngularVelocity = FlxG.random.float(-1, 1) * 400;
			if (FlxG.random.bool(50)) {
				// reroll
				note.scrollAngularVelocity = FlxG.random.float(-1, 1) * 200;
			}
			fakeNoteGroup.add(note);

			FlxTween.tween(note, {alpha: 0}, 0.2, {startDelay: 2.5});

			note.camera = note.sustain.camera = camHUD;

			var splash = CoolUtil.doSplash(note.getMidpoint().x, note.getMidpoint().y, bleh[5]);
			fakeSplashGroup.add(splash);
			splash.animation.finishCallback = function(a) {
				splash.kill();
				fakeSplashGroup.remove(splash);
				remove(splash);
				splash.destroy();
			}
		}

		new FlxTimer().start(3, (_) -> {
			fakeNoteGroup.forEachExists((n) -> {
				n.kill();
				fakeNoteGroup.remove(n);
				remove(n);
				n.destroy();
			});
		});

		// trace(fakeNoteGroup.members);

		cachedTransNotes = [];
	}

	public static function pause(p:Bool = true):Bool {
		if (PlayState.instance == null) {
			trace('why you tryna pause out of playstate bro');
			return p;
		}

		Conductor.paused = p;
		FlxG.sound.music.time = Conductor.time;
		resyncVox();

		FlxG.sound.list.forEach(snd -> {
			if (!p)
				snd.resume();
			else
				snd.pause();
		});

		if (!p)
			FlxG.sound.music.resume();
		else
			FlxG.sound.music.pause();

		// psych engine
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished)
			tmr.active = p);
		FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished)
			twn.active = p);

		instance.cacheTransNotes();
		instance.camGame.active = !p;

		instance.call('pause', [p]);

		return Conductor.paused;
	}

	override public function openSubState(SubState:FlxSubState) {
		SubState.camera = camOverlay;
		super.openSubState(SubState);
	}

	override function destroy() {
		call('destroy');
		scripts = FlxDestroyUtil.destroyArray(scripts);

		strumGroup.destroy();
		noteGroup.destroy();
		super.destroy();
		Paths.clear();
	}

	var died:Bool = false;

	function initDeath() {
		call('preDeath', []);
		if (!died) {
			died = true;
			call('death', []);
			Conductor.paused = true;
			cachedTransNotes = [];
			if (FlxG.sound.music != null)
				FlxTween.tween(FlxG.sound.music, {pitch: 0}, 0.5, {
					onComplete: (_) -> {
						FlxG.sound.music.volume = 0;
					}
				});

			strumGroup.forEachAlive((s) -> {
				s.forEachAlive((sn) -> {
					if (!s.autoHit) {
						sn.moves = true;
						sn.acceleration.y = FlxG.random.float(900, 1300);
						sn.velocity.y = FlxG.random.float(-160, -300);
						sn.velocity.x = FlxG.random.float(-1, 1) * 50;
						sn.angularVelocity = FlxG.random.float(-1, 1) * 40;
						for (n in sn.notes) {
							if (n != null) {
								n.strum = null;
								sn.notes.remove(n);
								n.moves = true;
								n.acceleration.y = FlxG.random.float(900, 1300);
								n.velocity.y = FlxG.random.float(0, -2) * 150 * n.speed;
								n.velocity.x = FlxG.random.float(-1, 1) * 80;
								n.angularVelocity = n.scrollAngularVelocity = FlxG.random.float(-1, 1) * 40;
								if (FlxG.random.bool(50)) {
									// reroll
									n.scrollAngularVelocity = FlxG.random.float(-1, 1) * 200;
								}
							}
						}
					} else {
						for (n in sn.notes) {
							if (n != null) {
								n.strum = null;
								sn.notes.remove(n);
								FlxTween.tween(n, {y: n.y - (100 * n.speed), alpha: 0}, 2, {ease: FlxEase.expoOut});
							}
						}
						FlxTween.tween(sn, {alpha: 0}, 0.2);
					}
					sn.notes = [];
				});
			});

			for (v in vocals) {
				if (v != null) {
					v.fadeOut(0.4);
				}
			}

			var excludeMembers:Array<FlxBasic> = [
				lastMissChar,
				scoreNum,
				timeNum,
				healthBar,
				strumGroup,
				fakeNoteGroup,
				fakeSplashGroup
			];

			forEachOfType(FlxSprite, (i:FlxSprite) -> {
				if (i == null || excludeMembers.contains(i))
					return;

				final fucj = function(_:FlxSprite) {
					if (_.colorTransform != null) {
						FlxTween.tween(_.colorTransform, {
							redMultiplier: 0,
							greenMultiplier: 0,
							blueMultiplier: 0,
							redOffset: 0,
							greenOffset: 0,
							blueOffset: 0
						}, 0.2, {
							onComplete: (why) -> {
								FlxG.camera.bgColor.alpha = 0;
								if (_.colorTransform != null) {
									FlxTween.tween(_.colorTransform, {
										alphaMultiplier: 0,
										alphaOffset: 0
									}, 0.2);
								}
							}
						});
					}
				}

				fucj(i);
			});

			FlxTween.cancelTweensOf(this, ['currentZoom']);
			FlxTween.cancelTweensOf(followPoint);

			FlxTween.tween(this, {currentZoom: 1}, 1, {ease: FlxEase.backInOut});
			if (lastMissChar != null) {
				final mid = lastMissChar.getMidpoint();
				FlxTween.tween(followPoint, {x: mid.x, y: mid.y}, 3, {
					ease: FlxEase.expoOut,
					startDelay: 1,
				});
			}
			call('postDeath', []);
		}
	}
}
