package objects;

import flixel.FlxSpriteExt;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.tile.FlxDrawQuadsItem;
import flixel.math.FlxAngle;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import song.Chart.ChartNote;
import util.RGBPalette;

class Note extends FlxSpriteExt {
	public static var angles:Array<Float> = [270, 180, 0, 90];

	public var rgb:RGBPalette = new RGBPalette();
	public var strumTime:Float = 0;
	public var strum:StrumNote;
	public var speed:Float = 1.0;
	public var strumIndex(default, set):Int = 2;
	public var aocondc:Bool = true; // stands for: angleOffset change on strumIndex change
	public var hit(default, set):NoteHitState = NONE;
	public var scrollAngle:Float = 0;
	public var sustain:Sustain;
	public var anim:String = null;
	public var editor:Bool = false;
	public var character:Character = null;
	public var scrollAngularVelocity:Float = 0;

	var parentGroup:FlxTypedGroup<Note>;

	public function set_hit(v:NoteHitState):NoteHitState {
		hit = v;
		if (hit == HIT)
			kill();
		return v;
	}

	public function set_strumIndex(v:Int):Int {
		if (aocondc)
			angleOffset = angles[FlxMath.wrap(v, 0, angles.length - 1)];
		return strumIndex = v;
	}

	var originalOffsets = [0.0, 0.0];

	public function new(?strumIndex:Int = 2) {
		super();
		sustain = new Sustain(this);
		this.strumIndex = strumIndex;
		frames = Paths.sparrow('ui/note');
		animation.addByPrefix('idle', 'idle', 24, false);
		animation.play('idle', true);
		scale.set(0.7, 0.7);
		updateHitbox();

		antialiasing = true;
		moves = false;

		shader = rgb.shader;
		rgb.set(0x717171, -1, 0x333333);

		originalOffsets = [offset.x, offset.y]; // for fun anim
	}

	override function update(elapsed:Float) {
		if (moves) {
			scrollAngle += scrollAngularVelocity * elapsed;
		}
		super.update(elapsed);
		if (strum != null) {
			followStrum(strum);
		}
		if (sustain != null)
			sustain.update(elapsed);
	}

	override function draw() {
		if (sustain != null && sustain.length >= Sustain.minDrawLength)
			sustain.draw();
		super.draw();
	}

	override function kill() {
		if (parentGroup != null)
			parentGroup.remove(this);
		if (sustain != null)
			sustain.kill();
		if (strum != null)
			strum.notes.remove(this);

		super.kill();
	}

	public var _shouldDoHit:Bool = false;

	var _origLen:Float = -1;

	function doHit() {
		if (sustain != null && sustain.length > 0) {
			if (_origLen == -1) {
				var diff = strumTime - Conductor.time;
				sustain.length += diff;
			}

			if (_shouldDoHit) {
				if (_origLen == -1) {
					_origLen = sustain.length;
					strumTime -= Conductor.delta;
				} else {
					strumTime = Conductor.time;
				}

				sustain.length -= Conductor.delta;
				hit = HELD;
				if (sustain.length <= Sustain.mercyThreshold)
					hit = HELD_MERCY;

				// fun anim !!! :3
				final shake:Float = 12;

				blend = ADD;
				offset.x = originalOffsets[0] + FlxG.random.float(-1, 1) * shake;
				offset.y = originalOffsets[1] + FlxG.random.float(-1, 1) * shake;
				color = 0x808080; // ???
			}
		} else {
			hit = HIT;
			kill();
		}
	}

	var copyProps = {
		x: true,
		y: true,
		angle: true,
		angleOffset: true,
		alpha: true,
		visible: true
	};

	public var totalAngle(get, never):Float;

	public function get_totalAngle():Float {
		if (strum != null && strum is Note)
			return scrollAngle + strum.scrollAngle;
		return scrollAngle;
	}

