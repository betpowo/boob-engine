package objects;

import states.PlayState;
import util.HscriptHandler;

// idk how im gonna handle stages tbh but heres this for now lol
class FunkinStage {
	public static var script:HscriptHandler;

	public static function init(stage:String = 'stage') {
		if (Paths.exists('data/stages/' + stage + '.hx')) {
			script = new HscriptHandler(stage, 'data/stages');
			script.setVariable('this', PlayState.instance ?? FlxG.state);
			script.setVariable('inGame', FlxG.state is PlayState);
			script?.call('init');
		}
	}

	public static function call(func:String, ?args:Array<Dynamic>) {
		script?.call(func, args);
	}
}
