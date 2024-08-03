package;

import Chart.ChartNote;
import flixel.input.keyboard.FlxKey;
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

	override public function create()
	{
		super.create();

		options = Options.instance;

		FlxG.camera.bgColor = FlxColor.fromHSB(0, 0, 0.4);

		FlxG.plugins.add(new Conductor());

		opponentStrums.setPosition(50, 50);
		add(opponentStrums);
		opponentStrums.autoHit = true;

		playerStrums.setPosition(FlxG.width - playerStrums.width - 50, 50);
		add(playerStrums);

		add(noteGroup);

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
				var que = rgbs[strum.ID];
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

		Conductor.stepHit.add(() ->
		{
			for (i in opponentStrums.members)
			{
				i.angle = FlxMath.fastSin(Conductor.beatFl * Math.PI) * 4;
			}
		});
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
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
