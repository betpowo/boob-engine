import flixel.VaryingSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

class Note extends VaryingSprite
{
	public static var angles:Array<Float> = [270, 180, 0, 90];

	public var rgb:RGBPalette = new RGBPalette();
	public var strumTime:Float = 0;
	public var strumTracker:StrumNote;
	public var speed:Float = 1.0;
	public var speedMult:Float = 1.0;
	public var noteData(default, set):Int = 2;
	public var aocondc:Bool = true; // stands for: angleOffset change on noteData change
	public var hit(default, set):NoteHitState = NONE;
	public var scrollAngle:Float = 0;
	public var sustain:Sustain;

	var parentGroup:FlxTypedGroup<Note>;

	public function set_hit(v:NoteHitState):NoteHitState
	{
		hit = v;
		if (hit == HIT)
			kill();
		return v;
	}

	public function set_noteData(v:Int):Int
	{
		if (aocondc)
			angleOffset = angles[FlxMath.wrap(v, 0, angles.length - 1)];
		return noteData = v;
	}

	var originalOffsets = [0.0, 0.0];

	public function new(?noteData:Int = 2)
	{
		super();
		sustain = new Sustain(this);
		this.noteData = noteData;
		frames = FlxAtlasFrames.fromSparrow('assets/note.png', 'assets/note.xml');
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

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (strumTracker != null)
		{
			followStrum(strumTracker);
		}
		if (sustain != null)
			sustain.update(elapsed);
	}

	override function draw()
	{
		if (sustain != null && sustain.length >= 10)
			sustain.draw();
		super.draw();
	}

	override function kill()
	{
		super.kill();
		if (parentGroup != null)
			parentGroup.remove(this);
	}

	public var _shouldDoHit:Bool = false;

	var _origLen:Float = -1;

	function doHit()
	{
		if (sustain != null && sustain.length > 0)
		{
			if (_shouldDoHit)
			{
				if (_origLen == -1)
					_origLen = sustain.length;

				strumTime = Conductor.time;
				sustain.length -= Conductor.delta;
				hit = HELD;

				// fun anim !!! :3
				blend = ADD;
				offset.x = originalOffsets[0] + FlxG.random.float(-1, 1) * 7;
				offset.y = originalOffsets[1] + FlxG.random.float(-1, 1) * 7;
			}
		}
		else
		{
			hit = HIT;
		}
	}

	var copyProps = {
		x: true,
		y: true,
		angle: true,
		angleOffset: true,
		alpha: true
	};

	function followStrum(strum:StrumNote)
	{
		var grah = scrollAngle * (Math.PI / -180);
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
	}
}

class Sustain extends VaryingSprite
{
	public var length:Float = 0;
	public var parent:Note = null;

	public function new(parent:Note)
	{
		super();
		this.parent = parent;
		frames = FlxAtlasFrames.fromSparrow('assets/note.png', 'assets/note.xml');
		animation.addByPrefix('hold', 'hold', 24, false);
		animation.addByPrefix('tail', 'tail', 24, false);
		animation.play('tail', true);
		scale.set(0.7, 0.7);
		updateHitbox();

		antialiasing = true;
		moves = false;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (parent != null)
			followNote(parent);
	}

	var copyProps = {
		x: true,
		y: true,
		alpha: true
	};

	function followNote(strum:Note, ?speed:Float = 1)
	{
		if (copyProps.x)
			x = (strum.getMidpoint().x - width * 0.5);

		if (copyProps.y)
			y = strum.y + 55;

		angle = strum.scrollAngle;

		if (copyProps.alpha)
			alpha = strum.alpha;
	}

	var _lastShit = {
		length: 0,
		speed: 1,
		speedMult: 1
	}

	private function updateVisual(l:Float, ?s:Float = 1, ?m:Float = 1)
	{
		animation.play('hold', true);
		setGraphicSize(Std.int(width), Std.int(l * 0.475 * s * m));
		updateHitbox();
	}

	override public function draw()
	{
		if (shader == null)
			shader = parent.shader;

		var bruh = height;
		super.draw();
		scale.y = 0.7;
		updateHitbox();
		y += bruh;
		animation.play('tail', true);
		super.draw();
		y -= bruh;

		if (parent != null)
			updateVisual(length, parent.speed, parent.speedMult);
		else
			updateVisual(length);
	}
}

// floats aren't worth it
enum NoteHitState
{
	NONE;
	HELD;
	HIT;
}
