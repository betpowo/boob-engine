package objects.ui.editor;

class UICheckBox extends FlxSprite {
	public var checked(default, set):Bool = false;

	public function set_checked(v:Bool):Bool {
		if (checked != v) {
			checked = v;
			animation.play('check', true, !checked);
			if (onChange != null)
				onChange();
		}
		return v;
	}

	public var onChange:Void->Void = null;

	public function new(ch:Bool = false) {
		super();
		frames = Paths.sparrow('ui/editor/ui');
		animation.addByIndices('idle', 'checkbox', [0], '', 24, true);
		animation.addByIndices('idle-checked', 'checkbox', [9], '', 24, true);
		animation.addByPrefix('check', 'checkbox', 37, false);
		animation.finishCallback = function(a:String) {
			if (!a.startsWith('idle')) {
				animation.play('idle' + (checked ? '-checked' : ''));
			}
		}
		animation.play('idle' + (ch ? '-checked' : ''), true);
		@:bypassAccessor checked = ch;

		antialiasing = true;
		moves = false;
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
		if (FlxG.mouse.overlaps(this) && FlxG.mouse.justPressed) {
			checked = !checked;
		}
	}
}
