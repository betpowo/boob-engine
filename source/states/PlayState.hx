package states;

import flixel.input.keyboard.FlxKey;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import objects.*;
import objects.ui.*;
import song.*;
import song.Chart.ChartNote;
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

		scoreNum.offset.y += 7;
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

	public function new() {
		super();
		instance = this;
	}

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

		playerStrums.setPosition(FlxG.width - playerStrums.width - 100, 50);
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

		for (str in strumGroup.members) {
			str.forEach((i) -> {
				i.noteHit.add(noteHit);
				i.noteHeldStep.add(noteHeldStep);
				// i.noteHeld.add(noteHeld);
				i.noteMiss.add(noteMiss);
			});
		}

		add(healthBar);
		healthBar.x = 50;
		healthBar.y = FlxG.height - healthBar.height - 50;
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

		opponentStrums.camera = playerStrums.camera = healthBar.camera = scoreNum.camera = timeNum.camera = camHUD;

		add(spectator = new Character('gf'));
		spectator.screenCenter();

		add(opponent = new Character('dad'));
		opponent.setPosition(50, 100);
		// opponent.setColorTransform(-1, 0, 0, 1, 255);

		add(player = new Character('bf'));
		player.setPosition(700, 200);
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

	function noteHit(note:Note) {
		var laneID = note.strum.parentLane.ID;
		var char:Character = player;
		if (laneID == 1) {
			var gwa = 0.01;
			score += 100;
			health += gwa;
		} else {
			char = opponent;
		}

		if (note.anim != null && char != null) {
			char.holdTime = Conductor.stepCrochetSec * char.holdDur;
			char.playAnim(note.anim, true);
		}
	}

	function noteHeldStep(note:Note) {
		var laneID = note.strum.parentLane.ID;

		if (laneID == 1) {
			health += 0.7 / 100;

			if (note.anim != null) {
				player.holdTime = Conductor.crochetSec * 2;
				player.playAnim(note.anim, true);
			}
		} else {
			opponent.holdTime = Conductor.crochetSec * 2;
			opponent.playAnim(note.anim, true);
		}
	}

	function noteMiss(note:Note) {
		var gwa = 0.02;
		score -= 10;
		health -= gwa;
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
		for (idx => note in chart.notes) {
			if (Conductor.time >= note.time - (3000 / chart.speed) && !note.spawned) {
				note.spawned = true;
				spawnNote(note);
			}
		}
		camGame.zoom = FlxMath.lerp(camGame.zoom, 1, elapsed * 2.5);
		camHUD.zoom = FlxMath.lerp(camHUD.zoom, 1, elapsed * 2.5);

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
		strum.notes.push(note);
		note.rgb.copy(strum.rgb);

		/*var clor = FlxColor.fromHSB(FlxG.random.int(0, 360), FlxG.random.float(0.2, 1), FlxG.random.float(0.6, 1));
			note.rgb.set(clor, -1, clor.getDarkened(0.5)); */

		noteGroup.add(note);
		note.y -= 2000;
		note.sustain.x -= 2000;

		if (i.lane == 0)
			note.scrollAngle = FlxG.random.float(-90, 90);

		note.camera = note.sustain.camera = camHUD;

		note.anim = switch (note.strumIndex) {
			case 0: 'singLEFT';
			case 1: 'singDOWN';
			case 2: 'singUP';
			case 3: 'singRIGHT';
			case _: null;
		}

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

		return Conductor.paused;
	}

	override public function openSubState(SubState:FlxSubState) {
		SubState.camera = camOverlay;
		super.openSubState(SubState);
	}

	override function destroy() {
		strumGroup.destroy();
		noteGroup.destroy();
		super.destroy();
		Paths.clear();
	}
}
