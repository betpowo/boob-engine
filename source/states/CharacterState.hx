package states;

import flxanimate.FlxAnimate;

class CharacterState extends FlxState {
	var gf:FlxAnimate;
	var bf:FlxAnimate;

	override public function create() {
		super.create();

		doCharacters();

		Conductor.paused = false;
		FlxG.sound.playMusic(Paths.sound('stayFunky', 'music'));
		Conductor.bpm = 90;

		Conductor.beatHit.add(beatHit);
	}

	function doCharacters() {
		gf = new FlxAnimate(0, 0, Paths.file('images/menus/char-select/chars/gf/sprite'));

		gf.anim.addBySymbolIndices('danceLeft', 'Partner GF idle', [for (i in 0...15) i], 24, false);
		gf.anim.addBySymbolIndices('danceRight', 'Partner GF idle', [for (i in 15...31) i], 24, false);

		gf.anim.addBySymbol('confirm', 'Partner GF confirm', 24, true);
		gf.anim.addBySymbol('deselect', 'Partner GF deselect', 24, false);

		gf.anim.play('danceRight');
		gf.antialiasing = true;

		add(gf);
		gf.screenCenter();

		bf = new FlxAnimate(0, 0, Paths.file('images/menus/char-select/chars/bf/sprite'));
		bf.anim.addBySymbol('idle', 'bf cs idle', 24, false);
		bf.anim.addBySymbol('confirm', 'select', 24, false);
		bf.anim.addBySymbol('deselect', 'deselect', 24, false);
		bf.anim.addBySymbol('in', 'slidein', 24, false);
		bf.anim.addBySymbol('out', 'slideout', 24, false);

		bf.anim.play('idle');
		bf.antialiasing = true;

		add(bf);
		// bf.screenCenter();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (FlxG.keys.justPressed.ESCAPE) {
			FlxG.switchState(new states.TitleState());
		}
	}

	function beatHit() {
		gf.anim.play('dance' + (Conductor.beat % 2 == 0 ? 'Left' : 'Right'));
		bf.anim.play('idle');
	}
}
