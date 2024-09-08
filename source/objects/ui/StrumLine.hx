package objects.ui;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

class StrumLine extends FlxTypedSpriteGroup<StrumNote> {
	public var autoHit(default, set):Bool = false;
	public var spacing(default, set):Float = 116;

	public function set_spacing(v:Float) {
		forEach(function(note) {
			note.x = v * note.ID;
		});
		return spacing = v;
	}

	public function set_autoHit(v:Bool):Bool {
		forEach(function(note) {
			note.autoHit = v;
		});
		return autoHit = v;
	}

	public function new(strums:Int = 4) {
		super();
		for (i in 0...strums) {
			var strum = new StrumNote(i);
			strum.setPosition(spacing * i);
			strum.parentLane = this;
			strum.ID = i;
			add(strum);
		}
	}
}
