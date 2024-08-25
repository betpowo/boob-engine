import flixel.VaryingSprite;

class Character extends VaryingSprite
{
	var ini:SSIni = new SSIni();
	var animOffsets:Map<String, Array<Float>> = [];

	public function new(char:String = 'bf')
	{
		super();
		scaleOffset = true;
		build(char);

		Conductor.beatHit.add(beatHit);
	}

	public function build(char:String = 'bf'):Bool
	{
		try
		{
			var path = 'data/characters/' + char + '.ini';
			if (!Paths.exists(path))
				path = 'data/characters/bf.ini';

			path = Paths.file(path);
			var guhTime = ini.doString(path);
			// Log.print('the time : $guhTime', 0xffcc66);

			var sheets = ini.getSection().sheets.split(',');

			frames = Paths.sparrow(sheets[0]);

			// idk why i named it obj
			var obj = ini.getSection('animations');
			for (field in Reflect.fields(obj))
			{
				var split = Reflect.getProperty(obj, field).split(',');
				final hxAnim:String = field;
				final animName:String = split[0];
				final animFPS:Float = Std.parseFloat(split[1]);
				final animLoop:Bool = split[2] == 'true';
				final offsets = [Std.parseFloat(split[3]), Std.parseFloat(split[4])];
				// later
				// final indices:Array<Int> = null;

				animation.addByPrefix(hxAnim, animName, animFPS, animLoop);
				animOffsets.set(hxAnim, offsets);
			}
			antialiasing = (ini.getSection()?.aa ?? 'true') == 'true';
			if ((ini.getSection()?.flip ?? 'false') == 'true')
				scale.x *= -1;

			if (ini.getSection().scale != null)
			{
				var fuck = Std.parseFloat(ini.getSection()?.scale ?? '1');
				scaleMult.set(fuck, fuck);
			}

			updateHitbox();
			dance();
			return true;
		}
		catch (e)
		{
			Log.print('EPIC FAIL (build) : $e', 0xff3366);
		}
		return false;
	}

	public function dance()
	{
		playAnim('idle', false);
	}

	public var holdTime:Float = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (holdTime >= 0)
		{
			holdTime -= elapsed;
		}
		else if (holdTime != -1)
		{
			holdTime = -1;
			dance();
		}
	}

	public function beatHit()
	{
		if (holdTime == -1)
		{
			dance();
		}
	}

	public function playAnim(anim:String, ?force:Bool = true, ?reverse:Bool = false, ?start:Int = 0)
	{
		if (scale.x < 0) // flipped
		{
			if (anim.contains('LEFT'))
				anim = anim.replace('LEFT', 'RIGHT');
			else if (anim.contains('RIGHT'))
				anim = anim.replace('RIGHT', 'LEFT');
		}

		animation.play(anim, force, reverse, start);
		if (animOffsets.exists(anim))
		{
			var val = animOffsets[anim];
			offset.x = val[0] * (flipX ? -1 : 1);
			offset.y = val[1] * (flipY ? -1 : 1);
		}
	}
}
