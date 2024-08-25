import flixel.math.FlxRect;

// is this useful ????
class HealthBar extends FlxSprite
{
	public var emptySprite:FlxSprite;
	public var empty:FlxColor;
	public var fill:FlxColor;
	public var percent(default, set):Float;
	public var rightToLeft:Bool;

	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		loadGraphic(Paths.image('ui/bar'));
		updateHitbox();

		clipRect = new FlxRect(0, 0, width, height);
		antialiasing = true;
		moves = false;

		emptySprite = new FlxSprite().loadGraphic(Paths.image('ui/bar'));
		emptySprite.updateHitbox();

		setColors(0xff0000, 0x66ff33);
	}

	override public function draw()
	{
		//             ...                      ..        .
		//
		//
		//
		//                  .:-===+====-:..
		//               .:=+***######*****++=:. .   ......
		//          .::.-+*****##%#############*-.. . .....
		//        ..=++++++**********++***##*###*+:.      .
		//        .=+++*##*++++***+**#####%%*+##*+=-..    .
		//        :+*%@@@@@@*++****%@@@@@%%%#%%@%*+-. .....
		//       .=+%@@#%@@@#*****#%#@@@@@@%%###%#+-.  ....
		//       .-+*@@@@@%#***####%@@@@@@%%%%*+**=:.  ...
		//      .:=++**##*####%%%%####%%%%%%%*++++=-......
		//     ..:=+++*****###%@@%##*###%%%###+==++=-:.....
		//     ..:==++====+++*####*****#%%%##*+==**+=:.....
		//      ..:======---=**##%*****#####*+++**+=-:.....
		//       ...:-------==+***+++++++++++++**+=-:......
		// ...    ....:--================++++****+-:.......
		//   ... ......:=+#%%%#***####*++++*####*+-:.......
		//  ...........:-=*##%%%%%%%%%%#%#######*+-::......
		// .   .. ......:-=+*#######%%%%%%%####**=-:...  ..
		// .  ...........::-=+*######%########*+=-::...  ..
		//   .....  .. ....::-=+*###########**+=-::........
		// ........ .   .....::-=++**#####**++=-:::........

		emptySprite.camera = camera;
		emptySprite.setPosition(x, y);
		emptySprite.scale.copyFrom(scale);
		emptySprite.angle = angle;
		emptySprite.alpha = alpha;
		emptySprite.color = empty;
		emptySprite.antialiasing = antialiasing;
		if (emptySprite.visible)
			emptySprite.draw();

		color = fill;

		// bro
		clipRect.set((rightToLeft ? frameWidth : 0) * (1 - percent), 0, frameWidth * percent, frameHeight);
		clipRect = clipRect;
		super.draw();
	}

	private function set_percent(f:Float):Float
	{
		f = FlxMath.bound(f, 0, 1);
		percent = f;
		return f;
	}

	// useless
	public function setColors(?_empty:FlxColor = 0xff0000, ?_fill:FlxColor = 0x66ff33)
	{
		empty = _empty;
		fill = _fill;
	}
}
