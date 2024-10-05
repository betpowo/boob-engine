package objects;

import flixel.FlxSpriteExt;
import flixel.util.FlxDestroyUtil;
import tools.Ini.IniData;
import tools.Ini;
import util.HscriptHandler;

class Character extends FlxSpriteExt {
	public var ini:IniData;
	public var holdDur:Float = 4;

	public var animOffsets:Map<String, Array<Float>> = [];
	public var skipDance:Bool = false;

	public var stagePos:FlxPoint = new FlxPoint(0, 0);

	public var script:HscriptHandler;

	var initAlready:Bool = false;
	var debugMode:Bool = false;

	// character will call script create and update functions automatically if true
	// (auto = doesnt require a parent state for it to call (e.g. PlayState))
	var autoCallBasicShit:Bool = true;

	public function new(char:String = 'bf', ?debug:Bool = false, ?autocall:Bool = true) {
		super();
		rotateOffset = scaleOffsetX = scaleOffsetY = true;

		debugMode = debug;
		autoCallBasicShit = autocall;

		build(char);
		if (autoCallBasicShit)
			call('create');
		Conductor.beatHit.add(beatHit);
	}

	public function call(f:String, ?args:Array<Dynamic>) {
		script?.call(f, args);
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

	public function setStagePosition(_x:Float = 0, _y:Float = 0) {
		setPosition(_x, _y);
		x -= width * .5;
		y -= height;
		call('onSetStagePos');
		stagePos.set(_x, _y);
	}

	public function build(char:String = 'bf'):Bool {
		if (!initAlready)
			initAlready = true;
		else
			call('destroy');

		script = FlxDestroyUtil.destroy(script);

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

			if (Paths.exists('data/characters/' + char + '.hx') && !debugMode) {
				script = new HscriptHandler(char, 'data/characters');
				script.setVariable('this', this);
				call('build');
			}

			setStagePosition(stagePos.x, stagePos.y);

			return true;
		} catch (e) {
			Log.print('EPIC FAIL (build) : $e', 0xff3366);
			setStagePosition(stagePos.x, stagePos.y);
		}
		return false;
	}

	public function dance() {
		if (skipDance)
			return;

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
		if (autoCallBasicShit)
			call('update', [elapsed]);
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

		if (animation.exists(anim))
			animation.play(anim, force, reverse, start);

		if (animOffsets.exists(anim)) {
			var val = animOffsets[anim];
			offset.x = val[0] * (flipX ? -1 : 1);
			offset.y = val[1] * (flipY ? -1 : 1);
		}

		if (animation.curAnim != null && animation.curAnim?.curFrame == 0)
			call('playAnim', [anim, force, reverse, start]);
	}

	override function destroy() {
		call('destroy');
		script = FlxDestroyUtil.destroy(script);
		super.destroy();
	}
}
