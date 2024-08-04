package;

import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();

		var opts = new Options();
		opts._load();
		// trace(Reflect.fields(opts));

		FlxG.signals.preStateSwitch.add(() ->
		{
			Conductor.beatHit.removeAll();
			Conductor.stepHit.removeAll();
			Conductor.paused = true;
			Conductor.time = 0;
		});

		addChild(new FlxGame(0, 0, PlayState, 175, 175));
		addChild(new openfl.display.FPS(5, 5, -1));
	}
}
