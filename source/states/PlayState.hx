package states;

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
import song.Chart.ChartNote;
import song.Chart.ChartParser;
import song.Song;
import util.HscriptHandler;
import util.Options;

typedef NoteGroup = FlxTypedGroup<Note>;

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

		defaultZoom = camGame.zoom = FunkinStage.zoom;

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

		if (cachedTransNotes.length > 0)
			doNoteTransition();

		for (idx => i in chars) {
			if (i.char != null) {
				var char = i.char;
				char.setStagePosition(i.pos[0], i.pos[1]);
				add(char);
				if (i.flip) {
					char.flipX = !char.flipX;
				}
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
		/*strumGroup.members[0].forEach((n) ->
			{
				n.scrollAngle = Conductor.beat % 2 == 0 ? -15 : 15;
		});*/

		if (Conductor.beat % 4 == 0) {
			camGame.zoom += 0.015;
			camHUD.zoom += 0.03;
		}
	}

	// later
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
	}

	function noteHit(note:Note) {
		var lane = note.strum.parentLane;
		var char:Character = note.character;

		if (!lane.autoHit) {
			var gwa = 0.01;
			score += note?.score(Conductor.time - note.strumTime) ?? 0;
			health += gwa;
			combo += 1;
			popupScore(note?.judge(Conductor.time - note.strumTime) ?? 'sick');
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
			char.holdTime = Conductor.crochetSec * 2;
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

	function noteMiss(note:Note) {
		var gwa = 0.02;
		score -= 10;
		health -= gwa;
		combo = 0;
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
		for (idx => note in Song.parsedNotes) {
			if (Conductor.time >= note.time - (3000 / Song.chart.speed) && !note.spawned) {
				note.spawned = true;
				spawnNote(note);
			}
		}
		camGame.zoom = FlxMath.lerp(camGame.zoom, defaultZoom, elapsed * 2.5);
		camHUD.zoom = FlxMath.lerp(camHUD.zoom, defaultHudZoom, elapsed * 2.5);

		timeNum.number = Math.floor(Conductor.time * 0.001);

		// todo: rework chartingstate maybe
		if (FlxG.keys.justPressed.SEVEN) {
			FlxG.sound.music.stop();
			FlxG.switchState(new states.ChartingState(Song.chart));
		}

		if (FlxG.keys.justPressed.F5)
			FlxG.resetState();

		if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.ENTER) {
			openSubState(new substates.PauseSubstate());
		}

		call('update', [elapsed]);
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
		note.rgb.copy(strum.rgb);
		note.y -= 2000;
		note.sustain.x -= 2000;

		note.camera = note.sustain.camera = camHUD;

		note.anim = switch (note.strumIndex) {
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

			var splash = fakeSplashGroup.recycle(FlxSprite);
			fakeSplashGroup.add(splash);
			splash.frames = Paths.sparrow('ui/splashEffect');
			splash.animation.addByPrefix('idle', 'splash ${FlxG.random.int(1, 2)}', 12, false);
			splash.animation.play('idle', true);
			splash.animation.finishCallback = function(a) {
				splash.kill();
				fakeSplashGroup.remove(splash);
				remove(splash);
				splash.destroy();
			}

			var rgb:FlxColor = bleh[5];
			splash.updateHitbox();
			splash.setColorTransform(1, 1, 1, 1, rgb.red, rgb.green, rgb.blue);
			splash.setPosition(note.getMidpoint().x, note.getMidpoint().y);
			splash.x -= splash.width * .5;
			splash.y -= splash.height * .5;

			splash.blend = SCREEN;
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
}
