package;

import hscript.Interp;
import hscript.Parser;

using StringTools;

class HscriptHandler
{
	var interpreter:Interp = new Interp();
	var parser:Parser = new Parser();
	var file:String = '';

	public static var _STOP:Int = 0;
	public static var _CONTINUE:Int = 1;

	public function new(file:String, ?root:String = 'data/scripts')
	{
		parser.line = 1;
		parser.allowJSON = true;
		parser.allowMetadata = true;
		parser.allowTypes = true;

		// haxeflixel shits
		setVariable('Math', Math);
		setVariable('Std', Std);
		setVariable('StringTools', StringTools);

		setVariable('FlxG', flixel.FlxG);
		// other
		setVariable('import', function(lib:String)
		{
			var cool:Array<String> = lib.split('.');
			setVariable(cool[cool.length - 1], Type.resolveClass(lib));
		});
		setVariable('keyFromString', function(k:String)
		{
			return flixel.input.keyboard.FlxKey.fromString(k);
		});

		#if desktop
		readOrSomething(sys.io.File.getContent(Paths.script(file, root)));
		this.file = file;
		#end
	}

	public function setVariable(v:String, n:Any)
	{
		interpreter.variables.set(v, n);
	}

	public function callThingy(fucktion:String, ?args:Array<Dynamic>):Dynamic
	{
		if (!interpreter.variables.exists(fucktion))
			return null;

		if (args == null)
			args = [];

		return Reflect.callMethod(interpreter.variables, interpreter.variables.get(fucktion), args);
	}

	function readOrSomething(the:String, ?ignoreTrace:Bool = false):Dynamic
	{
		var awesome:Dynamic = null;
		#if hscript
		try
		{
			awesome = interpreter.execute(parser.parseString(the));
			return awesome;
		}
		catch (e:Dynamic)
		{
			if (!ignoreTrace)
				trace('bruhhh you done fucked up - $e');
			return _CONTINUE;
		}
		#else
		trace('bruh tf are you doing hsript isnt supported!!!!!!!!!!');
		#end
	}
}
