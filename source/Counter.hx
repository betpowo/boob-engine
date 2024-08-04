import flixel.util.FlxStringUtil;

class Counter extends FlxSprite
{
	public var number:Float = 0;
	public var separator:Float = 4;
	public var alignment:FlxTextAlign = LEFT;
	public var display:CounterDisplay = INT;

	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		loadGraphic('assets/num.png');
		loadGraphic('assets/num.png', true, Std.int(width / 7), Std.int(height / 2));
		animation.add('num', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13], 0, true);
		animation.play('num', true);
		updateHitbox();

		antialiasing = true;
		moves = false;
	}

	override public function draw()
	{
		var ogx = x;
		var spli = getDisplay(number).split('');
		if (alignment == RIGHT)
		{
			x -= (frameWidth + separator) * scale.x * spli.length;
			x += separator;
		}
		else if (alignment == CENTER)
		{
			x -= ((frameWidth + separator) * scale.x * spli.length) * 0.5;
			x += separator * 2;
		}
		for (waaa in spli)
		{
			var num = 0;
			switch (waaa)
			{
				case '-':
					num = 10;
				case '.':
					num = 11;
				case ':':
					num = 12;
				case '?':
					num = 13;
				default:
					num = Std.parseInt(waaa);
			}
			animation.play('num', true, false, num);
			super.draw();
			x += (frameWidth + separator) * scale.x;
		}
		x = ogx;
	}

	function getDisplay(num:Float):String
	{
		return switch (display)
		{
			case QUESTION:
				[for (i in 0...Std.int(Math.max(num, 1))) '?'].join('');
			case TIME | TIME_MS:
				FlxStringUtil.formatTime(num, display == TIME_MS);
			case INT:
				Std.string(Math.floor(num));
			default:
				Std.string(num);
		}
	}
}

enum CounterDisplay
{
	INT;
	FLOAT;
	TIME;
	TIME_MS;
	QUESTION;
}