	function followStrum(strum:StrumNote) {
		var grah = totalAngle * (Math.PI / -180);
		var distance = (strumTime - Conductor.time) * 0.45 * speed;

		if (copyProps.x)
			x = strum.x + FlxMath.fastSin(grah) * distance;

		if (copyProps.y)
			y = strum.y + FlxMath.fastCos(grah) * distance;

		if (copyProps.angle)
			angle = strum.angle;

		if (copyProps.angleOffset)
			angleOffset = strum.angleOffset;

		if (copyProps.alpha)
			alpha = strum.alpha;

		if (copyProps.visible)
			visible = strum.visible;
	}

	public static function fromChartNote(not:ChartNote):Note {
		var note = new Note(not.index);
		note.strumTime = not.time;
		note.strumIndex = not.index;
		note.sustain.length = not.length;

		return note;
	}

	override function isOnScreen(?camera:FlxCamera):Bool {
		if (sustain != null && sustain.length >= 100)
			return true;

		return super.isOnScreen(camera);
	}

	// dynamic, so you can edit scoring system cus why not
	// should i make it static ? idk
	public dynamic function score(diff:Float = 0):Int {
		// not gonna bother rewriting the pbot1 score system from scratch
		var absTiming:Float = Math.abs(diff);

		/**
		 * The maximum score a note can receive.
		 */
		var PBOT1_MAX_SCORE:Int = 500;

		/**
		 * The offset of the sigmoid curve for the scoring function.
		 */
		var PBOT1_SCORING_OFFSET:Float = 54.99;

		/**
		 * The slope of the sigmoid curve for the scoring function.
		 */
		var PBOT1_SCORING_SLOPE:Float = 0.080;

		/**
		 * The minimum score a note can receive while still being considered a hit.
		 */
		var PBOT1_MIN_SCORE:Float = 9.0;

		var factor:Float = 1.0 - (1.0 / (1.0 + Math.exp(-PBOT1_SCORING_SLOPE * (absTiming - PBOT1_SCORING_OFFSET))));

		var score:Int = Std.int(PBOT1_MAX_SCORE * factor + PBOT1_MIN_SCORE);
		score = Std.int(FlxMath.bound(score, 0, PBOT1_MAX_SCORE));

		return score;
		// return 0;
	}

	public dynamic function judge(diff:Float = 0):String {
		var absTiming:Float = Math.abs(diff);
		if (absTiming <= 45)
			return 'sick';
		if (absTiming <= 90)
			return 'good';
		if (absTiming <= 120)
			return 'bad';
		return 'shit';
	}

	public var rating:String = null;
}

class Sustain extends FlxSpriteExt {
	public static var minDrawLength:Float = 30;
	public static var mercyThreshold:Float = 123;

	public var length:Float = 0;
	public var parent:Note = null;

	public function new(parent:Note) {
		super();
		this.parent = parent;
		frames = Paths.sparrow('ui/note');
		animation.addByPrefix('hold', 'hold', 24, false);
		animation.addByPrefix('tail', 'tail', 24, false);
		animation.play('tail', true);
		scale.set(0.7, 0.7);
		updateHitbox();

		antialiasing = true;
		moves = false;
		clipRect = new FlxRect(0, 0, frameWidth, frameHeight);
	}

	override function update(elapsed:Float) {
		if (parent != null) {
			followNote(parent);
		}
		super.update(elapsed);
	}

	var copyProps = {
		x: true,
		y: true,
		alpha: true,
		scrollAngle: true,
		visible: true
	};

	function followNote(strum:Note, ?speed:Float = 1) {
		if (copyProps.x)
			x = (strum.getMidpoint().x - width * 0.5);

		if (copyProps.y)
			y = strum.getMidpoint().y;

		if (copyProps.scrollAngle)
			angle = strum.totalAngle;

		if (copyProps.alpha)
			alpha = strum.alpha;

		if (copyProps.visible)
			visible = strum.visible;
	}

	public var susHeight(get, null):Float = 0;

	public function get_susHeight():Float {
		return length * 0.45 * (parent?.speed ?? 1);
	}

