package states;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import objects.Character;
import objects.Note;
import objects.ui.*;
import song.Chart.ChartNote;
import song.Chart.ChartParser;
import util.*;

class ChartingState extends FlxState {
	var GRID_SIZE:Float = 100;

	var chart = null;
	var chartNotes:Array<ChartNote> = [];
	var strumLine:StrumLine;
	var note:ChartingNoteGroup;
	var infoText:FlxText;
	var timeNum:Counter;
	var maxLayers:Int = 2;
	var layer(default, set):Int = -1;
	var inst:FlxSound;
	var grid:ChartingGrid;
	var gridShader:RGBPalette;
	var previewNote:Note;

	function set_layer(v:Int):Int {
		layer = v;
		if (note != null)
			note.layer = layer;
		return layer;
	}

	public function new(chart:Chart) {
		super();
		this.chart = chart;
	}

	var camHUD:FlxCamera;

	override public function create() {
		FlxG.camera.bgColor = FlxColor.fromHSB(0, 0, 0.3);
		camHUD = new FlxCamera();
		camHUD.bgColor = 0x00000000;
		FlxG.cameras.add(camHUD, false);

		strumLine = new StrumLine({keys: 4});
		strumLine.spacing = GRID_SIZE;
		strumLine.forEach((n) -> {
			n.setGraphicSize(GRID_SIZE);
			n.updateHitbox();
		});
		strumLine.y = 50;

		grid = new ChartingGrid(FlxGridOverlay.createGrid(1, 1, 1, 2, true, 0x665d005d, 0x660000bb), Y);
		grid.scale.set(GRID_SIZE, GRID_SIZE);
		grid.updateHitbox();
		grid.columns = 4;
		add(grid);

		gridShader = new RGBPalette();
		grid.shader = gridShader.shader;

		strumLine.screenCenter(X);
		grid.x = strumLine.x;
		grid.y = strumLine.y;

		add(strumLine);

		chartNotes = ChartParser.parseNotes(chart.notes);

		maxLayers = chart.lanes.length;

		// {base: 0xffF9393F, outline: 0xff651038}, {base: 0xff12FA05, outline: 0xff0A4447}
		add(note = new ChartingNoteGroup(chartNotes, strumLine, [
			for (idx => i in chart.lanes) {
				var col = FlxColor.fromString(Character.getIni(i.char)?.global?.color) ?? 0x717171;
				var outlin = new FlxColor(col);
				outlin.brightness *= 0.55;
				outlin.greenFloat *= 0.5;
				{
					base: col,
					outline: outlin
				}
			}
		]));
		note.gridSize = GRID_SIZE;
		note.x = strumLine.x;

		timeNum = new Counter();
		timeNum.x = timeNum.y = 50;
		timeNum.display = TIME_MS;
		timeNum.setColorTransform(-1, -1, -1, 1, 255, 255, 255);
		timeNum.scale.set(0.4, 0.4);
		timeNum.updateHitbox();
		add(timeNum);

		infoText = new FlxText();
		infoText.x = infoText.y = 50;
		infoText.y += (timeNum.frameHeight * timeNum.scale.y) + 8;
		infoText.size = 20;
		infoText.borderColor = FlxColor.BLACK;
		infoText.borderSize = 4;
		infoText.borderQuality = 2;
		infoText.borderStyle = OUTLINE_FAST;
		infoText.x -= 10;
		add(infoText);

		timeNum.camera = infoText.camera = camHUD;

		Conductor.bpm = chart.bpm[0].bpm;

		inst = new FlxSound();
		inst.loadEmbedded(Paths.song(Song.song, 'Inst', Song.variation), true);
		inst.volume = 0.7;
		inst.autoDestroy = false;
		FlxG.sound.list.add(inst);

		Conductor.tracker = inst;

		FlxG.sound.playMusic(Paths.sound('chartEditorLoop', 'music'), 0);

		add(previewNote = new Note(2));
		previewNote.rgb.set(0x333333, -1, 0x111111);
		previewNote.alpha = 0.75;
		previewNote.blend = ADD;
		previewNote.setGraphicSize(GRID_SIZE);
		previewNote.updateHitbox();
		previewNote.editor = note.editor = true;
		previewNote.speed = note.speed = 2;

		changeLayer(0);
	}

	@:allow(song.Song)
	override function update(elapsed:Float) {
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
		note.y = grid.y;

		timeNum.number = FlxMath.roundDecimal(Conductor.time * 0.001, 2);

		var intendedText = ' Beat: ${Conductor.beat}\n Step: ${Conductor.step}\n Layer:\n ';
		intendedText += (layer == -1) ? '[ALL]' : '$layerCharName [' + Std.string(layer) + ']';
		if (infoText.text != intendedText)
			infoText.text = intendedText;

		if (FlxG.mouse.justPressed) {
			FlxG.sound.play(Paths.sound('charter/ClickDown'));
		} else if (FlxG.mouse.justReleased) {
			FlxG.sound.play(Paths.sound('charter/ClickUp'));
		}

		updatePreviewNote(elapsed);

		if (FlxG.keys.justPressed.SPACE) {
			Conductor.paused = !Conductor.paused;
			inst.time = Conductor.time;
			if (Conductor.paused) {
				inst.pause();
				FlxG.sound.music.play();
			} else {
				inst.play(false, Conductor.time);
				FlxG.sound.music.pause();
				FlxG.sound.music.volume = -1;
			}
		}

		if (FlxG.keys.justPressed.ENTER) {
			Song.chart.notes = ChartParser.encodeNotes(chartNotes);
			Song.parsedNotes = chartNotes;
			inst.stop();
			FlxG.sound.music.stop();
			FlxG.switchState(new states.PlayState());
		}
	}

