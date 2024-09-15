package objects.ui;

import flixel.FlxSpriteExt;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import flxanimate.FlxAnimate;

class FreeplayCapsule extends FlxSpriteGroup {
	public var text(default, set):String = '';
	public var icon:FlxSpriteExt;
	public var difficulty(default, set):Int = 0;

	// public var color(default, set):FlxColor = 0xaadeff;
	var frontGlow:FlxSpriteExt;
	var backGlow:FlxSpriteExt;
	var textObj:FlxText;
	var maxWidth:Float = 373;

	var _diffGroup:FlxSpriteGroup;

	public function set_text(v:String):String {
		if (textObj != null && textObj.text != v) {
			textObj.text = v;
		}
		text = v;
		return v;
	}

	public function set_difficulty(d:Int):Int {
		if (d < 0)
			d = 0;

		var stri:String = Std.string(d);
		if (d < 10)
			stri = '0$stri';

		static var animMap = ['ZERO', 'ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', 'SIX', 'SEVEN', 'EIGHT', 'NINE'];

		var lastID:Int = 0;
		for (idx => i in stri.split('')) {
			var num = _diffGroup.members[idx];
			if (num == null) {
				num = _diffGroup.recycle(FlxSprite);
				num.frames = Paths.sparrow('menus/freeplay/nums');
				for (jdx => j in animMap) {
					num.animation.addByPrefix(Std.string(jdx), j, 24, true);
				}
				num.x = idx * 36;
				num.antialiasing = true;
				_diffGroup.add(num);
			}

			num.animation.play(i);
			lastID = idx;
		}

		while (_diffGroup.members.length > lastID + 1) {
			var letter = _diffGroup.members[_diffGroup.members.length - 1];
			if (letter != null) {
				letter.kill();
				_diffGroup.members.remove(letter);
				remove(letter);
			}
		}

		difficulty = d;
		return d;
	}

	override public function set_color(c:FlxColor):FlxColor {
		color = c;
		if (backGlow != null)
			backGlow.color = c;
		if (frontGlow != null)
			frontGlow.color = c;
		if (textObj != null) {
			textObj.borderColor = c;
			textObj.borderColor.alpha = 0x55;
		}
		return c;
	}

	public function new() {
		super();

		backGlow = bro('lcd screen backing', 40, 5);

		textObj = new FlxText();
		textObj.font = Paths.font('5by7.ttf');
		textObj.size = 40;
		textObj.antialiasing = true;
		textObj.borderStyle = FlxTextBorderStyle.OUTLINE;
		textObj.borderColor = 0x55aaeeff;
		textObj.borderSize = 2;
		textObj.setPosition(65, 28);

		bro('mp3 capsule');

		frontGlow = bro('capsule glow', -54, -15);

		add(textObj);

		frontGlow.blend = ADD;

		textObj.clipRect = new FlxRect(0, 0, maxWidth, textObj.height);

		_diffGroup = new FlxSpriteGroup();
		add(_diffGroup);
		_diffGroup.setPosition(456, 15);

		origin.set(0, 0);

		text = 'FreeplayCapsule';
		color = 0xaadeff;
		difficulty = 0;
	}

	function bro(sym:String, x:Float = 0, y:Float = 0):FlxSpriteExt {
		var capsule:FlxSpriteExt = cast recycle(FlxSpriteExt);
		capsule.frames = Paths.sparrow('menus/freeplay/capsule');
		capsule.animation.addByPrefix('idle', sym, 24, true);
		capsule.animation.play('idle', true);
		capsule.antialiasing = true;
		capsule.offsetOffset.set(x * -1, y * -1);
		capsule.origin.set();
		capsule.rotateOffset = capsule.scaleOffsetX = capsule.scaleOffsetY = true;
		add(capsule);
		return capsule;
	}

	var el:Float = 0;

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (active && visible && isOnScreen(camera)) {
			el += elapsed;
			textObj.borderSize = FlxMath.lerp(0.5, 2.5, (FlxMath.fastSin(el * 70) + 1) * 0.5);
			textObj.clipRect.width = maxWidth;
			textObj.clipRect.height = textObj.height;
			textObj.clipRect = textObj.clipRect;

			textObj.origin.set((x - textObj.x), (y - textObj.y)); // why
		}
	}
}
