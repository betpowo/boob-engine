import tools.Ini;
import flixel.VaryingSprite;

class Character extends VaryingSprite
{
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

			var data:IniData = Ini.parseFile(Paths.file(path));

			var sheets:Array<String> = (data.global.sheets:String).split(",");
			frames = Paths.sparrow(sheets[0]);

			// idk why i named it obj
			var obj = data.animations;
			for (animation in obj.keys()) {
				var split:Array<String> = (obj.get(animation):String).split(",");
				var hxAnim:String = animation;
				var animName:String = split[0];
				var animFPS:Float = Std.parseFloat(split[1]);
				var animLoop:Bool = (split[2] == "true");
				var offsets:Array<Float> = [Std.parseFloat(split[3]), Std.parseFloat(split[4])];
				// later
				// final indices:Array<Int> = null;

				this.animation.addByPrefix(hxAnim, animName, animFPS, animLoop);
				animOffsets.set(hxAnim, offsets);
			}

			antialiasing = (data.global.exists("aa") ? (data.global.aa:Bool) : true);
			if (data.global.exists("flip") && (data.global.flip:Bool))
				scale.x *= -1;

			if (data.global.scale != null) {
				scaleMult.set(data.global.scale, data.global.scale);
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
