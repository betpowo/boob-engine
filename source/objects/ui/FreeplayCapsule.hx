package objects.ui;

import flixel.FlxSpriteExt;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import flxanimate.FlxAnimate;
import util.GradientMap;

class FreeplayCapsule extends FlxSpriteGroup {
	public var text(default, set):String = '';
	public var icon:FlxSpriteExt;

	// public var color(default, set):FlxColor = 0xaadeff;
	var frontGlow:FlxAnimate;
	var backGlow:FlxAnimate;
	var textObj:FlxText;
	var maxWidth:Float = 373;
	var _gradient:GradientMap;

	public function set_text(v:String):String {
		if (textObj != null && textObj.text != v)
			textObj.text = v;
		text = v;
		return v;
	}

	override public function set_color(c:FlxColor):FlxColor {
		if (backGlow != null)
			backGlow.color = c;
		_gradient.black = c;
		color = c;
		return c;
	}

	public function new() {
		super();

		backGlow = bro('lcd screen backing', 43, 12);

		textObj = new FlxText();
		textObj.font = Paths.font('5by7.ttf');
		textObj.size = 40;
		textObj.antialiasing = true;
		textObj.borderStyle = FlxTextBorderStyle.OUTLINE;
		textObj.borderColor = 0x55000000;
		textObj.borderSize = 2;
		textObj.setPosition(65, 28);

		add(textObj);

		bro('mp3 capsule');

		frontGlow = bro('capsule glow');

		_gradient = new GradientMap();
		frontGlow.shader = textObj.shader = _gradient.shader;
		frontGlow.color = 0xff000000;

		frontGlow.blend = ADD;

		textObj.clipRect = new FlxRect(0, 0, maxWidth, textObj.height);

		text = '???';
		color = 0xaadeff;
	}

	function bro(sym:String, x:Float = 0, y:Float = 0):FlxAnimate {
		var capsule = new FlxAnimate();
		capsule.loadAtlas(Paths.file('images/menus/freeplay/capsule'));
		capsule.anim.addBySymbol('idle', sym, 24, true, x, y);
		capsule.anim.play('idle', true);
		capsule.antialiasing = true;

		capsule.width = 545;
		capsule.height = 117;

		add(capsule);
		return capsule;
	}

	var el:Float = 0;

	override function update(elapsed:Float) {
		super.update(elapsed);

		el += elapsed;
		textObj.borderSize = FlxMath.lerp(1.5, 2.5, (FlxMath.fastSin(el * 50) + 1) * 0.5);
		textObj.clipRect.width = maxWidth;
		textObj.clipRect.height = textObj.height;
		textObj.clipRect = textObj.clipRect;

		textObj.origin.set(0, 0);
	}
}
