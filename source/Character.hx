import tools.Ini;
import tools.Ini.IniData;
import flixel.FlxSpriteExt;

class Character extends FlxSpriteExt
{
  var ini:IniData;
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
		return Ini.parseFile(Paths.file(path));
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

			var sheets:Array<String> = (ini.global.sheets:String).split(",");
			frames = Paths.sparrow(sheets[0]);

			// idk why i named it obj
			var obj = ini.animations;
			for (animation in obj.keys()) {
				var split:Array<String> = (obj.get(animation):String).split(",");
				var hxAnim:String = animation;
				var animName:String = split[0];
				var animFPS:Float = Std.parseFloat(split[1]);
				var animLoop:Bool = (split[2] == "true");
				var offsets:Array<Float> = [Std.parseFloat(split[3]), Std.parseFloat(split[4])];
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
					this.animation.addByIndices(hxAnim, animName, indices, '', animFPS, animLoop);
        else
          this.animation.addByPrefix(hxAnim, animName, animFPS, animLoop);
				animOffsets.set(hxAnim, offsets);

				if (hxAnim == 'danceLeft' || hxAnim == 'danceRight')
					dancer = true;
			}

			antialiasing = (ini.global.exists("aa") ? (ini.global.aa:Bool) : true);
			if (ini.global.exists("flip") && (ini.global.flip:Bool))
				flipX = !flipX;

			if (ini.global.scale != null) {
				scaleMult.set(ini.global.scale, ini.global.scale);
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
