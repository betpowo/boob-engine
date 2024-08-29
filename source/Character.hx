import flixel.FlxSpriteExt;

class Character extends FlxSpriteExt
{
	var ini:SSIni;
	var animOffsets:Map<String, Array<Float>> = [];

	public function new(char:String = 'bf')
	{
		super();
		scaleOffset = true;
		build(char);

		Conductor.beatHit.add(beatHit);
	}

	public static function getIni(char:String = 'bf'):SSIni
	{
		var path = 'data/characters/' + char;
		if (!Paths.exists(path + '.ini'))
			path = 'data/characters/bf';

		path = Paths.file(path + '.ini');
		return new SSIni(path);
	}

	var dancer:Bool = false; // uses danceLeft/Right instead of idle
	private var _danced:Bool = false;

	public function build(char:String = 'bf'):Bool
	{
		try
		{
			dancer = false;
			ini = getIni(char);
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
				var indices:Array<Int> = null;

				if (split[5] != null)
				{
					if (~/[0-9]+-[0-9]+/g.match(split[5]))
					{
						var result:Array<Int> = [];
						var fuck = split[5].split('-');
						var start:Int = Std.parseInt(fuck[0]);
						var end:Int = Std.parseInt(fuck[1]);
						var ind:Int = start;
						while (ind <= end)
						{
							result.push(ind++);
						}
						indices = result;
					}
					else
					{
						var fuck:Array<Int> = [];
						for (i in split[5].split('/'))
							fuck.push(Std.parseInt(i));
						indices = fuck;
					}
				}

				if (indices != null)
					animation.addByIndices(hxAnim, animName, indices, '', animFPS, animLoop);
				else
					animation.addByPrefix(hxAnim, animName, animFPS, animLoop);
				animOffsets.set(hxAnim, offsets);

				if (hxAnim == 'danceLeft' || hxAnim == 'danceRight')
					dancer = true;
			}
			antialiasing = (ini.getSection()?.aa ?? 'true') == 'true';
			if ((ini.getSection()?.flip ?? 'false') == 'true')
			{
				// scale.x *= -1;
				flipX = !flipX;
			}

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
		if (dancer)
		{
			playAnim('dance' + (_danced ? 'Right' : 'Left'), false);
			_danced = !_danced;
		}
		else
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
		if (scale.x < 0 || flipX) // flipped
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
