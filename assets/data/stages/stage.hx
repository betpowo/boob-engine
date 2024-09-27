// called before state finished loading
function init() {
	quick('back', -600, -200, 0.9);
	quick('front', -650, 600, 0.9, 1.1);
	quick('curtains', -500, -300, 1.3, 0.9);
}

function quick(sprite:String, ?x:Float = 0, ?y:Float = 0, ?scroll:Float = 1, ?scale:Float = 1) {
	x ??= 0;
	y ??= 0;
	scroll ??= 1;
	scale ??= 1;
	var spr:FlxSprite = new FlxSprite(x, y);
	spr.loadGraphic(Paths.image('stages/stage/' + sprite));
	spr.scrollFactor.set(scroll, scroll);
	spr.scale.set(scale, scale);
	add(spr);
	return spr;
}

// called AFTER state is finished, so you can do cool stuff here like add stuff in front of characters
function create() {
	if (inGame) {
		/*this.opponent.setStagePosition(335, 885);
			this.spectator.setStagePosition(751, 787);
			this.player.setStagePosition(989, 885); */
	}
}
