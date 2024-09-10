function create() {
	// this.scale.set(FlxG.random.float(0.5, 2), FlxG.random.float(0.5, 2));
	this.angle = 90;
}

function update(elapsed) {
	if (FlxG.keys.justPressed.SPACE) {
		this.playAnim('singUP', true);
		this.holdTime = this.animation.curAnim.frameDuration * this.animation.curAnim.numFrames;
	}
}

function playAnim(anim) {
	if (StringTools.startsWith(anim, 'sing')) {
		FlxG.camera.zoom += 0.025;
		PlayState.instance.camHUD.zoom += 0.05;

		FlxG.camera.shake(4 / FlxG.camera.width, 0.1);
		PlayState.instance.camHUD.shake(5 / FlxG.camera.width, 0.1);
	}
}
