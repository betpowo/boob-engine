class Note extends flixel.VaryingSprite
{
	public static var angles:Array<Float> = [270, 180, 0, 90];

	public var rgb:RGBPalette = new RGBPalette();
	public var strumTime:Float = 0;
	public var strumTracker:StrumNote;
	public var noteSpeed:Float = 1.0;
	public var noteData(default, set):Int = 2;
	public var aocondc:Bool = true; // stands for: angleOffset change on noteData change
	public var hit:Float = 0.0; // its a float cus of sustain notes which will be added later
	public var scrollAngle:Float = 0;

	var parentGroup:FlxTypedGroup<Note>;

	public function set_noteData(v:Int):Int
	{
		if (aocondc)
			angleOffset = angles[FlxMath.wrap(v, 0, angles.length - 1)];
		return noteData = v;
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
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (strumTracker != null)
		{
			followStrum(strumTracker, noteSpeed);
		}
	}

	override function kill()
	{
		hit = 1;
		super.kill();
		if (parentGroup != null)
			parentGroup.remove(this);
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
