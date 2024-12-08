package objects.ui;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;

class HealthIcon extends FlxSprite {
	public var dying(default, set):Bool;
	public var icon(default, set):String = null;

	public function new() {
		super();
		icon = '_default';
	}

	public function set_icon(c:String):String {
		icon = c;
		final defaultImage = Paths.image('ui/icons/_default');
		var image:FlxGraphic;
		if (c == null)
			image = defaultImage;
		else {
			image = Paths.image('ui/icons/' + c) ?? defaultImage;
		}

		loadGraphic(image, true, Std.int(image.width * .5), Std.int(image.height));
		animation.add('icon', [0, 1], 0, false);
		animation.play('icon', true);
		return c;
	}

	public function set_dying(value:Bool):Bool {
		animation.curAnim.curFrame = value ? 1 : 0;
		dying = value;
		return value;
	}
}
