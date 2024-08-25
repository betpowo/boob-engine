package;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

class OptionsState extends FlxState
{
	override public function create()
	{
		super.create();

		var bg = new FlxBackdrop(FlxGridOverlay.createGrid(1, 1, 2, 2, true, -1, 0));
		bg.scale.set(30, 30);
		bg.velocity.set(20, -20);
		bg.alpha = 0.1;
		add(bg);

		var a = new Alphabet();
		a.text = 'idk anymore idk what\nto make this menu';
		a.x = a.y = 50;
		add(a);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.switchState(new TitleState());
		}
	}
}
