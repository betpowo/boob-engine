import flash.filters.BitmapFilter;
import flash.filters.BlurFilter;
import flixel.graphics.frames.FlxFilterFrames;
import flixel.input.keyboard.FlxKey;

class StrumNote extends Note
{
	public var strumRGB:RGBPalette = new RGBPalette();

	private var dumpRGB:RGBPalette = new RGBPalette();
	var blurSpr:Note;

	public var inputs:Array<FlxKey> = null;
	public var notes:Array<Note> = [];
	public var autoHit:Bool = false;

	override function set_sustainLength(v:Float):Float
	{
		return sustainLength = 0;
	}

	public function new(?noteData:Int = 2)
	{
		super(noteData);
		shader = strumRGB.shader;
		strumRGB.set(0x87a3ad, -1, 0);
		dumpRGB.set(FlxColor.interpolate(strumRGB.r, rgb.r, 0.3).getDarkened(0.15), -1, 0x201e31);
		blurSpr = new Note(noteData);
		blurSpr.shader = rgb.shader;
		blurSpr.blend = ADD;
		blurSpr.alpha = 0.75;
		blurSpr.visible = false;
		createFilterFrames(blurSpr, new BlurFilter(58, 58));

		animation.addByIndices('confirm', 'idle', [0, 0, 0], '', false);
		animation.addByIndices('press', 'idle', [0, 0, 0], '', false);
		animation.callback = function(a, b, c)
		{
			if (a == 'confirm')
			{
				shader = strumRGB.shader;
				switch (b)
				{
					case 0:
						var mult = 1.15;
						scaleMult.set(mult, mult);
						blurSpr.visible = true;
						blurSpr.alphaMult = 1;
						blurSpr.colorTransform.redOffset = blurSpr.colorTransform.greenOffset = blurSpr.colorTransform.blueOffset = 30;
					case 1:
						blurSpr.colorTransform.redOffset = blurSpr.colorTransform.greenOffset = blurSpr.colorTransform.blueOffset = 0;
					case 2:
						var mult = 1.1;
						blurSpr.alphaMult = 0.75;
						scaleMult.set(mult, mult);
				}
			}
			else if (a == 'press')
			{
				shader = dumpRGB.shader;
				blurSpr.visible = false;
				switch (b)
				{
					case 0:
						var mult = 0.9;
						scaleMult.set(mult, mult);
					case 2:
						var mult = 0.95;
						scaleMult.set(mult, mult);
						blurSpr.alpha = 0.75;
				}
			}
			else
			{
				scaleMult.set(1, 1);
				blurSpr.visible = false;
				shader = strumRGB.shader;
			}
		}
	}

	function createFilterFrames(sprite:FlxSprite, filter:BitmapFilter)
	{
		var filterFrames = FlxFilterFrames.fromFrames(sprite.frames, 64, 64, [filter]);
		updateFilter(sprite, filterFrames);
		return filterFrames;
	}

	function updateFilter(spr:FlxSprite, sprFilter:FlxFilterFrames)
	{
		sprFilter.applyToSprite(spr, false, true);
	}

	override function draw()
	{
		if (visible && alpha != 0)
		{
			super.draw();
			if (blurSpr.visible && blurSpr.alpha != 0)
				blurSpr.draw();
		}
	}

	var confirmTime:Float = 0.0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		blurSpr.setPosition(x, y);
		blurSpr.angle = angle;
		blurSpr.alpha = alpha;
		blurSpr.scale.copyFrom(scale);
		blurSpr.scaleMult.copyFrom(scaleMult);
		dumpRGB.r = FlxColor.interpolate(strumRGB.r, rgb.r, 0.3).getDarkened(0.15);

		if (inputs is Array && inputs != null)
		{
			if (FlxG.keys.anyJustPressed(inputs))
			{
				animation.play('press', true);

				for (note in notes)
				{
					if (note.sustainLength < 100)
					{
						if (Math.abs(note.strumTime - Conductor.time) <= 100 && note.hitAmount == 0)
						{
							animation.play('confirm', true);
							note.hit();
						}
					}
				}
			}
			else if (FlxG.keys.anyPressed(inputs))
			{
				for (note in notes)
				{
					if (note.sustainLength > 100)
					{
						if (Math.abs(note.strumTime - Conductor.time) <= 100 && note.hitAmount < 1)
						{
							animation.play('confirm', true);
							note.hit();
						}
					}
				}
			}

			if (FlxG.keys.anyJustReleased(inputs))
				animation.play('idle', true);
		}
		else
		{
			if (autoHit)
			{
				for (note in notes)
				{
					if (note.strumTime <= Conductor.time && note.hitAmount != 1)
					{
						animation.play('confirm', true);
						confirmTime = 0.123;
						note.hit();
					}
				}
				if (confirmTime > 0)
				{
					confirmTime -= elapsed;
				}
				else
				{
					animation.play('idle', true);
					confirmTime = 0;
				}
			}
		}
	}
}
