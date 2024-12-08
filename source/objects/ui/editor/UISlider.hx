package objects.ui.editor;

import flixel.group.FlxSpriteGroup;

class UISlider extends FlxSpriteGroup {
	public var value(get, set):Float;
	public var min:Float = 0;
	public var max:Float = 1;
	public var percent(default, set):Float = -1;
	public var bounded:Bool = true;

	public function set_value(v:Float):Float {
		percent = FlxMath.remapToRange(v, min, max, 0, 1);
		// trace('blehh $percent');
		return v;
	}

	public function get_value():Float {
		return FlxMath.lerp(min, max, percent);
	}

	public function set_percent(v:Float):Float {
		if (bounded)
			v = FlxMath.bound(v, 0, 1);

		if (percent != v) {
			percent = v;
			bar.percent = v;
			handle.setPosition(x, y);
			handle.x -= handle.width * .5;
			handle.y -= handle.height * .5;
			handle.x += bar.width * percent;
			if (onChange != null)
				onChange(value);
		}
		return v;
	}

	public var onChange:Float->Void = null;

	public var handle:FlxSprite;
	public var bar:HealthBar;

	public function new(initialValue:Float = -1, ?barWidth:Float = 256) {
		super();
		var _frames = Paths.sparrow('ui/editor/ui');

		handle = new FlxSprite();
		bar = new HealthBar(-5, -5);
		add(bar);
		add(handle);

		handle.frames = _frames;
		bar.frames = bar.emptySprite.frames = _frames;

		for (i in [bar, bar.emptySprite]) {
			i.animation.addByPrefix('idle', 'slider0', 12, true);
			i.animation.play('idle', true);
			i.updateHitbox();

			i.setGraphicSize(barWidth, i.frameHeight);
			i.updateHitbox();
		}

		handle.animation.addByIndices('idle', 'slider_handle', [0, 1], '', 12, true);
		handle.animation.addByIndices('idle-scream', 'slider_handle', [4, 5], '', 12, true);
		handle.animation.addByIndices('scream', 'slider_handle', [2, 3], '', 12, false);
		handle.animation.addByIndices('unscream', 'slider_handle', [3, 2], '', 12, false);

		handle.animation.finishCallback = function(a:String) {
			if (!a.startsWith('idle')) {
				handle.animation.play('idle' + (pressing ? '-scream' : ''));
			}
		}

		handle.animation.play('idle', true);
		handle.updateHitbox();
		bar.setColors(0x333333, 0xffffff);

		handle.antialiasing = bar.antialiasing = bar.emptySprite.antialiasing = true;

		antialiasing = true;
		moves = false;

		percent = initialValue;
	}

	var pressing:Bool = false;

	override public function update(elapsed:Float) {
		super.update(elapsed);
		if (FlxG.mouse.overlaps(this)) {
			if (FlxG.mouse.pressed && !handle.animation.name.contains('scream') && !pressing) {
				handle.animation.play('scream', true);
				pressing = true;
			}
		}
		if (FlxG.mouse.justReleased && handle.animation.name != 'unscream' && pressing) {
			handle.animation.play('unscream', true);
			pressing = false;
		}
		if (pressing) {
			// percent = FlxMath.remapToRange(percent, 0, 1, FlxG.mouse.x - x, FlxG.mouse.x - x + bar.width);
			percent = ((FlxG.mouse.x - x) / bar.width);
		}
	}
}
