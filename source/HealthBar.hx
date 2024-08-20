import flixel.system.FlxAssets.FlxShader;

// is this useful ????

class HealthBar extends FlxSprite
{
	public var bshad = new HealthBarShader();

	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		loadGraphic(Paths.image('ui/bar'));
		antialiasing = true;
		moves = false;

		shader = bshad.shader;
	}

	public var empty(default, set):FlxColor;
	public var fill(default, set):FlxColor;
	public var value(default, set):Float;
	public var rightToLeft(default, set):Bool;

	private function set_empty(color:FlxColor)
	{
		bshad.empty = color;
		return color;
	}

	private function set_fill(color:FlxColor)
	{
		bshad.fill = color;
		return color;
	}

	private function set_value(f:Float)
	{
		f = FlxMath.bound(f, 0, 1);
		bshad.value = f;
		return f;
	}

	private function set_rightToLeft(b:Bool)
	{
		bshad.rightToLeft = b;
		return b;
	}

	public function set(?_empty:FlxColor, ?_fill:FlxColor)
	{
		bshad.set(_empty, _fill);
	}
}

class HealthBarShader
{
	public var shader(default, null):HealthBarShaderShader = new HealthBarShaderShader();
	public var empty(default, set):FlxColor;
	public var fill(default, set):FlxColor;
	public var value(default, set):Float;
	public var rightToLeft(default, set):Bool;

	public function set(?_empty:FlxColor, ?_fill:FlxColor)
	{
		if (_empty == null)
			_empty = 0xff0000;
		if (_fill == null)
			_fill = 0x66ff33;

		empty = _empty;
		fill = _fill;
	};

	private function set_empty(color:FlxColor)
	{
		empty = color;
		shader.empty.value = [color.redFloat, color.greenFloat, color.blueFloat];
		return color;
	}

	private function set_fill(color:FlxColor)
	{
		fill = color;
		shader.fill.value = [color.redFloat, color.greenFloat, color.blueFloat];
		return color;
	}

	private function set_value(f:Float)
	{
		f = FlxMath.bound(f, 0, 1);
		value = f;
		shader.value.value = [f];
		return f;
	}

	private function set_rightToLeft(b:Bool)
	{
		rightToLeft = b;
		shader.rtl.value = [b];
		return b;
	}

	public function new()
	{
		set(0xFFFF0000, 0xFF66FF33);
		value = 0.5;
		rightToLeft = false;
	}
}

class HealthBarShaderShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header

        uniform vec3 empty;
        uniform vec3 fill;
        uniform float value;
        uniform bool rtl;

		void main() {
			vec4 dump = flixel_texture2D(bitmap, openfl_TextureCoordv);
            if (rtl) {
                dump.rgb *= (openfl_TextureCoordv.x >= (1 - value)) ? fill.xyz : empty.xyz;
            } else {
                dump.rgb *= (openfl_TextureCoordv.x >= value) ? fill.xyz : empty.xyz;
            }
            gl_FragColor = dump;
		}
    ')
	public function new()
	{
		super();
	}
}
