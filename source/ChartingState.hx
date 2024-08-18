import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

class ChartingState extends FlxState
{
	final GRID_SIZE:Float = 110;

	var chart = null;
	var strumLine:StrumLine;
	var note:ChartingNoteGroup;
	var infoText:Alphabet;
	var timeNum:Counter;
	var maxLayers:Int = 2;
	var layer(default, set):Int = -1;
	var inst:FlxSound;
	var grid:FlxBackdrop;

	function set_layer(v:Int):Int
	{
		layer = v;
		if (note != null)
			note.layer = layer;
		return layer;
	}

	public function new(chart:Chart)
	{
		super();
		this.chart = chart;
	}

	override public function create()
	{
		FlxG.camera.bgColor = FlxColor.fromHSB(0, 0, 0.3);

		strumLine = new StrumLine(4);
		strumLine.spacing = GRID_SIZE;
		strumLine.forEach((n) ->
		{
			n.setGraphicSize(GRID_SIZE, GRID_SIZE);
			n.updateHitbox();
		});
		strumLine.y = 50;

		grid = new FlxBackdrop(FlxGridOverlay.createGrid(1, 1, 4, 2, true, 0x33ff0000, 0x330000ff), Y);
		grid.scale.set(GRID_SIZE, GRID_SIZE);
		grid.updateHitbox();
		grid.screenCenter(X);
		grid.y = strumLine.y;
		add(grid);

		strumLine.screenCenter(X);

		add(strumLine);

		add(note = new ChartingNoteGroup(chart, strumLine, [{base: 0xffF9393F, outline: 0xff651038}, {base: 0xff12FA05, outline: 0xff0A4447}]));
		note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();

		timeNum = new Counter();
		timeNum.x = timeNum.y = 50;
		timeNum.display = TIME_MS;
		timeNum.setColorTransform(-1, -1, -1, 1, 255, 255, 255);
		timeNum.scale.set(0.4, 0.4);
		timeNum.updateHitbox();
		add(timeNum);

		infoText = new Alphabet();
		infoText.x = infoText.y = 50;
		infoText.y += 20;
		infoText.scale.set(0.4, 0.4);
		add(infoText);

		Conductor.bpm = chart.bpm;

		inst = new FlxSound();
		inst.loadEmbedded('assets/songs/darnell/Inst.ogg', true);
		inst.volume = 0.7;
		inst.autoDestroy = false;
		FlxG.sound.list.add(inst);

		Conductor.tracker = inst;

		FlxG.sound.playMusic('assets/music/chartEditorLoop.ogg', 0);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (Conductor.paused)
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + (elapsed * 0.05), 0.6);

		if (FlxG.keys.pressed.Z)
			FlxG.camera.zoom -= elapsed * 0.3;
		if (FlxG.keys.pressed.X)
			FlxG.camera.zoom += elapsed * 0.3;

		var mult = FlxG.keys.pressed.SHIFT ? 4 : 1;
		if (FlxG.keys.anyPressed([W, UP]))
			Conductor.time -= elapsed * 500 * mult;
		if (FlxG.keys.anyPressed([S, DOWN]))
			Conductor.time += elapsed * 500 * mult;

		if (FlxG.keys.anyJustPressed([A, LEFT]))
			changeLayer(-1);

		if (FlxG.keys.anyJustPressed([D, RIGHT]))
			changeLayer(1);

		grid.y = strumLine.y + (((Conductor.time) / 0.45) * Conductor.crochetSec * -1);

		timeNum.number = FlxMath.roundDecimal(Conductor.time * 0.001, 2);

		var intendedText = 'Beat: ${Conductor.beat}\nStep: ${Conductor.step}\nLayer:\n';
		intendedText += (layer == -1) ? '[ALL]' : 'Unnamed [' + Std.string(layer) + ']';
		if (infoText.text != intendedText)
			infoText.text = intendedText;

		if (FlxG.keys.justPressed.SPACE)
		{
			Conductor.paused = !Conductor.paused;
			inst.time = Conductor.time;
			if (Conductor.paused)
			{
				inst.pause();
				FlxG.sound.music.play();
			}
			else
			{
				inst.play();
				FlxG.sound.music.pause();
				FlxG.sound.music.volume = -1;
			}
		}

		if (FlxG.keys.justPressed.ENTER)
		{
			PlayState.chart = chart;
			inst.stop();
			FlxG.sound.music.stop();
			FlxG.switchState(new PlayState());
		}
	}

	function changeLayer(ch:Int = 0)
	{
		if (ch != 0)
		{
			layer += ch;
			layer = FlxMath.wrap(layer, -1, maxLayers - 1);
		}
	}
}

class ChartingNoteGroup extends Note
{
	var chart:Chart;
	var strumLine:StrumLine;

	public var layer:Int = -1;

	var rgbs = [];

	public function new(chart, strumLine, laneColors:Array<{base:Int, outline:Int}>)
	{
		super();
		this.chart = chart;
		this.strumLine = strumLine;
		for (idx => i in laneColors)
		{
			var colr = new RGBPalette();
			colr.set(i.base, -1, i.outline);
			rgbs[idx] = colr;
		}
	}

	override public function draw()
	{
		if (strumLine != null && chart != null)
		{
			for (bruh in chart.notes)
			{
				var shouldDraw = (bruh.time + bruh.length) >= (Conductor.time - Conductor.crochet * 2)
					&& bruh.time <= (Conductor.time + (Conductor.crochet * 3));
				var gwa = rgbs[bruh.lane] ?? rgbs[0];
				shader = gwa.shader;
				alpha = 1;
				y = ((bruh.time - Conductor.time) / 0.45) * Conductor.crochetSec;
				if (!Conductor.paused && ((Conductor.time >= bruh.time)) || (layer != -1 && bruh.lane != layer))
				{
					alpha = 0.3;
				}

				y += strumLine.members[bruh.index].y;
				x = strumLine.members[bruh.index].x;
				strumIndex = bruh.index;
				sustain.length = bruh.length;
				if (shouldDraw)
					super.draw();
			}
		}
	}
}
