import flixel.FlxObject;

var fuck = new FlxObject();

function create() {
	// this.scale.set(FlxG.random.float(0.5, 2), FlxG.random.float(0.5, 2));
	FlxG.camera.follow(fuck, null, 4);
}

function update(elapsed) {
	fuck.setPosition(FlxG.width * .5, FlxG.height * .5);

	if (StringTools.startsWith(this.animation.name, 'sing')) {
		fuck.setPosition(this.getMidpoint().x, this.getMidpoint().y);
	}
	if (FlxG.keys.justPressed.SPACE) {
		this.playAnim('singUP', true);
		this.holdTime = this.animation.curAnim.frameDuration * this.animation.curAnim.numFrames;
	}
}
