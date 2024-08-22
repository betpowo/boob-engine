import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

class ChartingState extends FlxState
{
	var GRID_SIZE:Float = 100;

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
	var previewNote:Note = new Note(2);

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

	var camHUD:FlxCamera;

	override public function create()
	{
		FlxG.camera.bgColor = FlxColor.fromHSB(0, 0, 0.3);
		camHUD = new FlxCamera();
		camHUD.bgColor = 0x00000000;
		FlxG.cameras.add(camHUD, false);

		strumLine = new StrumLine(4);
		strumLine.spacing = GRID_SIZE;
		strumLine.forEach((n) ->
		{
			n.setGraphicSize(GRID_SIZE);
			n.updateHitbox();
		});
		strumLine.y = 50;

		grid = new FlxBackdrop(FlxGridOverlay.createGrid(1, 1, 4, 2, true, 0x665d005d, 0x660000bb), Y);
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

		timeNum.camera = infoText.camera = camHUD;

		Conductor.bpm = chart.bpm;

		inst = new FlxSound();
		inst.loadEmbedded(Paths.song('darnell'), true);
		inst.volume = 0.7;
		inst.autoDestroy = false;
		FlxG.sound.list.add(inst);

		Conductor.tracker = inst;

		FlxG.sound.playMusic(Paths.sound('chartEditorLoop', 'music'), 0);

		add(previewNote);
		previewNote.rgb.set(0x333333, -1, 0x111111);
		previewNote.alpha = 0.75;
		previewNote.blend = ADD;
		previewNote.setGraphicSize(GRID_SIZE);
		previewNote.updateHitbox();
		previewNote.editor = note.editor = true;

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

		if (FlxG.mouse.justPressed)
		{
			FlxG.sound.play(Paths.sound('charter/ClickDown'));
		}
		else if (FlxG.mouse.justReleased)
		{
			FlxG.sound.play(Paths.sound('charter/ClickUp'));
		}

		updatePreviewNote(elapsed);

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
				inst.play(false, Conductor.time);
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

	var shittyLength:Float = 0;
	var holdingTime:Float = 0;
	var ogColors = [];

	function updatePreviewNote(elapsed:Float)
	{
		if (ogColors.length < 1 && previewNote != null)
			ogColors = [previewNote.rgb.r, previewNote.rgb.g, previewNote.rgb.b];

		if (FlxG.keys.justPressed.Q)
			shittyLength -= Conductor.stepCrochet;
		if (FlxG.keys.justPressed.E)
			shittyLength += Conductor.stepCrochet;

		shittyLength = Math.max(0, shittyLength);

		if (FlxG.mouse.x >= grid.x && FlxG.mouse.x < (grid.x + grid.width))
		{
			var valueX = Math.floor((FlxG.mouse.x - grid.x) / GRID_SIZE);
			var valueY = Math.floor((FlxG.mouse.y - grid.y) / GRID_SIZE);
			var unsnapped = false;

			previewNote.visible = true;
			previewNote.x = valueX * GRID_SIZE;
			previewNote.x += grid.x;
			previewNote.strumIndex = valueX;
			if (FlxG.keys.pressed.SHIFT)
			{
				previewNote.y = FlxG.mouse.y - GRID_SIZE * 0.5;
				unsnapped = true;
			}
			else
			{
				previewNote.y = valueY * GRID_SIZE;
				previewNote.y += grid.y;
			}
			previewNote.sustain.length = Math.max(0, stepFromMS(shittyLength * 2) * GRID_SIZE);
			previewNote.sustain.blend = previewNote.blend;

			if (FlxG.mouse.justPressed)
			{
				holdingTime = 0;
			}

			if (FlxG.mouse.pressed)
			{
				holdingTime += elapsed;
				previewNote.shader = gridShader.shader;
				var tick:Int = Math.floor(holdingTime / 0.1);
				previewNote.color = previewNote.sustain.color = (tick % 2 == 0) ? 0x6600ff : 0x0000ff;
				previewNote.angle = FlxMath.fastSin(holdingTime * 15) * 5;
			}

			if (FlxG.mouse.justReleased)
			{
				previewNote.color = previewNote.sustain.color = -1;
				previewNote.shader = previewNote.rgb.shader;
				previewNote.angle = 0;
				// trace('place note');
				if (layer != -1)
				{
					FlxG.sound.play(Paths.sound('charter/noteLay'));
					var daTime = (unsnapped ? (FlxG.mouse.y - grid.y - GRID_SIZE * 0.5) / GRID_SIZE : valueY) * Conductor.stepCrochet;
					// trace('note is at $daTime');
					chart.notes.push({
						time: daTime,
						index: valueX,
						length: shittyLength,
						lane: layer
					});
					chart.notes.sort((a, b) ->
					{
						if (a.time < b.time)
							return -1;
						if (a.time > b.time)
							return 1;
						return 0;
					});
					note.chart = chart; // lame
				}
				else
				{
					var shakeTime = 0.0;
					FlxG.sound.play(Paths.sound('ui/cancel')).pitch = FlxG.random.float(0.95, 1.05);
					FlxTween.cancelTweensOf(previewNote);
					FlxG.camera.shake(2 / FlxG.camera.width, 0.1);
					FlxTween.shake(previewNote, 0.05, 0.25, FlxAxes.XY, {
						ease: FlxEase.expoOut,
						onUpdate: (_) ->
						{
							shakeTime += FlxG.elapsed;
							var tick:Int = Math.floor(shakeTime / 0.05);
							if (tick % 2 == 0)
							{
								infoText.rgb.g = 0xff0000;
								previewNote.rgb.set(0xff0000, 0, 0x800000);
							}
							else
							{
								infoText.rgb.g = -1;
								previewNote.rgb.set(ogColors[0], ogColors[1], ogColors[2]);
							}
						},
						onComplete: (_) ->
						{
							infoText.rgb.g = -1;
							previewNote.rgb.set(ogColors[0], ogColors[1], ogColors[2]);
						}
					});
				}
			}
		}
		else
		{
			previewNote.visible = false;
			previewNote.color = previewNote.sustain.color = -1;
			previewNote.shader = previewNote.rgb.shader;
			previewNote.angle = 0;
		}
	}

	function changeLayer(ch:Int = 0)
	{
		if (ch != 0)
		{
			layer += ch;
			layer = FlxMath.wrap(layer, -1, maxLayers - 1);
			FlxG.sound.play(Paths.sound('ui/scroll'));
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
	public var strumLine:StrumLine;
	public var chart:Chart;
	public var layer:Int = -1;
	public var gridSize(default, set):Float = 110;

	public function set_gridSize(v:Float):Float
	{
		setGraphicSize(v);
		updateHitbox();
		sustain.scale.x = (v / sustain.frameWidth) * sustain.scale.x;
		gridSize = v;
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

				y += strumLine.y;
				x = strumLine.x + (bruh.index * gridSize);
				strumIndex = bruh.index;
				// i have to *2 it because it would be short
				sustain.length = ChartingState.stepFromMS(bruh.length * 2) * gridSize;
				if (shouldDraw)
					super.draw();
			}
		}
	}
}
