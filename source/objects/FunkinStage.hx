// this is not an object (yet), but is only hre for the sake of organizing
package objects;

import states.PlayState;
import tools.Ini.IniData;
import tools.Ini;
import util.HscriptHandler;

// idk how im gonna handle stages tbh but heres this for now lol
class FunkinStage {
	public static var script:HscriptHandler;
	public static var ini:IniData;
	public static var zoom:Float = 1;

	public static var positions:Map<String, Array<Float>> = ['opp' => [335, 885], 'spc' => [751, 787], 'plr' => [989, 885]];
	public static var camOffsets:Map<String, Array<Float>> = ['opp' => [150, 100], 'plr' => [-100, -100]];
	public static var flipPos:Array<String> = ['plr'];

	public static function init(stage:String = 'stage') {
		var iniPath = Paths.ini('data/stages/$stage');
		if (Paths.exists(iniPath)) {
			ini = Ini.parseFile(iniPath);
			initIni(ini);
		}

		if (Paths.exists('data/stages/' + stage + '.hx')) {
			script = new HscriptHandler(stage, 'data/stages');
			script.setVariable('this', PlayState.instance ?? FlxG.state);
			script.setVariable('inGame', FlxG.state is PlayState);
			script?.call('init');
		}
	}

	static function initIni(ini:IniData) {
		flipPos = (ini.global.flip : String).split(',') ?? ['plr'];
		if (ini.exists('pos')) {
			var pos:Map<String, String> = cast ini.get('pos');
			for (k => v in pos) {
				positions.set(k, (v : String).split(',').map((a) -> {
					return Std.parseFloat(a);
				}));
			}
		}
		if (ini.exists('camoff')) {
			var off:Map<String, String> = cast ini.get('camoff');
			for (k => v in off) {
				camOffsets.set(k, (v : String).split(',').map((a) -> {
					return Std.parseFloat(a);
				}));
			}
		}
		zoom = ini.global.zoom ?? 1;
	}

	public static function call(func:String, ?args:Array<Dynamic>) {
		script?.call(func, args);
	}
}