	var shittyLength:Float = 0;
	var holdingTime:Float = 0;

	public static var releaseTime:Float = 0;

	var ogColors = [];

	function updatePreviewNote(elapsed:Float) {
		releaseTime += elapsed;

		if (ogColors.length < 1 && previewNote != null)
			ogColors = [previewNote.rgb.r, previewNote.rgb.g, previewNote.rgb.b];

		if (FlxG.keys.justPressed.Q)
			shittyLength -= Conductor.stepCrochet;
		if (FlxG.keys.justPressed.E)
			shittyLength += Conductor.stepCrochet;

		shittyLength = Math.max(0, shittyLength);

		if (FlxG.mouse.x >= grid.x && FlxG.mouse.x < (grid.x + (GRID_SIZE * grid.columns))) {
			var valueX = Math.floor((FlxG.mouse.x - grid.x) / GRID_SIZE);
			var valueY = Math.floor((FlxG.mouse.y - grid.y) / GRID_SIZE);
			var unsnapped = false;

			previewNote.visible = !note.selecting;
			previewNote.x = valueX * GRID_SIZE;
			previewNote.x += grid.x;
			previewNote.strumIndex = valueX;
			if (FlxG.keys.pressed.SHIFT) {
				previewNote.y = FlxG.mouse.y - GRID_SIZE * 0.5;
				unsnapped = true;
			} else {
				previewNote.y = valueY * GRID_SIZE;
				previewNote.y += grid.y;
			}
			previewNote.sustain.blend = previewNote.blend;

			if (previewNote.visible) {
				previewNote.sustain.length = Math.max(0, stepFromMS(shittyLength) * GRID_SIZE);
			}

			if (FlxG.mouse.justPressed) {
				holdingTime = 0;
			}

			if (FlxG.mouse.pressed) {
				holdingTime += elapsed;
				previewNote.shader = gridShader.shader;
				var tick:Int = Math.floor(holdingTime / 0.1);
				previewNote.color = previewNote.sustain.color = (tick % 2 == 0) ? 0x6600ff : 0x0000ff;
				previewNote.angle = FlxMath.fastSin(holdingTime * 15) * 5;
			}

			if (FlxG.mouse.justReleased) {
				previewNote.color = previewNote.sustain.color = -1;
				previewNote.shader = previewNote.rgb.shader;
				previewNote.angle = 0;
				// trace('place note');
				if (layer != -1) {
					if (!note.selecting) {
						FlxG.sound.play(Paths.sound('charter/noteLay'));
						var daTime = (unsnapped ? (FlxG.mouse.y - grid.y - GRID_SIZE * 0.5) / GRID_SIZE : valueY) * Conductor.stepCrochet;
						// trace('note is at $daTime');
						chartNotes.push({
							time: daTime,
							index: valueX,
							length: shittyLength,
							lane: layer
						});
						note.chart = chartNotes; // lame
						releaseTime = 0;
					} else {
						FlxG.sound.play(Paths.sound('charter/noteErase'));
						chartNotes.sort((a, b) -> {
							if (a.time < b.time)
								return -1;
							if (a.time > b.time)
								return 1;
							return 0;
						});
						note.chart = chartNotes; // lame
					}
					chartNotes.sort((a, b) -> {
						if (a.time < b.time)
							return -1;
						if (a.time > b.time)
							return 1;
						return 0;
					});
				} else {
					var shakeTime = 0.0;
					FlxG.sound.play(Paths.sound('ui/cancel')).pitch = FlxG.random.float(0.95, 1.05);
					FlxTween.cancelTweensOf(previewNote);
					FlxG.camera.shake(2 / FlxG.camera.width, 0.1);
					FlxTween.shake(previewNote, 0.05, 0.25, FlxAxes.XY, {
						ease: FlxEase.expoOut,
						onUpdate: (_) -> {
							shakeTime += FlxG.elapsed;
							var tick:Int = Math.floor(shakeTime / 0.05);
							if (tick % 2 == 0) {
								infoText.color = 0xff0000;
								previewNote.rgb.set(0xff0000, 0, 0x800000);
							} else {
								infoText.color = -1;
								previewNote.rgb.set(ogColors[0], ogColors[1], ogColors[2]);
							}
						},
						onComplete: (_) -> {
							infoText.color = -1;
							previewNote.rgb.set(ogColors[0], ogColors[1], ogColors[2]);
						}
					});
				}
			}
		} else {
			previewNote.visible = false;
			previewNote.color = previewNote.sustain.color = -1;
			previewNote.shader = previewNote.rgb.shader;
			previewNote.angle = 0;
		}
	}

