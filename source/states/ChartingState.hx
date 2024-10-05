package states;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.input.keyboard.FlxKey;
import lime.app.Application;
import objects.Character;
import objects.Note;
import objects.StrumNote;
import objects.ui.*;
import song.Chart.ChartEvents;
import song.Chart.ChartNote;
import song.Chart.ChartParser;
import substates.popup.EditorPopupWindow;
import util.*;

class ChartingState extends FlxState {
	var GRID_SIZE:Float = 100;

	var chart:Chart = null;
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

	public static var instance:ChartingState;

	public function new(chart:Chart) {
		super();
		instance = this;
		this.chart = chart;
	}

	var camHUD:FlxCamera;

	override public function create() {
		FlxG.camera.bgColor = FlxColor.fromHSB(0, 0, 0.3);
		camHUD = new FlxCamera();
		camHUD.bgColor = 0x00000000;
		FlxG.cameras.add(camHUD, false);

		strumLine = new StrumLine({keys: getMaxKeyCount()});
		strumLine.spacing = GRID_SIZE;
		strumLine.forEach((n) -> {
			n.setGraphicSize(GRID_SIZE);
			n.updateHitbox();
		});
		strumLine.y = 50;

		grid = new ChartingGrid(FlxGridOverlay.createGrid(1, 1, 1, 2, true, 0x665d005d, 0x660000bb), Y);
		grid.scale.set(GRID_SIZE, GRID_SIZE);
		grid.updateHitbox();
		grid.columns = Std.int(Math.max(getMaxKeyCount(), 1)); // make sure youll still be able to place events with 0 keys
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
				outlin.greenFloat *= 0.45;
				outlin.blueFloat *= 1.15;
				{
					base: col,
					outline: outlin
				}
			}
		]));
		note.gridSize = GRID_SIZE;
		note.events = Song.events;
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

		addButton(function() {
			/*Application.current.window.alert([
					'place notes and drag them to move them',
					'drag notes outside grid to delete them',
					'press left or right to switch layers',
					'uhhh... more soon i forgot'
				].join('\n'), 'chart editor help'); */

			openSubState(new EditorPopupWindow());
		}, 'help', 0x6699ff, 0x330099, [FlxKey.F1]);

		editButton = addButton(function() {
			// Application.current.window.alert(['this is meant for layer/strumline options', 'im doing it later'].join('\n'), 'fuck');
			if (layer >= 0) {
				var lane = chart.lanes[layer];
				openSubState(new EditorPopupWindow(1180, 620, 'Edit Layer [$layer]', [
					{
						type: 'check',
						checked: lane.play ?? false,
						label: 'Playable',
						pos: [0, 0],
						onChange: function() {
							lane.play = !lane.play;
						}
					},
					{
						type: 'check',
						checked: lane.visible ?? true,
						label: 'Visible',
						pos: [400, 0],
						onChange: function() {
							lane.visible = !lane.visible;
						}
					}
				]));
			}
		}, 'pencil', 0xcccccc, 0x333333, [FlxKey.M]);
		editButton.y += 110;

		addStrButton = addButton(function() {
			if (layer >= 0) {
				chart.lanes[layer].keys += 1;
				grid.columns = getMaxKeyCount();
				grid.allowedColumns = chart.lanes[layer].keys;
				updateStrumCount(grid.columns);
				changeLayer(0);

				FlxG.sound.play(Paths.sound('charter/noteLay'), 0.6).pitch = 0.7;
				FlxG.sound.play(Paths.sound('charter/stretchSNAP_UI'));
			}
		}, 'plus', 0x33cc99, 0x336666, [FlxKey.P]);
		addStrButton.camera = FlxG.camera;
		addStrButton.scale.set(.77, .77);
		addStrButton.updateHitbox();
		addStrButton.centerOriginPoint();

		delStrButton = addButton(function() {
			if (layer >= 0) {
				chart.lanes[layer].keys -= 1;
				grid.columns = getMaxKeyCount();
				grid.allowedColumns = chart.lanes[layer].keys;
				updateStrumCount(grid.columns);
				changeLayer(0);

				FlxG.sound.play(Paths.sound('charter/noteErase'), 0.6).pitch = 0.7;
				FlxG.sound.play(Paths.sound('charter/undo'));
			}
		}, 'minus', 0xff6699, 0x990066, [FlxKey.O]);
		delStrButton.camera = FlxG.camera;
		delStrButton.scale.set(.77, .77);
		delStrButton.updateHitbox();
		delStrButton.centerOriginPoint();

		changeLayer(0);
	}

	var editButton:ImageButton;
	var addStrButton:ImageButton;
	var delStrButton:ImageButton;

	function updateStrumCount(keys:Int) {
		var diff = keys - strumLine.members.length;
		if (diff > 0) {
			for (_i in 0...diff) {
				var strum = strumLine.recycle(StrumNote);
				strum.strumIndex = strum.ID = keys - 1;
				strum.setGraphicSize(GRID_SIZE);
				strum.updateHitbox();
				strumLine.add(strum);
				strumLine.spacing = strumLine.spacing;
				strum.visible = false;
			}
		} else if (diff < 0) {
			var i:Int = Std.int(Math.abs(diff));
			while (i > 0) {
				var letter:StrumNote = strumLine.members[strumLine.members.length - 1];
				if (letter != null) {
					CoolUtil.doSplash(letter.getMidpoint().x, letter.getMidpoint().y, letter.strumRGB.r);
					letter.kill();
					strumLine.members.remove(letter);
					remove(letter);
				}
				i -= 1;
			}
		}
	}

	function addButton(callback:Void->Void, path:String = 'help', col1:FlxColor = 0xcccccc, col2:FlxColor = 0x333333, ?inp:Array<FlxKey>):ImageButton {
		var infoButt = new ImageButton(Paths.image('ui/editor/image_button/$path'));
		infoButt.onPress.add(callback);
		infoButt.setPosition(FlxG.width - infoButt.width - 50, 50);
		infoButt.quickColor(col1, col2);
		add(infoButt);
		infoButt.camera = camHUD;
		infoButt.inputs = inp;
		infoButt.antialiasing = true;

		return infoButt;
	}

	@:allow(song.Song)
	override function update(elapsed:Float) {
		/*if (Conductor.paused)
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + (elapsed * 0.05), 0.6); */

		final zoomMult:Float = 0.5;

		if (FlxG.keys.pressed.Z)
			FlxG.camera.zoom -= elapsed * zoomMult;
		if (FlxG.keys.pressed.X)
			FlxG.camera.zoom += elapsed * zoomMult;

		FlxG.camera.zoom = FlxMath.bound(FlxG.camera.zoom, 0.5, 1.75);

		var mult = FlxG.keys.pressed.SHIFT ? 4 : 1;
		if (FlxG.keys.anyPressed([W, UP]))
			Conductor.time -= elapsed * 500 * mult;
		if (FlxG.keys.anyPressed([S, DOWN]))
			Conductor.time += elapsed * 500 * mult;

		if (FlxG.keys.anyJustPressed([A, LEFT]))
			changeLayer(-1);

		if (FlxG.keys.anyJustPressed([D, RIGHT]))
			changeLayer(1);

		grid.x = FlxMath.lerp(grid.x, (FlxG.width - (grid.columns * GRID_SIZE)) * .5, elapsed * 13);
		strumLine.x = note.x = grid.x;
		grid.y = strumLine.y + stepFromMS(Conductor.time) * GRID_SIZE * -1;
		note.y = grid.y;

		timeNum.number = FlxMath.roundDecimal(Conductor.time * 0.001, 2);

		var intendedText = ' Beat: ${Conductor.beat}\n Step: ${Conductor.step}\n Layer:\n ';
		intendedText += switch (layer) {
			case -1: '[ALL]';
			case -2: '[EVENTS]';
			default: '$layerCharName [' + Std.string(layer) + ']';
		};
		if (infoText.text != intendedText)
			infoText.text = intendedText;

		if (FlxG.mouse.justPressed) {
			FlxG.sound.play(Paths.sound('charter/ClickDown'));
		} else if (FlxG.mouse.justReleased) {
			FlxG.sound.play(Paths.sound('charter/ClickUp'));
		}

		if (layer == -2) {
			previewNote.visible = false;
		} else {
			updatePreviewNote(elapsed);
		}

		addStrButton.x = grid.x + (grid.columns * GRID_SIZE);
		delStrButton.x = grid.x - delStrButton.width;

		super.update(elapsed);

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

	public static var holdingTime:Float = 0;
	public static var releaseTime:Float = 0;

	var ogColors = [];

	function updatePreviewNote(elapsed:Float) {
		releaseTime += elapsed;

		if (ogColors.length < 1 && previewNote != null)
			ogColors = [previewNote.rgb.r, previewNote.rgb.g, previewNote.rgb.b];

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
				if (FlxG.keys.justPressed.Q)
					shittyLength -= Conductor.stepCrochet;
				if (FlxG.keys.justPressed.E)
					shittyLength += Conductor.stepCrochet;

				shittyLength = Math.max(0, shittyLength);

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
				if (layer >= 0 && valueX < grid.allowedColumns) {
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
						note.justPlaced = true;
						chartNotes.sort((a, b) -> {
							if (a.time < b.time)
								return -1;
							if (a.time > b.time)
								return 1;
							return 0;
						});
						note.chart = chartNotes; // lame
						add(CoolUtil.doSplash(grid.x
							+ (valueX * GRID_SIZE)
							+ (GRID_SIZE * .5),
							grid.y
							+ ((daTime / Conductor.stepCrochet) * GRID_SIZE)
							+ (GRID_SIZE * .5), gridShader.r));
					}
					releaseTime = 0;
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
			layer = FlxMath.wrap(layer, -2, maxLayers - 1);
			FlxG.sound.play(Paths.sound('ui/scroll'));
		}
		if (layer > -1) {
			var target:RGBPalette = note.rgbs[layer];
			gridShader.copy(target);
		} else {
			gridShader.set(0xeeeeff, -1, 0x808099);
		}

		for (i in strumLine.members) {
			i.rgb.copy(gridShader);
		}

		layerCharName = Character.getIni(chart.lanes[layer]?.char)?.global?.name ?? 'Unnamed';

		grid.allowedColumns = grid.columns;

		if (layer > -1)
			grid.allowedColumns = chart.lanes[layer].keys;

		for (idx => i in strumLine.members) {
			var _visible = true;
			if (idx >= grid.allowedColumns && layer > -1)
				_visible = false;

			if (i.visible != _visible) {
				i.visible = _visible;
				CoolUtil.doSplash(i.getMidpoint().x, i.getMidpoint().y, i.strumRGB.r);
			}
		}

		if (editButton != null) {
			if (layer < 0) {
				// edit chart metadata
				editButton.quickColor(0xffcc99, 0x660033);
			} else {
				// edit current layer
				editButton.quickColor(gridShader.r.getLightened(0.6), gridShader.b.getDarkened(0.4));
			}
		}
	}

	public static function stepFromMS(ms:Float):Float {
		return ms / Conductor.stepCrochet;
	}

	public function getMaxKeyCount():Int {
		if (chart == null)
			return 0;
		var result:Int = 0;
		for (i in chart.lanes) {
			if (i.keys > result)
				result = i.keys;
		}
		return result;
	}
}

