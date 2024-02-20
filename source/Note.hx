import flixel.VaryingSprite;
import flixel.math.FlxPoint;

class Note extends VaryingSprite
{
	public static var angles:Array<Float> = [270, 180, 0, 90];

	public var rgb:RGBPalette = new RGBPalette();
	public var strumTime:Float = 0;
	public var strumTracker:StrumNote;
	public var noteSpeed:Float = 1.0;
	public var noteData(default, set):Int = 2;
	public var aocondc:Bool = true; // stands for: angleOffset change on noteData change
	public var hitAmount(default, set):Float = 0.0; // its a float cus of sustain notes which will be added later
	public var scrollAngle:Float = 0;
	public var sustainLength(default, set):Float = 0.0;

	var sustainSprite:VaryingSprite = new VaryingSprite();

	var parentGroup:FlxTypedGroup<Note>;

	public function set_hitAmount(v:Float):Float
	{
		if (v >= 1)
			kill();
		return hitAmount = v;
	}

	public function set_noteData(v:Int):Int
	{
		if (aocondc)
			angleOffset = angles[FlxMath.wrap(v, 0, angles.length - 1)];
		return noteData = v;
	}

	public function set_sustainLength(v:Float):Float
	{
		// used only to set it to 0 in StrumNote
		return sustainLength = v;
	}

	public function new(?noteData:Int = 2)
	{
		super();
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

		sustainSprite.shader = shader;
		sustainSprite.frames = frames;
		sustainSprite.animation.addByPrefix('hold', 'hold', 24, false);
		sustainSprite.animation.addByPrefix('tail', 'tail', 24, false);
		sustainSprite.scale.copyFrom(scale);
		sustainSprite.updateHitbox();
		sustainSprite.alphaMult = 0.6;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (strumTracker != null)
		{
			followStrum(strumTracker, noteSpeed);
		}
	}

	override function draw()
	{
		if (sustainLength > 100)
		{
			sustainSprite.animation.play('tail', true);
			sustainSprite.scale.x = scale.x;
			sustainSprite.alpha = alpha;
			sustainSprite.updateHitbox();
			sustainSprite.setPosition(x + ((width - sustainSprite.width) / 2), y + (height / 2));
			sustainSprite.scale.y = (sustainLength / 50) * 0.45 * PlayState.chart.speed * noteSpeed;
			sustainSprite.updateHitbox();
			sustainSprite.angle = scrollAngle;
			sustainSprite.draw();

			var lastXYWH = {
				x: sustainSprite.x,
				y: sustainSprite.y,
				width: sustainSprite.width,
				height: sustainSprite.height
			};

			// do it again
			sustainSprite.animation.play('hold', true);
			sustainSprite.scale.y = scale.y;
			sustainSprite.updateHitbox();
			sustainSprite.setPosition(lastXYWH.x, lastXYWH.y + lastXYWH.height);

			sustainSprite.draw();
		}
		super.draw();
	}

	override function kill()
	{
		super.kill();
		if (parentGroup != null)
			parentGroup.remove(this);
	}

	function hit()
	{
		// normal ass note
		// if (sustainLength < 100)
		hitAmount = 1;
		// else
		// { // stinky sustain
		// hitAmount = FlxMath.bound(strumTime / (strumTime + sustainLength), 0, 1);
		// }
	}

	var copyProps = {
		x: true,
		y: true,
		angle: true,
		angleOffset: true,
		alpha: true
	};

	function followStrum(strum:StrumNote, ?speed:Float = 1)
	{
		var grah = scrollAngle * (Math.PI / -180);
		var distance = (strumTime - Conductor.time) * 0.45 * PlayState.chart.speed * speed;

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
