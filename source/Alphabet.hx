import flixel.FlxCamera;
import flixel.util.FlxAxes;
import flixel.util.FlxStringUtil;

using StringTools;

class Alphabet extends FlxSprite
{
	public var text(default, set):String = 'Alphabet';

	public function set_text(v:String):String
	{
		if (text != v)
		{
			text = v;
			schedule();
		}
		return v;
	}

	function schedule()
	{
		displit = text.split('');
	}

	public var separator:Float = 4;
	public var rgb = new RGBPalette();

	var displit:Array<String> = [];
	var script:HscriptHandler;

	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		if (script == null)
			script = new HscriptHandler('alphabet', 'images/ui');

		frames = Paths.sparrow('ui/alphabet');
		animation.addByPrefix('idle', ':FALLBACK', 0, true);
		animation.play('idle', true);
		updateHitbox();

		for (fr in frames.frames)
		{
			var frameName = fr.name.replace('0000', '');
			var the = script.callThingy('doFilter', [frameName]); // why is it an array ?????
			animation.addByPrefix(the, frameName, 0, true);
		}

		antialiasing = true;
		moves = false;

		shader = rgb.shader;
		rgb.set(0xff0000, -1, 0);

		schedule();
	}

	var rows:Int = 0;
	var lineHeight:Float = 75;
	var _defaultDrawData:AlphabetDrawData = {
		x: 0.0,
		y: 0.0,
		angle: 0.0,
		flip: 'none'
	};

	override public function draw()
	{
		rows = 0;
		var ogx = x;
		var ogy = y;
		var ogh = height;
		var spli = displit;
		// script.callThingy('drawOnce', []);
		for (waaa in spli)
		{
			switch (waaa)
			{
				case ' ':
					x += (30 + separator) * scale.x;
					y = ogy;
					y += lineHeight * rows * scale.y;
				case '\n':
					x = ogx;
					rows += 1;
				default:
					var _drawData:AlphabetDrawData = getDrawData(waaa);

					var anim = _drawData.char ?? waaa;

					animation.play(anim, true);
					if (!animation.exists(anim))
						animation.play('idle', true); // fallback char

					updateHitbox();
					y = ogy + ogh - height;
					y += lineHeight * rows * scale.y;

					if (_drawData != null)
					{
						var ogfx = flipX;
						var ogfy = flipY;

						x += _drawData.x * scale.x;
						y += _drawData.y * scale.y;
						angle += _drawData.angle;

						if (_drawData.flip != null)
						{
							var axes = FlxAxes.fromString(_drawData.flip);
							if (axes.x)
								flipX = !flipX;
							if (axes.y)
								flipY = !flipY;
						}

						super.draw();
						if (_drawData.extra != null)
						{
							animation.play(_drawData.extra.char, true);

							x += _drawData.extra.x * scale.x;
							y += _drawData.extra.y * scale.y;
							angle += _drawData.extra.angle;
							if (_drawData.extra.flip != null)
							{
								var axes = FlxAxes.fromString(_drawData.extra.flip);
								if (axes.x)
									flipX = !flipX;
								if (axes.y)
									flipY = !flipY;
							}
							super.draw();
							x -= _drawData.extra.x * scale.x;
							y -= _drawData.extra.y * scale.y;
							angle -= _drawData.extra.angle;

							animation.play(anim, true);
							if (!animation.exists(anim))
								animation.play('idle', true); // fallback char

							updateHitbox();
						}

						x -= _drawData.x;
						y -= _drawData.y;
						angle -= _drawData.angle;

						flipX = ogfx;
						flipY = ogfy;
					}
					else
					{
						super.draw();
					}
					x += (frameWidth + separator) * scale.x;
					y = ogy;
			}
		}
		x = ogx;
		y = ogy;
		height = ogh;
	}

	private var _drawfunc:String->AlphabetDrawData = null;

	inline function getDrawData(input:String)
	{
		if (_drawfunc == null && script.interpreter.variables.exists('onDraw'))
			_drawfunc = script.interpreter.variables.get('onDraw');

		return _drawfunc(input) ?? _defaultDrawData;
	}
}

typedef AlphabetDrawData = AlphabetExtraDrawData &
{
	?extra:AlphabetExtraDrawData
}

// WHY
typedef AlphabetExtraDrawData =
{
	x:Float,
	y:Float,
	angle:Float,
	flip:String,
	?char:String
}