	/*private inline function updateVisual(l:Float, ?s:Float = 1) {
		animation.play('hold', true);
		var ogScale:Float = scale.x;
		susHeight = (l * 0.45 * s) + 2;
		setGraphicSize(width, susHeight);
		scale.x = ogScale;
		updateHitbox();
		origin.y = 0;
	}*/
	override public function draw() {
		if (parent != null) {
			shader = parent.shader;
		}

		if (susHeight <= 0)
			return;

		/*var ogScale:Float = scale.y;
			updateVisual(length, parent?.speed ?? 1);

			// TODO: tiled sustains instead of stretched
			var bruh = height;
			y -= bruh * 0.5;
			super.draw();
			scale.y = ogScale;
			y += bruh * 0.5;
			y -= 2.5;
			animation.play('tail', true);
			updateHitbox();
			offset.y = origin.y = (bruh) * (-1 / scale.y); */
		super.draw();
	}

	var tailOffset:Float = 1.2;

	inline function hasCTMult():Bool {
		var c = colorTransform;
		if (c == null)
			return true;
		return c.redMultiplier == 1 && c.greenMultiplier == 1 && c.blueMultiplier == 1 && c.alphaMultiplier == 1;
	}

	inline function hasCTOff():Bool {
		var c = colorTransform;
		if (c == null)
			return true;
		return c.redOffset == 0 && c.greenOffset == 0 && c.blueOffset == 0 && c.alphaOffset == 0;
	}

	override public function drawComplex(cam:FlxCamera) {
		// draw tail
		animation.play('tail');
		updateHitbox();
		final _tailHeight = frameHeight;
		offset.y = origin.y = (susHeight) * (-1 / scale.y) + _tailHeight - tailOffset;
		var startingPoint:Float = offset.y + tailOffset;
		super.drawComplex(cam);

		// draw the rest of the tiles
		origin.y = 0;
		animation.play('hold');
		final _frameHeight = frameHeight - 2;
		var item:FlxDrawQuadsItem = cam.startQuadBatch(_frame.parent, hasCTMult(), hasCTOff(), blend, antialiasing, shader);
		final tileFracts:Float = (susHeight - _tailHeight) / _frameHeight / scale.y;
		final tileCount:Int = Math.ceil(tileFracts);
		var __index:Int = tileCount;
		offset.y = startingPoint - tailOffset;
		while (__index > 0) {
			offset.y += _frameHeight;
			item.addQuad(_frame, doFuckingMatrixThing(__index), colorTransform);

			__index -= 1;
		}
	}

	override function isOnScreen(?camera:FlxCamera):Bool {
		// not gonna bother with calculating length
		return susHeight > 0;
	}

	var _______mat:FlxMatrix = new FlxMatrix();

	inline function doFuckingMatrixThing(tile:Int) {
		var _matrix = _______mat; // i aint doing all that

		// brah
		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0);
		inline _matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x * scaleMult.x, scale.y * scaleMult.y);
		if (checkFlipX()) {
			_matrix.a *= -1;
			_matrix.c *= -1;
			_matrix.tx *= -1;
		}
		if (checkFlipY()) {
			_matrix.b *= -1;
			_matrix.d *= -1;
			_matrix.ty *= -1;
		}

		var radians:Float = (angle + angleOffset) * FlxAngle.TO_RAD;
		var _sinAngleCustom = Math.sin(radians);
		var _cosAngleCustom = Math.cos(radians);

		if (radians != 0)
			_matrix.rotateWithTrig(_cosAngleCustom, _sinAngleCustom);

		var ogoffx = offset.x;
		var ogoffy = offset.y;

		offset.addPoint(offsetOffset);

		offset.x *= scale.x * scaleMult.x;
		offset.y *= scale.y * scaleMult.y;
		offset.degrees += angle + angleOffset;

		if (additiveOffset)
			getScreenPosition(_point, camera).addPoint(offset);
		else
			getScreenPosition(_point, camera).subtractPoint(offset);
		_point.addPoint(origin);

		offset.x = ogoffx;
		offset.y = ogoffy;

		inline _matrix.translate(_point.x, _point.y);

		return _matrix;
	}
}

// floats aren't worth it
enum NoteHitState {
	NONE;
	MISS;
	HELD;
	HELD_MERCY;
	HIT;
}