class ChartingNoteGroup extends Note {
	public var strumLine:StrumLine;
	public var chart:Array<ChartNote>;
	public var layer:Int = -1;
	public var gridSize(default, set):Float = 110;

	public var selecting:Bool = false;
	public var justPlaced:Bool = false;

	public var events:ChartEvents = {};

	var eventSprite:FlxSprite;

	public function set_gridSize(v:Float):Float {
		gridSize = v;

		setGraphicSize(v);
		updateHitbox();
		eventSprite.setGraphicSize(v);
		eventSprite.updateHitbox();

		sustain.scale.x = (v / sustain.frameWidth) * 0.7;
		return v;
	}

	public var rgbs:Array<RGBPalette> = [];

	var defaultEventGraphic = null;

	public function new(chart, strumLine, laneColors:Array<{base:Int, outline:Int}>) {
		super();
		this.chart = chart;
		this.strumLine = strumLine;
		for (idx => i in laneColors) {
			var colr = new RGBPalette();
			colr.set(i.base, -1, i.outline);
			rgbs[idx] = colr;
		}

		defaultEventGraphic = Paths.image('ui/editor/events/_default');

		eventSprite = new FlxSprite().loadGraphic(defaultEventGraphic);
		eventSprite.antialiasing = antialiasing;
	}

