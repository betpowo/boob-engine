package objects.ui;

import flixel.FlxSpriteExt;
import flixel.graphics.FlxGraphic;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSignal;
import util.GradientMap;

class ImageButton extends FlxSpriteExt
{
	public var gradient:GradientMap = new GradientMap();
	public var sprite:FlxSpriteExt;
	public var inputs:Array<FlxKey> = null;

	public var colors:Array<FlxColor> = [0xcccccc, 0x333333];
	public var hoverColors:Array<FlxColor> = [0xffffff, 0x777777];
	public var pressColors:Array<FlxColor> = [0x333333, 0xcccccc];

	public function new(?img:FlxGraphic)
	{
		super();
		shader = gradient.shader;

		loadGraphic(Paths.image('ui/editor/_image_button'));
		updateHitbox();

		sprite = new FlxSpriteExt();
		sprite.loadGraphic(img);
		sprite.updateHitbox();

		gradient.set(0xcccccc, 0x333333);
	}

	override function draw()
	{
		sprite.camera = camera;
		sprite.shader = shader;

		if (visible && alpha > 0)
		{
			super.draw();
			if (sprite.visible && sprite.alpha >= 0)
			{
				sprite.x = getMidpoint().x - sprite.width * 0.5;
				sprite.y = getMidpoint().y - sprite.height * 0.5;
				sprite.draw();
			}
		}
	}

	public function quickColor(col:FlxColor = 0xcccccc, out:FlxColor = 0x333333)
	{
		colors = [col, out];
		hoverColors = [col.getLightened(0.3), out.getLightened(0.15)];
		pressColors = [out, col];
	}

	public var onPress:FlxSignal = new FlxSignal();

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		sprite.angle = angle;
		sprite.alpha = alpha;
		sprite.scale.copyFrom(scale);
		sprite.updateHitbox();
		sprite.scaleMult.copyFrom(scaleMult);
		sprite.update(elapsed);

		var cols:Array<FlxColor> = colors;
		if (FlxG.mouse.overlaps(this, camera))
		{
			cols = hoverColors;

			if (FlxG.mouse.pressed)
				cols = pressColors;

			if (FlxG.mouse.justReleased)
			{
				onPress.dispatch();
			}
		}
		else if (inputs != null)
		{
			if (FlxG.keys.anyPressed(inputs))
			{
				cols = pressColors;
			}
			else if (FlxG.keys.anyJustReleased(inputs))
			{
				cols = colors;
				onPress.dispatch();
			}
		}

		gradient.set(cols[0], cols[1]);
	}
}
