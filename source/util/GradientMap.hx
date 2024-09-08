package util;

import flixel.system.FlxAssets.FlxShader;

class GradientMap {
	public var shader(default, null):GradientMapShader = new GradientMapShader();
	public var black(default, set):FlxColor;
	public var white(default, set):FlxColor;
	public var mult(default, set):Float;

	public function set(?_w:FlxColor = 0xffffffff, ?_b:FlxColor = 0xff000000) {
		white = _w;
		black = _b;
	};

	public function copy(target:GradientMap) {
		set(target.white, target.black);
	}

	private function set_white(color:FlxColor) {
		if (color == color.to24Bit() && color != FlxColor.TRANSPARENT)
			color.alphaFloat = 1;

		white = color;
		shader.white.value = [color.redFloat, color.greenFloat, color.blueFloat, color.alphaFloat];
		return color;
	}

	private function set_black(color:FlxColor) {
		if (color == color.to24Bit() && color != FlxColor.TRANSPARENT)
			color.alphaFloat = 1;

		black = color;
		shader.black.value = [color.redFloat, color.greenFloat, color.blueFloat, color.alphaFloat];
		return color;
	}

	private function set_mult(value:Float) {
		mult = FlxMath.bound(value, 0, 1);
		shader.mult.value = [mult];
		return mult;
	}

	public function new() {
		set(-1, 0);
		mult = 1.0;
	}
}

class GradientMapShader extends FlxShader {
	@:glFragmentHeader('
		#pragma header
		
		uniform vec4 black;
        uniform vec4 white;
		uniform float mult;

		vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) {
			vec4 color = flixel_texture2D(bitmap, coord);
			if (!hasTransform || color.a == 0.0 || mult == 0.0) {
				return color;
			}

			vec4 newColor = color;
            newColor.rgb = vec3((color.r + color.g + color.b) / 3.0);
            newColor = mix(black, white, vec4(newColor.g));
            newColor *= newColor.a * color.a;
			
			color = mix(color, newColor, mult);
			
			if(color.a > 0.0) {
				return vec4(color.rgb, color.a);
			}
			return vec4(0.0, 0.0, 0.0, 0.0);
		}')
	@:glFragmentSource('
		#pragma header

		void main() {
			gl_FragColor = flixel_texture2DCustom(bitmap, openfl_TextureCoordv);
		}')
	public function new() {
		super();
	}
}
