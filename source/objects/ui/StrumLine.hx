package objects.ui;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import song.Chart.ChartLane;
import song.Song;

class StrumLine extends FlxTypedSpriteGroup<StrumNote> {
	public var autoHit(default, set):Bool = true;
	public var spacing(default, set):Float = 116;
	public var char:Character = null;

	public function set_spacing(v:Float) {
		forEach(function(note) {
			note.x = x + (v * note.ID);
		});
		return spacing = v;
	}

	public function set_autoHit(v:Bool):Bool {
		forEach(function(note) {
			note.autoHit = v;
		});
		return autoHit = v;
	}

	public var data:ChartLane;
	public var vocals:FlxSound;

	public function new(data:ChartLane) {
		super();
		this.data = data;
		if (data == null)
			return;

		final options = util.Options.data;

		for (i in 0...(data.keys ?? 4)) {
			var strum = new StrumNote(i);
			strum.setPosition(spacing * i);
			strum.parentLane = this;
			strum.ID = i;
			strum.inputs = options.keys[i] ?? [];

			var rgbs = options.noteColors;
			var que = rgbs[strum.ID] ?? {base: 0x717171, outline: 0x333333};
			strum.rgb.set(que.base, -1, que.outline);

			add(strum);
		}

		if (data.char != null)
			char = new Character(data.char, false, false);

		if (data.play != null)
			autoHit = !data.play;
		else
			autoHit = true;

		if (data.vox != null) {
			vocals = new FlxSound().loadEmbedded(Paths.song(Song.song, 'Voices' + (data.vox.length > 0 ? '-${data.vox}' : ''), Song.variation));
			FlxG.sound.list.add(vocals);
		}
	}
}
