import flixel.FlxBasic;
import flixel.input.keyboard.FlxKey;

class DefaultOptions extends FlxBasic
{
	public var keys = [[LEFT, A], [DOWN, S], [UP, W], [RIGHT, D]];
	public var noteColors = [
		{base: 0xffC24B99, outline: 0xff3C1F56},
		{base: 0xff00FFFF, outline: 0xff1542B7},
		{base: 0xff12FA05, outline: 0xff0A4447},
		{base: 0xffF9393F, outline: 0xff651038}
	];
}

class Options extends DefaultOptions
{
	public static var instance:Options;

	public function new()
	{
		super();
		if (instance == null)
			instance = this;
	}

	public function _load():Bool
	{
		// will be made later
		if (true)
		{
			return true;
		}
		return false;
	}
}
