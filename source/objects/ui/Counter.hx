package objects.ui;

import flixel.util.FlxStringUtil;

class Counter extends FlxSprite {
	public var number(default, set):Float = 0;
	public var display(default, set):CounterDisplay = INT;

	public function set_number(v:Float):Float {
		if (number != v) {
			number = v;
			schedule();
		}
		return v;
	}

	public function set_display(v:CounterDisplay):CounterDisplay {
		if (display != v) {
			display = v;
			schedule();
		}
		return v;
	}

	function schedule() {
		displit = getDisplay(number).split('');
	}

	public var separator:Float = 4;
	public var alignment:FlxTextAlign = LEFT;

	var displit:Array<String> = [];

	public function new(?x:Float = 0, ?y:Float = 0) {
		super(x, y);
		loadGraphic(Paths.image('ui/num'));
		loadGraphic(Paths.image('ui/num'), true, Std.int(width / 7), Std.int(height / 2));
		animation.add('num', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13], 0, true);
		animation.play('num', true);
		updateHitbox();

		antialiasing = true;
		moves = false;

		schedule();
	}

	override public function draw() {
		var ogx = x;
		var spli = displit;
		if (alignment == RIGHT) {
			x -= (frameWidth + separator) * scale.x * spli.length;
			x += separator;
		} else if (alignment == CENTER) {
			x -= ((frameWidth + separator) * scale.x * spli.length) * 0.5;
			x += separator * scale.x;
		}
		for (waaa in spli) {
			var num = 0;
			switch (waaa) {
				case '-':
					num = 10;
				case '.':
					num = 11;
				case ':':
					num = 12;
				case '?':
					num = 13;
				default:
					num = Std.parseInt(waaa);
			}
			animation.play('num', true, false, num);
			super.draw();
			x += (frameWidth + separator) * scale.x;
		}
		x = ogx;
	}

	function getDisplay(num:Float):String {
		return switch (display) {
			case QUESTION:
				[for (i in 0...Std.int(Math.max(num, 1))) '?'].join('');
			case TIME | TIME_MS:
				FlxStringUtil.formatTime(num, display == TIME_MS);
			case INT:
				Std.string(Math.floor(num));
			default:
				Std.string(num);
		}
	}
}

enum CounterDisplay {
	INT;
	FLOAT;
	TIME;
	TIME_MS;
	QUESTION;
}
