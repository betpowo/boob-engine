class Conductor
{
	private static var last_time:Float = 0;

	public static var time(default, set):Float = 0;

	public static function set_time(v:Float):Float
	{
		last_time = time;
		time = v;
		return v;
	}

	/**
	 * ms difference from last time to current time
	 */
	public static var delta(get, never):Float;

	public static function get_delta():Float
	{
		return time - last_time;
	}
}
