package objects;

import flixel.FlxSpriteExt;
import tools.Ini.IniData;
import tools.Ini;

class Character extends FlxSpriteExt {
	public var ini:IniData;
	public var holdDur:Float = 4;

	var animOffsets:Map<String, Array<Float>> = [];

	public function new(char:String = 'bf') {
		super();
		scaleOffset = true;
		build(char);

		Conductor.beatHit.add(beatHit);
	}

	public static function getIni(char:String = 'bf'):IniData {
		var path = 'data/characters/' + char;
		if (!Paths.exists(path + '.ini'))
			path = 'data/characters/bf';

		path = Paths.file(path + '.ini');
		return Ini.parseFile(path);
	}

	var dancer:Bool = false; // uses danceLeft/Right instead of idle
	private var _danced:Bool = false;

	public function build(char:String = 'bf'):Bool {
		try {
			dancer = false;
			ini = getIni(char);
			// Log.print('the time : $guhTime', 0xffcc66);

			var sheets:Array<String> = (ini.global.sheets : String).split(",");
			var atlas = Paths.sparrow(sheets[0]);

			for (i in 1...sheets.length)
				atlas.addAtlas(Paths.sparrow(sheets[i]));

			frames = atlas;

			// idk why i named it obj
			var obj = ini.animations;
			for (animation in obj.keys()) {
				var split:Array<String> = (obj.get(animation) : String).split(",");
				var hxAnim:String = animation;
				var animName:String = split[0];
				var animFPS:Float = Std.parseFloat(split[1]);
				var animLoop:Bool = (split[2] == "true");
				var offsets:Array<Float> = [Std.parseFloat(split[3]), Std.parseFloat(split[4])];
				// later
				var indices:Array<Int> = null;

				if (split[5] != null) {
					var result:Array<Int> = [];
					for (i in split[5].split('/')) {
						if (~/[0-9]+-[0-9]+/g.match(i)) {
							var subindices = i.split('-');
							var start:Int = Std.parseInt(subindices[0]);
							var end:Int = Std.parseInt(subindices[1]);
							var ind:Int = start;
							while (ind <= end) {
								result.push(ind++);
							}
						} else
							result.push(Std.parseInt(i));
					}
					indices = result;
					// trace(result);
				}

				if (indices != null)
					this.animation.addByIndices(hxAnim, animName, indices, '', animFPS, animLoop);
				else
					this.animation.addByPrefix(hxAnim, animName, animFPS, animLoop);

				animOffsets.set(hxAnim, offsets);

				if (hxAnim.startsWith('danceLeft') || hxAnim.startsWith('danceRight'))
					dancer = true;
			}

			antialiasing = (ini.global.exists("aa") ? (ini.global.aa : Bool) : true);
			if (ini.global.exists("flip") && (ini.global.flip : Bool))
				flipX = !flipX;

			if (ini.global.exists("hold")) {
				holdDur = (ini.global.hold : Float);
			}

			if (ini.global.scale != null) {
				scaleMult.set(ini.global.scale, ini.global.scale);
			}

			dance();
			updateHitbox();

			return true;
		} catch (e) {
			Log.print('EPIC FAIL (build) : $e', 0xff3366);
		}
		return false;
	}

	public function dance() {
		if (dancer) {
			playAnim('dance' + (_danced ? 'Right' : 'Left'), false);
			_danced = !_danced;
		} else
			playAnim('idle', false);
	}

	public var holdTime:Float = 0;

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (holdTime >= 0) {
			holdTime -= elapsed;
		} else if (holdTime != -1) {
			holdTime = -1;
			if (!dancer) // prevent weird quick bop after hold time is over (it throws me off)
				dance();
		}
		if (animation != null) {
			if (animation.exists(animation.name + '-hold') && animation.finished) {
				playAnim(animation.name + '-hold', true);
			}
		}
	}

	public function beatHit() {
		if (holdTime == -1) {
			dance();
		}
	}

	public function playAnim(anim:String, ?force:Bool = true, ?reverse:Bool = false, ?start:Int = 0) {
		if (scale.x < 0 || flipX) // flipped
		{
			if (anim.contains('LEFT'))
				anim = anim.replace('LEFT', 'RIGHT');
			else if (anim.contains('RIGHT'))
				anim = anim.replace('RIGHT', 'LEFT');
		}

		animation.play(anim, force, reverse, start);
		if (animOffsets.exists(anim)) {
			var val = animOffsets[anim];
			offset.x = val[0] * (flipX ? -1 : 1);
			offset.y = val[1] * (flipY ? -1 : 1);
		}
	}
}