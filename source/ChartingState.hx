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
			noteSprite.y = (bruh.strumTime / 0.45) + 50;
			noteSprite.x = strumLine.members[bruh.index].x;
			noteSprite.noteData = bruh.index;
			noteSprite.draw();
		}
	}
}