	var ogx:Float = 0;
	var ogy:Float = 0;

	var curShader:RGBPalette;

	override public function draw() {
		ogx = x;
		ogy = y;
		selecting = false;
		eventSprite.camera = camera;
		if (strumLine != null) {
			if (layer != -2)
				drawEvents();

			if (chart != null) {
				for (idx => bruh in chart) {
					var shouldDraw = (bruh.time + bruh.length) >= (Conductor.time - Conductor.crochet * 2)
						&& bruh.time <= (Conductor.time + (Conductor.crochet * 3));

					if (shouldDraw) {
						var gwa = rgbs[bruh.lane] ?? rgbs[0];
						curShader = gwa;
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

						if (FlxG.state.subState == null && FlxG.mouse.overlaps(this) && (bruh.lane == layer || layer == -1) || forceSelect == idx) {
							colorTransform.greenOffset = 128;
							selecting = true;
							handleSelection(idx);
						}

						super.draw();

						x = ogx;
						y = ogy;
					}
				}
			}
		}

		// make events appear in front ONLY if event layer is selected
		if (layer == -2)
			drawEvents();
	}

	function drawEvents() {
		if (events != null && events.events.length > 0) {
			for (idx => arr in events.events) {
				for (bruh in (arr : Array<Dynamic>)) {
					final e_strumTime:Float = bruh[0];
					final e_index:Int = bruh[1];

					var shouldDraw = e_strumTime >= (Conductor.time - Conductor.crochet * 2)
						&& e_strumTime <= (Conductor.time + (Conductor.crochet * 3));

					if (shouldDraw) {
						eventSprite.loadGraphic(Paths.image('ui/editor/events/${events.order[idx]}') ?? defaultEventGraphic);

						eventSprite.setPosition(x + (e_index * gridSize), y + ChartingState.stepFromMS(e_strumTime) * gridSize);
						eventSprite.alpha = 1;
						eventSprite.color = -1;
						if (!Conductor.paused && ((Conductor.time >= e_strumTime)) || (layer != -2)) {
							eventSprite.alpha = 0.1;
							eventSprite.color = 0x666666;
						}

						eventSprite.draw();
					}
				}
			}
		}
	}

