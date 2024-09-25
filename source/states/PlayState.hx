package states;

import flixel.FlxSpriteExt;
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
import util.HscriptHandler;
import util.Options;

typedef NoteGroup = FlxTypedGroup<Note>;

class PlayState extends FlxState {
	public static var instance:PlayState;

	public static var chart:Chart = {
		speed: 1,
		notes: [{time: 0, index: 0}],
		bpm: 60
	};

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

	var player:Character;
	var opponent:Character;
	var spectator:Character;

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

		var options = Options.data;

		var opponentStrums = new StrumLine(4);
		var playerStrums = new StrumLine(4);

		opponentStrums.setPosition(50, 50);
		strumGroup.add(opponentStrums);
		opponentStrums.autoHit = true;
		opponentStrums.ID = 0;

		playerStrums.setPosition((FlxG.width * .5) + 50, 50);
		strumGroup.add(playerStrums);
		playerStrums.ID = 1;
		// playerStrums.autoHit = true;

		add(strumGroup);
		add(noteGroup);

		for (index => keys in options.keys) {
			var strum = playerStrums.members[index];
			strum.inputs = keys;
		}

		for (str in [opponentStrums, playerStrums]) {
			for (strum in str.members) {
				var rgbs = options.noteColors;
				var que = rgbs[strum.ID] ?? {base: 0x717171, outline: 0x333333};
				strum.rgb.set(que.base, -1, que.outline);
			}
		}
		noteGroup.memberAdded.add(function(note) {
			@:privateAccess {
				note.parentGroup = noteGroup;
			}
		});

		for (i in chart.notes) {
			i.spawned = false;
		}
		Conductor.bpm = chart.bpm;
		Conductor.paused = false;
		Conductor.tracker = FlxG.sound.music;
		Conductor.beatHit.add(beatHit);

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

		for (i in [opponentStrums, playerStrums, healthBar, scoreNum, timeNum, ratingSpr, comboNum]) {
			i.camera = camHUD;
		}

		FunkinStage.init('stage');

		add(spectator = new Character('gf'));

		add(opponent = new Character('dad'));

		add(player = new Character('bf'));
		player.flipX = !player.flipX;
		// player.scale.x *= -1;

		FlxG.sound.playMusic(Paths.song('darnell'), 0);

		var _vocals = new FlxSound().loadEmbedded(Paths.song('darnell', 'Voices-Play'));
		FlxG.sound.list.add(_vocals);
		_vocals.play();
		vocals.push(_vocals);

		var _vocals = new FlxSound().loadEmbedded(Paths.song('darnell', 'Voices-Opp'));
		FlxG.sound.list.add(_vocals);
		_vocals.play();
		vocals.push(_vocals);

		FlxG.sound.music.time = Conductor.time = 0;
		resyncVox();
		FlxG.sound.music.volume = 1;

		addScriptPack('songs/darnell/scripts');

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
				v.time = Conductor.time;
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
		var laneID = note.strum.parentLane.ID;
		var char:Character = note.character ?? player;

		if (laneID == 1) {
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

		call('noteHit', [note, laneID]);
	}

	function noteHeldStep(note:Note) {
		var laneID = note.strum.parentLane.ID;
		var char:Character = note.character ?? player;

		if (note.anim != null && char != null) {
			char.holdTime = Conductor.crochetSec * 2;
			char.playAnim(note.anim, true);
		}

		call('noteHeld', [note, laneID]);
	}

	function noteHeldUpdate(note:Note) {
		var laneID = note.strum.parentLane.ID;
		if (laneID == 1) {
			health += (7.5 / 100) * FlxG.elapsed;
			var tempS:Float = score + (250 * FlxG.elapsed);
			score = Std.int(tempS);
		}

		call('noteHeldUpdate', [note, laneID]);
	}

	function noteMiss(note:Note) {
		var gwa = 0.02;
		score -= 10;
		health -= gwa;
		combo = 0;
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
		for (idx => note in chart.notes) {
			if (Conductor.time >= note.time - (3000 / chart.speed) && !note.spawned) {
				note.spawned = true;
				spawnNote(note);
			}
		}
		camGame.zoom = FlxMath.lerp(camGame.zoom, defaultZoom, elapsed * 2.5);
		camHUD.zoom = FlxMath.lerp(camHUD.zoom, defaultHudZoom, elapsed * 2.5);

		timeNum.number = Math.floor(Conductor.time * 0.001);

		if (FlxG.keys.justPressed.SEVEN) {
			FlxG.sound.music.stop();
			FlxG.switchState(new states.ChartingState(chart));
		}

		if (FlxG.keys.justPressed.THREE) {
			FlxG.sound.music.stop();
			FlxG.switchState(new states.AlphabetTestState());
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
		note.strumIndex = i.index;
		note.strumTime = i.time;
		note.strum = strum;
		note.sustain.length = i.length;
		note.speed = chart.speed;
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

		note.character = i.lane == 0 ? opponent : player;

		strum.notes.push(note);
		noteGroup.add(note);

		call('spawnNote', [note, i]);

		return note;
	}

	public static function pause(p:Bool = true):Bool {
		Conductor.paused = p;
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

		FlxG.sound.music.time = Conductor.time;
		resyncVox();

		// psych engine
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished)
			tmr.active = p);
		FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished)
			twn.active = p);

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
