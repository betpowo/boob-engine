package;

import Chart.ChartNote;
import flixel.input.keyboard.FlxKey;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;

typedef NoteGroup = FlxTypedGroup<Note>;

class PlayState extends FlxState
{
	var opponentStrums:StrumLine = new StrumLine(4);
	var playerStrums:StrumLine = new StrumLine(4);

	public static var chart:Chart = {
		speed: 1,
		notes: [
			{strumTime: 1000, index: 3},
			{strumTime: 2000, index: 0},
			{strumTime: 3000, index: 2},
			{strumTime: 3500, index: 1},
			{strumTime: 4000, index: 2},
			{strumTime: 6000, index: 4, isPlayer: true}
		],
		bpm: 60
	};

	var noteGroup:NoteGroup = new NoteGroup();
	var vocals:FlxSound;

	var noteQueue:Array<Note> = [];

	var options:Options;

	var not:Note;

	var health(default, set):Float = 0.5;
	var score(default, set):Int = 0;
	var healthBar:HealthBar = new HealthBar();
	var scoreNum:Counter = new Counter();
	var timeNum:Counter = new Counter();

	function set_health(v:Float):Float
	{
		health = FlxMath.bound(v, 0, 1);
		healthBar.value = health;
		return health;
	}

	function set_score(v:Int):Int
	{
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

	override public function create()
	{
		super.create();

		options = Options.instance;

		FlxG.camera.bgColor = FlxColor.fromHSB(0, 0, 0.4);

		FlxG.plugins.add(new Conductor());

		opponentStrums.setPosition(50, 50);
		add(opponentStrums);
		opponentStrums.autoHit = true;

		playerStrums.setPosition(FlxG.width - playerStrums.width - 100, 50);
		add(playerStrums);
		// playerStrums.autoHit = true;

		add(noteGroup);

		not = new Note(2);
		not.sustain.length = 500;
		not.screenCenter();
		not.rgb.set(0x6600ff, -1, 0x000066);
		// add(not);

		var index = 0;
		for (keys in [[LEFT, A], [DOWN, S], [UP, K], [RIGHT, L]])
		{
			var strum = playerStrums.members[index];
			strum.inputs = keys;
			index += 1;
		}

		for (str in [opponentStrums, playerStrums])
		{
			for (strum in str.members)
			{
				var rgbs = options.noteColors;
				var que = rgbs[strum.ID] ?? {base: 0x87a3ad, outline: 0x000000};
				strum.rgb.set(que.base, -1, que.outline);
			}
		}
		chart = Chart.ChartConverter.convert(lime.utils.Assets.getText('assets/songs/darnell/charts/chart.json'));
		noteGroup.memberAdded.add(function(note)
		{
			@:privateAccess {
				note.parentGroup = noteGroup;
			}
		});
		FlxG.sound.playMusic('assets/songs/darnell/Inst.ogg', 0);
		vocals = new FlxSound().loadEmbedded('assets/songs/darnell/Voices-Play.ogg');
		FlxG.sound.list.add(vocals);
		vocals.play();

		var _vocals = new FlxSound().loadEmbedded('assets/songs/darnell/Voices-Opp.ogg');
		FlxG.sound.list.add(_vocals);
		_vocals.play();

		FlxG.sound.music.time = vocals.time = _vocals.time = 0;
		FlxG.sound.music.volume = 1;

		Conductor.bpm = chart.bpm;
		Conductor.paused = false;

		Conductor.beatHit.add(() ->
		{
			if (Conductor.beat % 4 == 0)
				FlxG.camera.zoom += 0.03;
		});

		for (i in playerStrums.members)
		{
			i.noteHit.add(noteHit);
			i.noteMiss.add(noteMiss);
		}

		add(healthBar);
		healthBar.x = 50;
		healthBar.y = FlxG.height - healthBar.height - 50;
		healthBar.rightToLeft = true;

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
	}

	function noteHit(note:Note)
	{
		var gwa = 0.01;
		score += 100;
		health += gwa;
	}

	function noteMiss(note:Note)
	{
		var gwa = 0.02;
		score -= 10;
		health -= gwa;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		not.scrollAngle += elapsed * 25;
		for (idx => note in chart.notes)
		{
			if (Conductor.time >= note.strumTime - (3000 / chart.speed) && !note.spawned)
			{
				note.spawned = true;
				spawnNote(note);
			}
		}
		FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, 1, elapsed * 2.5);
		if (FlxG.keys.justPressed.SEVEN)
		{
			FlxG.sound.music.stop();
			vocals.stop();
			FlxG.switchState(new ChartingState(chart));
		}
		if (FlxG.keys.pressed.UP)
			not.sustain.length -= 20;
		if (FlxG.keys.pressed.DOWN)
			not.sustain.length += 20;

		timeNum.number = Conductor.time * 0.001;
	}

	function spawnNote(i:ChartNote):Note
	{
		var group = i.isPlayer ? playerStrums : opponentStrums;
		var strum = group.members[i.index % group.members.length];

		var note = noteGroup.recycle(Note);
		note.noteData = i.index;
		note.strumTime = i.strumTime;
		note.strumTracker = strum;
		note.sustain.length = i.length;
		note.speed = chart.speed;
		strum.notes.push(note);
		note.rgb.copy(strum.rgb);
		noteGroup.add(note);
		note.y -= 2000;
		note.sustain.x -= 2000;

		return note;
	}
}
