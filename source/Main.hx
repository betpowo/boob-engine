package;

// adding psych crash handler stuff for a moment while i debug things
import flixel.FlxGame;
import haxe.CallStack;
import haxe.io.Path;
import lime.app.Application;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.UncaughtErrorEvent;

using StringTools;

class Main extends Sprite
{
	public function new()
	{
		super();

		var opts = new Options();
		opts._load();
		// trace(Reflect.fields(opts));

		addChild(new FlxGame(0, 0, TitleState, 175, 175));
		addChild(new openfl.display.FPS(5, 5, -1));

		FlxG.plugins.addPlugin(new Conductor());
		FlxG.signals.preStateSwitch.add(() ->
		{
			Conductor.beatHit.removeAll();
			Conductor.stepHit.removeAll();
			Conductor.paused = true;
			Conductor.time = 0;
		});

		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
	}

	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (" + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: " + e.error + "\n\n> Crash Handler written by: sqirra-rng";

		Application.current.window.alert(errMsg, "Error!");
		Sys.exit(1);
	}
}
