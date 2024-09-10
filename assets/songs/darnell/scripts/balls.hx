function spawnNote(note, data) {
	if (data.lane == 0) {
		note.angleOffset = FlxG.random.float(0, 360);
		note.speed *= FlxG.random.float(0.5, 2);
	}
}
