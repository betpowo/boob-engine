import flixel.FlxBasic;

class DefaultOptions extends FlxBasic
{
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
			noteColors = [
				{base: 0xffF9393F, outline: 0xff651038},
				{base: 0xff12FA05, outline: 0xff0A4447},
				{base: 0xff00FFFF, outline: 0xff1542B7},
				{base: 0xffC24B99, outline: 0xff3C1F56}
			];

			return true;
		}
		return false;
	}
}
