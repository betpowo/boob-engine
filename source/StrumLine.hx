import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

class StrumLine extends FlxTypedSpriteGroup<StrumNote>
{
	public var autoHit(default, set):Bool = false;

	public function set_autoHit(v:Bool):Bool
	{
		forEach(function(note)
		{
			note.autoHit = v;
		});
		return autoHit = v;
	}

	public function new(strums:Int = 4)
	{
		super();
		for (i in 0...strums)
		{
			var strum = new StrumNote(i);
			strum.setPosition(116 * i);
			strum.ID = i;
			add(strum);
		}
	}
}
