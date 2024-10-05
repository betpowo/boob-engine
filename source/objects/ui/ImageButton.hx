package objects.ui;

import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroupedSprite;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSignal;
import util.CoolUtil;
import util.GradientMap;

class ImageButton extends FlxGroupedSprite {
	public var gradient:GradientMap = new GradientMap();
	public var sprite:FlxSprite;
	public var button:FlxUI9SliceSprite;
	public var inputs:Array<FlxKey> = null;

	public var colors:Array<FlxColor> = [0xcccccc, 0x333333];
	public var hoverColors:Array<FlxColor> = [0xffffff, 0x777777];
	public var pressColors:Array<FlxColor> = [0x333333, 0xcccccc];

	public function new(?img:FlxGraphic) {
		super();

		button = CoolUtil.make9Slice('ui/editor/image_button', [25, 25, 75, 75], 100, 100);
		add(button);

		sprite = new FlxSprite();
		sprite.loadGraphic(img);
		sprite.updateHitbox();
		add(sprite);

		sprite.x = (button.width - sprite.width) * .5;
		sprite.y = (button.height - sprite.height) * .5;

		button.shader = sprite.shader = gradient.shader;
		button.camera = sprite.camera = camera;
		gradient.set(0xcccccc, 0x333333);
	}

	public function quickColor(col:FlxColor = 0xcccccc, out:FlxColor = 0x333333) {
		colors = [col, out];
		hoverColors = [col.getLightened(0.3), out.getLightened(0.15)];
		pressColors = [out, col];
	}

	public var onPress:FlxSignal = new FlxSignal();

	override function update(elapsed:Float) {
		super.update(elapsed);

		var cols:Array<FlxColor> = colors;
		if (FlxG.mouse.overlaps(this, camera)) {
			cols = hoverColors;

			if (FlxG.mouse.pressed)
				cols = pressColors;

			if (FlxG.mouse.justReleased) {
				onPress.dispatch();
			}
		} else if (inputs != null) {
			if (FlxG.keys.anyPressed(inputs)) {
				cols = pressColors;
			} else if (FlxG.keys.anyJustReleased(inputs)) {
				cols = colors;
				onPress.dispatch();
			}
		}

		gradient.set(cols[0], cols[1]);
	}
}
