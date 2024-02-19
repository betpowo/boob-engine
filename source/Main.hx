package;

import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, PlayState, 175, 175));
		addChild(new openfl.display.FPS(5, 5, -1));
	}
}
