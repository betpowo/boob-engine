package;

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
		]
	};

	var noteGroup:NoteGroup = new NoteGroup();
	var vocals:FlxSound;

	var noteQueue:Array<Note> = [];

	override public function create()
	{
		super.create();
		FlxG.camera.bgColor = FlxColor.fromHSB(0, 0, 0.4);

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
				var rgbs = [
					{base: 0xffC24B99, outline: 0xff3C1F56},
					{base: 0xff00FFFF, outline: 0xff1542B7},
					{base: 0xff12FA05, outline: 0xff0A4447},
					{base: 0xffF9393F, outline: 0xff651038}
				];
				var que = rgbs[strum.ID];
				strum.rgb.set(que.base, -1, que.outline);
			}
		}
		chart = Chart.ChartConverter.convert(lime.utils.Assets.getText('assets/songs/unbeatable/charts/normal.json'));
		noteGroup.memberAdded.add(function(note)
		{
			@:privateAccess {
				note.parentGroup = noteGroup;
			}
		});
		for (i in chart.notes)
		{
			var group = i.isPlayer ? playerStrums : opponentStrums;
			var strum = group.members[i.index % group.members.length];

			var note = noteGroup.recycle(Note);
			note.noteData = i.index;
			note.strumTime = i.strumTime;
			note.strumTracker = strum;
			strum.notes.push(note);
			note.rgb.copy(strum.rgb);
			noteQueue.push(note);
		}
		FlxG.sound.playMusic('assets/songs/unbeatable/Inst.ogg', 0);
		vocals = new FlxSound().loadEmbedded('assets/songs/unbeatable/Voices.ogg');
		FlxG.sound.list.add(vocals);
		vocals.play();
		FlxG.sound.music.time = vocals.time = 11000;
		FlxG.sound.music.volume = 1;
	}

	override public function update(elapsed:Float)
	{
		Conductor.time = FlxG.sound.music.time;
		super.update(elapsed);
		for (note in noteQueue)
		{
			if (Conductor.time >= note.strumTime - (3000 / chart.speed))
			{
				noteGroup.add(noteQueue.shift());
			}
		}
	}
}
