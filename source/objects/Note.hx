package objects;

import flixel.FlxSpriteExt;
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
		if (sustain != null && sustain.length >= 10)
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

				// fun anim !!! :3
				blend = ADD;
				offset.x = originalOffsets[0] + FlxG.random.float(-1, 1) * 7;
				offset.y = originalOffsets[1] + FlxG.random.float(-1, 1) * 7;
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
		if (absTiming <= 130)
			return 'bad';
		return 'shit';
	}

	public var rating:String = null;
}

class Sustain extends FlxSpriteExt {
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
	}

	override function update(elapsed:Float) {
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

	private inline function updateVisual(l:Float, ?s:Float = 1) {
		animation.play('hold', true);
		setGraphicSize(width, (l * 0.48 * s) + 2);
		updateHitbox();
		origin.y = 0;
	}

	override public function draw() {
		if (parent != null) {
			followNote(parent);
			shader = parent.shader;
		}

		updateVisual(length, parent?.speed ?? 1);

		var bruh = height;
		y -= bruh * 0.5;
		super.draw();
		scale.y = 0.7;
		y += bruh * 0.5;
		y -= 2.5;
		animation.play('tail', true);
		updateHitbox();
		offset.y = origin.y = (bruh) * (-1 / scale.y);
		super.draw();
	}

	function doRotate() {
		if (parent != null) {
			var gwa = FlxPoint.weak(x, y).pivotDegrees(FlxPoint.weak(parent.getMidpoint().x, parent.getMidpoint().y), parent.totalAngle);
			setPosition(gwa.x, gwa.y);
		}
	}
}

// floats aren't worth it
enum NoteHitState {
	NONE;
	HELD;
	HIT;
}
