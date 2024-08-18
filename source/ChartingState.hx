import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

class ChartingState extends FlxState
{
	var GRID_SIZE:Float = 110;

	var chart = null;
	var strumLine:StrumLine;
	var note:ChartingNoteGroup;
	var infoText:Alphabet;
	var timeNum:Counter;
	var maxLayers:Int = 2;
	var layer(default, set):Int = -1;
	var inst:FlxSound;
	var grid:FlxBackdrop;
	var gridShader:RGBPalette;

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
			n.setGraphicSize(GRID_SIZE);
			n.updateHitbox();
		});
		strumLine.y = 50;

		grid = new FlxBackdrop(FlxGridOverlay.createGrid(1, 1, 4, 2, true, 0x66bb0000, 0x660000bb), Y);
		grid.scale.set(GRID_SIZE, GRID_SIZE);
		grid.updateHitbox();
		grid.screenCenter(X);
		grid.y = strumLine.y;
		add(grid);

		gridShader = new RGBPalette();
		grid.shader = gridShader.shader;

		strumLine.screenCenter(X);

		add(strumLine);

		add(note = new ChartingNoteGroup(chart, strumLine, [{base: 0xffF9393F, outline: 0xff651038}, {base: 0xff12FA05, outline: 0xff0A4447}]));
		note.gridSize = GRID_SIZE;

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

		changeLayer(0);
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

		grid.y = strumLine.y + stepFromMS(Conductor.time) * GRID_SIZE * -1;

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
		if (layer != -1)
		{
			var target:RGBPalette = note.rgbs[layer];
			gridShader.copy(target);
		}
		else
		{
			gridShader.set(0xeeeeff, -1, 0x808099);
		}
	}

	public static function stepFromMS(ms:Float):Float
	{
		return ms / Conductor.stepCrochet;
	}
}

class ChartingNoteGroup extends Note
{
	var chart:Chart;
	var strumLine:StrumLine;

	public var layer:Int = -1;
	public var gridSize(default, set):Float = 110;

	public function set_gridSize(v:Float):Float
	{
		setGraphicSize(v);
		updateHitbox();
		return v;
	}

	public var rgbs = [];

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
				y = ChartingState.stepFromMS(bruh.time - Conductor.time) * gridSize;
				if (!Conductor.paused && ((Conductor.time >= bruh.time)) || (layer != -1 && bruh.lane != layer))
				{
					alpha = 0.3;
				}

				y += strumLine.members[bruh.index].y;
				x = strumLine.members[bruh.index].x;
				strumIndex = bruh.index;
				sustain.length = ChartingState.stepFromMS(bruh.length) * gridSize;
				if (shouldDraw)
					super.draw();
			}
		}
	}
}
