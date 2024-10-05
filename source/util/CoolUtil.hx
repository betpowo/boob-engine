package util;

import flixel.addons.ui.FlxUI9SliceSprite;
import openfl.geom.Rectangle;

// baby
class CoolUtil {
	public static function make9Slice(?path:String = 'ui/editor/image_button', ?slices:Array<Int>, ?w:Float = 1, ?h:Float = 1) {
		slices ??= [25, 25, 75, 75];
		return new FlxUI9SliceSprite(0, 0, Paths.image(path, null, true), new Rectangle(0, 0, w, h), slices);
	}

	public static function doSplash(x:Float = 0, y:Float = 0, color:FlxColor = 0x717171):FlxSprite {
		var splash:FlxSprite = cast FlxG.state.recycle(FlxSprite);
		splash.frames = Paths.sparrow('ui/splashEffect');
		splash.animation.addByPrefix('idle', 'splash ${FlxG.random.int(1, 2)}', 16, false);
		splash.animation.play('idle', true);
		splash.animation.finishCallback = function(a) {
			splash.kill();
			FlxG.state.remove(splash);
			splash.destroy();
		}

		var rgb:FlxColor = color;
		splash.updateHitbox();
		splash.setColorTransform(1, 1, 1, 1, rgb.red, rgb.green, rgb.blue);
		splash.setPosition(x, y);
		splash.x -= splash.width * .5;
		splash.y -= splash.height * .5;
		splash.antialiasing = true;
		splash.blend = SCREEN;

		return splash;
	}
}
