package util;

import haxe.PosInfos;
import flixel.FlxBasic;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import hscript.Interp;
import hscript.Parser;

using StringTools;

class HscriptHandler implements IFlxDestroyable {
	public var interpreter:Interp = new Interp();
	public var parser:Parser = new Parser();
	public var file:String = '';
	public var root:String = '';
	public var active:Bool = true;

	public static var _STOP:Int = 0;
	public static var _CONTINUE:Int = 1;

	public function new(file:String, ?root:String = 'data/scripts') {
		parser.line = 1;
		parser.allowJSON = true;
		parser.allowMetadata = true;
		parser.allowTypes = true;

		// haxeflixel shits
		setVariable('Math', Math);
		setVariable('Std', Std);
		setVariable('StringTools', StringTools);

		setVariable('FlxG', flixel.FlxG);
		setVariable('state', flixel.FlxG.state);

		setVariable('FlxGroup', flixel.group.FlxGroup);
		setVariable('FlxSpriteGroup', flixel.group.FlxSpriteGroup);

		// other
		setVariable('import', function(lib:String) {
			var cool:Array<String> = lib.split('.');
			setVariable(cool[cool.length - 1], Type.resolveClass(lib));
		});
		setVariable('keyFromString', function(k:String) {
			return flixel.input.keyboard.FlxKey.fromString(k);
		});

		setVariable('FlxSprite', flixel.FlxSprite);
		setVariable('FlxSpriteExt', flixel.FlxSpriteExt);
		setVariable('FlxText', flixel.text.FlxText);
		setVariable('FlxMath', flixel.math.FlxMath);
		setVariable('FlxTween', flixel.tweens.FlxTween);
		setVariable('FlxEase', flixel.tweens.FlxEase);

		setVariable('Conductor', song.Conductor);
		setVariable('Song', song.Song);

		setVariable('Alphabet', objects.Alphabet);
		setVariable('Character', objects.Character);
		setVariable('Note', objects.Note);
		setVariable('StrumNote', objects.StrumNote);

		setVariable('Paths', util.Paths);
		setVariable('FlxAnimate', flxanimate.FlxAnimate);

		setVariable('Options', util.Options);
		setVariable('Ash', util.Ash);

		setVariable('PlayState', states.PlayState);

		setVariable('add', (obj:FlxBasic) -> {
			FlxG.state.add(obj);
		});
		setVariable('insert', (pos:Int, obj:FlxBasic) -> {
			FlxG.state.insert(pos, obj);
		});
		setVariable('remove', (obj:FlxBasic) -> {
			FlxG.state.remove(obj);
		});

		setVariable('trace', (message:String) -> {
			var color:FlxColor = 0x99cc99;
			var pos:PosInfos = interpreter.posInfos();
			Sys.println('\033[38;2;${color.red};${color.green};${color.blue};1m'
				+ '\033[7m ${root + (root.endsWith('/') ? '' : '/') + file}:${pos.lineNumber} \033[27;21m '
				+ message
				+ '\033[0m');
		});

		#if desktop
		readOrSomething(sys.io.File.getContent(Paths.script(file, root)));
		this.file = file;
		this.root = root;
		#end
	}

	public function setVariable(v:String, n:Any) {
		interpreter.variables.set(v, n);
	}

	public function call(fucktion:String, ?args:Array<Dynamic>):Dynamic {
		if (!interpreter.variables.exists(fucktion) && active)
			return null;

		if (args == null)
			args = [];

		try {
			return Reflect.callMethod(interpreter.variables, interpreter.variables.get(fucktion), args);
		} catch (e) {
			var color:FlxColor = 0xff6666;
			var pos:PosInfos = interpreter.posInfos();
			Sys.println('\033[38;2;${color.red};${color.green};${color.blue};1m'
				+ '\033[7m ${root + (root.endsWith('/') ? '' : '/') + file}:${pos.lineNumber} \033[27;21m '
				+ ~/hscript:([0-9])+:\s/g.replace(e.toString(), '')
				+ '\033[0m');
		}
		return null;
	}

	function readOrSomething(the:String, ?ignoreTrace:Bool = false):Dynamic {
		var awesome:Dynamic = null;
		#if hscript
		try {
			awesome = interpreter.execute(parser.parseString(the));
			return awesome;
		} catch (e:Dynamic) {
			if (!ignoreTrace)
				trace('bruhhh you done fucked up - $e');
			return _CONTINUE;
		}
		#else
		trace('hscript is not supported!!!!!!!!!!');
		#end
	}

	public function destroy() {
		return null;
	}
}
