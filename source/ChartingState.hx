class ChartingState extends FlxState
{
	var chart = null;
	var strumLine = new StrumLine(4);
	var noteSprite:Note = new Note(2);

	public function new(chart:Chart)
	{
		super();
		this.chart = chart;

		strumLine.spacing = strumLine.members[0].width;
		strumLine.y = 50;

		var last = strumLine.members[strumLine.members.length - 1];
		var bg = new FlxSprite().makeGraphic(1, 1, -1);
		bg.scale.set(last.x + last.width, FlxG.height * 1.5);
		bg.scale.x += 60;
		bg.screenCenter();

		strumLine.screenCenter(X);

		add(bg);
		add(strumLine);
	}

	override public function draw()
	{
		super.draw();
		for (bruh in chart.notes)
		{
			noteSprite.y = ((bruh.strumTime - Conductor.time) / 0.45) + strumLine.members[bruh.index].y;
			noteSprite.x = strumLine.members[bruh.index].x;
			noteSprite.noteData = bruh.index;
			noteSprite.sustain.length = bruh.length;
			noteSprite.draw();
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (FlxG.keys.pressed.Z)
			FlxG.camera.zoom -= 0.003;
		if (FlxG.keys.pressed.X)
			FlxG.camera.zoom += 0.003;

		noteSprite.update(elapsed);

		if (FlxG.keys.justPressed.SPACE)
			Conductor.paused = !Conductor.paused;
	}
}
