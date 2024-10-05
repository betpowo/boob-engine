package substates;

import flixel.graphics.FlxGraphic;
import objects.Alphabet;
import objects.ui.AlphabetList;
import states.PlayState;
import util.CoolUtil;
import util.GradientMap;

class PauseSubstate extends FlxSubState {
	var bg:FlxSprite;

	override public function create() {
		PlayState.pause(true);

		super.create();

		bg = new FlxSprite().makeGraphic(1, 1, -1);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.screenCenter();
		bg.setColorTransform(0, 0, 0, 0);
		add(bg);

		var songNameColor:FlxColor = FlxColor.fromString(Song.meta.color ?? '#f9feb1');
		var fuck:FlxColor = new FlxColor(songNameColor);
		// agony
		fuck *= 0xee55bb;
		fuck.blueFloat *= songNameColor.blueFloat;
		fuck.saturation *= 1.1;
		fuck.alpha = 255;

		var songName = CoolUtil.makeTardlingText(Song.meta.display ?? Song.song, songNameColor, fuck);
		add(songName);
		songName.setPosition(50, 50);

		var diffAsset:FlxGraphic = Paths.image('menus/results/diffs/${Song.difficulty}') ?? Paths.image('menus/results/diffs/_default');
		var diff:FlxSprite = new FlxSprite(50, 50).loadGraphic(diffAsset);
		add(diff);
		songName.x += diff.width + 25;

		var compName = CoolUtil.makeTardlingText('${Song.meta.art ?? '(undefined)'}\n\n${Song.meta.music ?? '(undefined)'}\n\n${Song.meta.chart ?? '(undefined)'}');
		add(compName);
		compName.scale.set(0.6, 0.6);
		compName.updateHitbox();
		compName.setPosition(50, FlxG.height - 50 - compName.height);

		songName.y -= 10;
		diff.y -= 10;

		var compIcon:FlxSprite = new FlxSprite(50, -50).loadGraphic(Paths.image('ui/pause-icons'));
		add(compIcon);
		diff.antialiasing = compIcon.antialiasing = true;
		compIcon.y += FlxG.height - compIcon.height;
		compName.y -= 10;
		compName.x += compIcon.width + 2;

		songName.alpha = diff.alpha = compName.alpha = compIcon.alpha = 0.001;

		FlxTween.tween(diff, {y: diff.y + 10, alpha: 1}, 0.1, {ease: FlxEase.quartOut, startDelay: 0.25});
		FlxTween.tween(songName, {y: songName.y + 10, alpha: 1}, 0.1, {ease: FlxEase.quartOut, startDelay: 0.3});

		FlxTween.tween(compIcon, {y: compIcon.y + 10, alpha: 1}, 0.1, {ease: FlxEase.quartOut, startDelay: 0.35});
		FlxTween.tween(compName, {y: compName.y + 10, alpha: 1}, 0.1, {ease: FlxEase.quartOut, startDelay: 0.35});

		var rightArrow:Alphabet = new Alphabet('→');
		var leftArrow:Alphabet = new Alphabet('←');
		rightArrow.x = leftArrow.x = -2000;
		add(rightArrow);
		add(leftArrow);

		var menu:AlphabetList = new AlphabetList();
		menu.setPosition(FlxG.width * 0.5, FlxG.height * 0.5);
		menu.list = ['RESUME', 'RESTART', 'REGRET'];
		menu.forEach(a -> {
			a.alignment = CENTER;
		});
		menu.followFunction = function(a, elapsed) {
			a.x = menu.x;
			a.y = menu.y;
			a.y -= 32;
			a.y -= 60 * (menu.list.length - 1);
			a.y += 120 * a.ID;
			a.alpha = a.ID == menu.curSelected ? 1 : 0.6;
			if (a.alpha == 1) {
				rightArrow.setPosition(a.x - rightArrow.maxWidth - 30, a.y);
				leftArrow.setPosition(a.x + a.maxWidth + 30, a.y);
				rightArrow.x -= a.maxWidth * .5;
				leftArrow.x -= a.maxWidth * .5;
			}
		}
		menu.press = function(a) {
			switch (menu.list[a].toLowerCase()) {
				case 'regret':
					close();
					PlayState.cachedTransNotes = [];
					FlxTween.globalManager.active = true;
					FlxTimer.globalManager.active = true;
					FlxG.switchState(new states.TitleState());
				case 'restart':
					close();
					// PlayState.pause(false);
					FlxG.resetState();
				default:
					close();
					PlayState.pause(false);
			}
		}
		add(menu);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (bg != null)
			bg.alpha = FlxMath.bound(bg.alpha + (elapsed * 3), 0, 0.6);
		if (FlxG.keys.justPressed.ESCAPE) {
			close();
			PlayState.pause(false);
		}
	}
}