	public var forceSelect:Int = -1;

	var valueX:Float = 0;
	var valueY:Float = 0;

	function handleSelection(idx:Int = 0) {
		// ill figure out moving notes later
		valueX = (FlxG.mouse.x - ogx - (gridSize * .5)) / gridSize;
		valueY = (FlxG.mouse.y - ogy - (gridSize * .5)) / gridSize;
		if (FlxG.mouse.pressed) {
			setPosition(FlxG.mouse.x - (gridSize * .5), FlxG.mouse.y - (gridSize * .5));
			forceSelect = idx;

			// try and make it not disappear if dragging it too far?
			chart[idx].time = valueY * Conductor.stepCrochet;
			// trace('[$valueX,$valueY]');
		}

		if (FlxG.mouse.justReleased) {
			if (ChartingState.releaseTime >= 0.05 && layer == chart[idx].lane) {
				chart.splice(idx, 1);
				FlxG.sound.play(Paths.sound('charter/noteErase'));
				CoolUtil.doSplash(FlxG.mouse.x, FlxG.mouse.y, curShader.r);
			} else {
				chart[idx].time = (FlxG.keys.pressed.SHIFT ? valueY : Math.round(valueY)) * Conductor.stepCrochet;
				chart[idx].index = Math.round(valueX);
				// Log.print('[${Math.round(valueX)},${valueY * Conductor.stepCrochet}]', 0x468427);
				if (justPlaced) {
					justPlaced = false;
				} else
					FlxG.sound.play(Paths.sound('charter/openWindow'));
			}

			forceSelect = -1;
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
	public var allowedColumns:Int = 4;

	public function new(image, repeat) {
		super(image, repeat, 0, 0);
	}

	override public function draw() {
		var ogx = x;
		var ogfy = flipY;

		for (idx in 0...columns) {
			color = 0xffffff;
			x = ogx + (scale.x * idx);
			flipY = idx % 2 == 1;
			if (idx > (allowedColumns - 1))
				color = 0x330066;
			super.draw();
		}
		x = ogx;
		flipY = ogfy;
	}
}
