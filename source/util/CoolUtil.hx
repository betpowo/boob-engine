package util;

import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;
import openfl.geom.Rectangle;
import util.GradientMap;

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

	public static function makeTardlingText(text:String, col1:FlxColor = 0xffffff, col2:FlxColor = 0xff000000):FlxBitmapText {
		var fontLetters:String = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz:1234567890!?,.()-Ññ&\"'+[]/#";

		var text = new FlxBitmapText(0, 0, text, FlxBitmapFont.fromMonospace(Paths.image('ui/tardlingSpritesheet'), fontLetters, FlxPoint.get(49, 62)));
		text.letterSpacing = -15;
		text.antialiasing = true;

		var songNameGM:GradientMap = new GradientMap();
		text.shader = songNameGM.shader;
		songNameGM.set(col1, col2);

		return text;
	}
}
