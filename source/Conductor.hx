import flixel.FlxBasic;
import flixel.util.FlxSignal;

class Conductor extends FlxBasic
{
	private static var last_time:Float = 0;

	public static var time(default, set):Float = 0;
	public static var bpm:Float = 60;
	public static var rate:Float = 1;

	public static var crochet(get, never):Float;
	public static var crochetSec(get, never):Float;

	public static var beatFl(get, never):Float;
	public static var beat(get, never):Int;

	public static var stepFl(get, never):Float;
	public static var step(get, never):Int;

	public static var instance:Conductor;

	public function new()
	{
		super();
		instance = this;
	}

	public static function set_time(v:Float):Float
	{
		last_time = time;
		time = v;
		return v;
	}

	public static function get_crochet():Float
	{
		return crochetSec * 1000;
	}

	public static function get_crochetSec():Float
	{
		return 60 / bpm;
	}

	public static function get_beatFl():Float
	{
		return time / crochet;
	}

	public static function get_stepFl():Float
	{
		return beatFl * 4;
	}

	public static function get_beat():Int
	{
		return Math.floor(beatFl);
	}

	public static function get_step():Int
	{
		return Math.floor(stepFl);
	}

	/**
	 * ms difference from last time to current time
	 */
	public static var delta(get, never):Float;

	public static function get_delta():Float
	{
		return time - last_time;
	}

	public static var paused:Bool = true;
	static var last = {
		beat: -1,
		step: -1
	}

	public static var beatHit:FlxSignal = new FlxSignal();
	public static var stepHit:FlxSignal = new FlxSignal();
	public static var tracker(get, default):FlxSound;

	public static function get_tracker():FlxSound
	{
		if (tracker != null)
			return tracker;
		return FlxG.sound.music;
	}

	public static var threshold:Float = 20;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!paused)
		{
			time += elapsed * (1000 * rate);
			if (tracker.playing)
			{
				if (Math.abs(time - tracker.time) > threshold)
					time = tracker.time;
			}
			if (last.step != step)
			{
				last.step = step;
				stepHit.dispatch();
			}
			if (last.beat != beat)
			{
				last.beat = beat;
				beatHit.dispatch();
			}
		}
	}
}
