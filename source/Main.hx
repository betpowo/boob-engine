package;

// adding psych crash handler stuff for a moment while i debug things
import flixel.FlxGame;
import haxe.CallStack;
import haxe.PosInfos;
import haxe.io.Path;
import lime.app.Application;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.UncaughtErrorEvent;
import openfl.utils.Function;

using StringTools;

class Main extends Sprite
{
	public function new()
	{
		super();

		Log.init();
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

		Log.anonprint('');
		Log.anonprint('                 why are you using boob engine');
		Log.anonprint('');
		for (i in [
			'@@@@@@@@@@@@@@@@@@@@@@@@@@####@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@####@@@@@@@@@',
			'@@@@@@@@@@@@@@@@@@@@@@@@@@#####@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@####@@@@@@@@@',
			'@@@@@@@@@@@@@@@@@@@@@@@@@@#####@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#####@@@@@@@@@',
			'@@@@@@@@@@@@@@@@@@@@@@@@@@#####@@@@@@@@@@@@@@@@@@@@@@@@@@@@#######@@@@@@@@@',
			'@@@@@@@@@@@@@@@@@@@@@@@@@@#####@@@@######@@@@@@@@@@@@@@@@#########@@@@@@@@@',
			'@@@@@@@@@@@@@@@@@@@@@@@@@####@@@@@@@@@@##########################@@@@@@@@@@',
			'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@####################@@@@@@@@@@@',
			'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@################@@@@@@@@@@@@@',
			'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#############@@@@@@@@@@@@@@@@',
			'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#########@@@@@@@@@@@@@@@@@@@@@@',
			'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#############@@@@@@@@@@@@@@@@@@@@@',
			'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#############S#@###@@@@@@@@@@@@@@@@@@@@@@',
			'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#########@@#;,.,#S@@@@@@@@@@@@@@@@@@@@@@@@',
			'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@######%?@#,..;#*%##@@@@@@@@@@@@@@@@@@@@@',
			'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+,,+++*%S?+;;*@@@@@@@@@@@@@@@@@@@@@',
			'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%SSSSSS%?*++*+;;@@@@@@@@@@@@@@@@@@@@@',
			'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?++++++++*%SSS?+%@@@@@@@@@@@@@@@@@@@@@',
			'@@@@@@@@@@@@@@@@@@@##@@@@@@@@@@@@@@@@?+++;+*%S%?*++*S@@@@@@@@@@@@@@@@@@@@@@',
			'######################@@@@@@@@@@@@@@#*??%%S%?+++*%S@@@#####################',
			'#######################@@@@@@@@@@@@@@S%%?*+++*%#@@@@#######################',
			'########################@@@@@@@@@@@@#++++*?S#@@@##@@@@#####################',
			'######################@@@@@@@@@@@@@@@SS##@@@@@######@@@@###################',
			'#####################@@@@@@@@@@@@@@@@@@@@@@@@#########@@@##################',
			'####################@@@@@@@@@@@@@@@@@@@@@@@@@###########@@#################',
			'###################@@@@@@@@@@@@@@@@@@@@@@@@@@@##########@@#################',
			'##################@@@@@@@@@@@@@@@@@@@@@@@@@@@@######@@###@@################',
			'#################@@@@@@@@@@@@@@@@@@@@@@@@@@@@@######@@@##@@################',
			'################@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@######@@@###@@###############',
			'################@@@@@@@@@@@@@@@@@@@@@@@@@@@@@######@@@@###@@###############',
			'################@@@@@@@#@@@@@@@@@@@@@@@@@@@@######@@@@@####@@##############',
			'###############@@@@@@@@##@@@@@@@@@@@@@@@@@@@@#####@@##@@###@@##############'
		])
		{
			Log.anonprint('\033[7m' + i + '\033[0m', 0xcc6666);
		}
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

class Log
{
	static var ogTrace:Function;

	public static function init()
	{
		ogTrace = haxe.Log.trace;
		haxe.Log.trace = haxeTrace;
	}

	public static function haxeTrace(v:Dynamic, ?pos:PosInfos)
	{
		print(v, null, pos);
	}

	public static function print(message:Dynamic, ?color:FlxColor = 0xd2d2d2, ?pos:PosInfos)
	{
		Sys.println('\033[38;2;${color.red};${color.green};${color.blue}m'
			+ '\033[7m ${pos.className}:${pos.lineNumber} \033[27m '
			+ message
			+ '\033[0m');
	}

	public static function anonprint(message:Dynamic, ?color:FlxColor = 0xd2d2d2, ?pos:PosInfos)
	{
		Sys.println('\033[38;2;${color.red};${color.green};${color.blue}m' + message + '\033[0m');
	}

	public static function add(message:Dynamic, ?color:FlxColor = 0xd2d2d2)
	{
		Sys.print('\033[38;2;${color.red};${color.green};${color.blue}m' + message + '\033[0m');
	}
}
