class ComboCounter extends FlxSprite
{
	public var number:Float = 0;
	public var separator:Float = 4;
	public var rightToLeft:Bool = false;

	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		loadGraphic('assets/num.png');
		loadGraphic('assets/num.png', true, Std.int(width / 6), Std.int(height / 2));
		animation.add('num', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], 0, true);
		animation.play('num', true);
		updateHitbox();

		antialiasing = true;
		moves = false;
	}

	override public function draw()
	{
		var ogx = x;
		var spli = Std.string(number).split('');
		if (rightToLeft)
		{
			x -= (frameWidth + separator) * scale.x * spli.length;
			x += separator;
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
				default:
					num = Std.parseInt(waaa);
			}
			animation.play('num', true, false, num);
			super.draw();
			x += (frameWidth + separator) * scale.x;
		}
		x = ogx;
	}
}