	var layerCharName:String = 'Unnamed';

	function changeLayer(ch:Int = 0) {
		if (ch != 0) {
			layer += ch;
			layer = FlxMath.wrap(layer, -1, maxLayers - 1);
			FlxG.sound.play(Paths.sound('ui/scroll'));
		}
		if (layer != -1) {
			var target:RGBPalette = note.rgbs[layer];
			gridShader.copy(target);
		} else {
			gridShader.set(0xeeeeff, -1, 0x808099);
		}

		for (i in strumLine.members) {
			i.rgb.copy(gridShader);
		}

		layerCharName = Character.getIni(chart.lanes[layer]?.char)?.global?.name ?? 'Unnamed';
	}

	public static function stepFromMS(ms:Float):Float {
		return ms / Conductor.stepCrochet;
	}
}

class ChartingNoteGroup extends Note {
	public var strumLine:StrumLine;
	public var chart:Array<ChartNote>;
	public var layer:Int = -1;
	public var gridSize(default, set):Float = 110;

	public var selecting:Bool = false;

	// public var selected:Array<Int> = [];

	public function set_gridSize(v:Float):Float {
		setGraphicSize(v);
		updateHitbox();
		sustain.scale.x = (v / sustain.frameWidth) * sustain.scale.x;
		gridSize = v;
		return v;
	}

	public var rgbs = [];

	public function new(chart, strumLine, laneColors:Array<{base:Int, outline:Int}>) {
		super();
		this.chart = chart;
		this.strumLine = strumLine;
		for (idx => i in laneColors) {
			var colr = new RGBPalette();
			colr.set(i.base, -1, i.outline);
			rgbs[idx] = colr;
		}
	}

	var ogx:Float = 0;
	var ogy:Float = 0;

	override public function draw() {
		ogx = x;
		ogy = y;
		selecting = false;
		if (strumLine != null && chart != null) {
			for (idx => bruh in chart) {
				var shouldDraw = (bruh.time + bruh.length) >= (Conductor.time - Conductor.crochet * 2)
					&& bruh.time <= (Conductor.time + (Conductor.crochet * 3));
				var gwa = rgbs[bruh.lane] ?? rgbs[0];
				shader = gwa.shader;
				alpha = 1;
				y += ChartingState.stepFromMS(bruh.time) * gridSize;
				if (!Conductor.paused && ((Conductor.time >= bruh.time)) || (layer != -1 && bruh.lane != layer)) {
					alpha = 0.3;
				}
				x += (bruh.index * gridSize);
				strumIndex = bruh.index;
				sustain.length = ChartingState.stepFromMS(bruh.length) * gridSize;

				colorTransform.greenOffset = 0;

				if (FlxG.mouse.overlaps(this) && (bruh.lane == layer || layer == -1)) {
					colorTransform.greenOffset = 128;
					selecting = true;
					handleSelection(idx);
				}

				if (shouldDraw)
					super.draw();

				x = ogx;
				y = ogy;
			}
		}
	}

	function handleSelection(idx:Int = 0) {
		// ill figure out moving notes later
		if (FlxG.mouse.pressed) {
			var valueX:Float = (FlxG.mouse.x - ogx) / gridSize;
			chart[idx].index = Std.int((valueX % 1 >= 0.75) ? valueX + 1 : valueX);
			/*var valueY:Float = Math.floor((FlxG.mouse.y - ogy) / gridSize);
				var unsnapped = FlxG.keys.pressed.SHIFT;

				if (unsnapped)
					valueY = (FlxG.mouse.y - ogy - (gridSize * 0.5)) / gridSize;

				var daTime = valueY * Conductor.stepCrochet;
				trace('hi $daTime');

				chart[idx].time = daTime; */
		}

		if (FlxG.mouse.justReleased && ChartingState.releaseTime >= 0.1 && layer == chart[idx].lane) {
			chart.splice(idx, 1);
		}

		if (FlxG.keys.anyJustPressed([Q, E])) {
			FlxG.sound.play(Paths.sound('charter/stretch${FlxG.random.int(1, 2)}_UI'));
			chart[idx].length += Conductor.stepCrochet * (FlxG.keys.justPressed.Q ? -1 : 1);
		}
	}
}

// useless, but just to make multikey grid easier

class ChartingGrid extends FlxBackdrop {
	public var columns:Int = 4;

	public function new(image, repeat) {
		super(image, repeat, 0, 0);
	}

	override public function draw() {
		var ogx = x;
		var ogfy = flipY;

		for (idx in 0...columns) {
			x = ogx + (scale.x * idx);
			flipY = idx % 2 == 1;
			super.draw();
		}
		x = ogx;
		flipY = ogfy;
	}
}
