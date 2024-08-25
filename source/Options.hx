import flixel.FlxBasic;
import flixel.input.keyboard.FlxKey;

@:structInit
class DefaultOptions
{
	public var keys = [[LEFT, A], [DOWN, S], [UP, W], [RIGHT, D]];
	public var noteColors = [
		{base: 0xffC24B99, outline: 0xff3C1F56},
		{base: 0xff00FFFF, outline: 0xff1542B7},
		{base: 0xff12FA05, outline: 0xff0A4447},
		{base: 0xffF9393F, outline: 0xff651038}
	];
}

class Options
{
	public static final _default:DefaultOptions = {};
	public static var data:DefaultOptions = _default;

	public static function load():Bool
	{
		// will be made later
		/*data.noteColors = [
				{base: 0, outline: -1},
				{base: 0, outline: -1},
				{base: 0, outline: -1},
				{base: 0, outline: -1}
			]; */

		return true;
	}
}
