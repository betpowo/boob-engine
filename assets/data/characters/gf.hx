var speakers:FlxSpriteExt = new FlxSpriteExt();

function build() {
	trace('yo');
	speakers.frames = Paths.sparrow('characters/props/speakers');
	speakers.animation.addByPrefix('idle', 'speakers', 24, false);
	speakers.animation.play('idle', true);
	speakers.antialiasing = true;
	speakers.updateHitbox();
	Ash.attach(this, speakers, (this.frameWidth - speakers.frameWidth) * 0.5, this.frameHeight - 125);
	Conductor.beatHit.add(beatHit);

	insert(0, speakers);
}

function destroy() {
	speakers.destroy();
	Conductor.beatHit.remove(beatHit);
}

function beatHit() {
	speakers.animation.play('idle', true);
}
