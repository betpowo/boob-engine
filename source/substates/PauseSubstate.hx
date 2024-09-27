package substates;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;
import objects.Alphabet;
import objects.ui.AlphabetList;
import util.GradientMap;

class PauseSubstate extends FlxSubState {
	var bg:FlxSprite;

	function makeTardlingText(text:String, col1:FlxColor = 0xff000000, col2:FlxColor = 0xffffff):FlxBitmapText {
		var fontLetters:String = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz:1234567890!?,.()-Ññ&\"'+[]/#";

		var text = new FlxBitmapText(0, 0, text, FlxBitmapFont.fromMonospace(Paths.image('ui/tardlingSpritesheet'), fontLetters, FlxPoint.get(49, 62)));
		text.letterSpacing = -15;
		text.antialiasing = true;

		var songNameGM:GradientMap = new GradientMap();
		text.shader = songNameGM.shader;
		songNameGM.set(col1, col2);

		return text;
	}

	override public function create() {
		states.PlayState.pause(true);

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
		fuck.brightness *= 0.85;
		fuck.saturation *= 1.2;
		fuck.magenta += 10;
		fuck.yellow += 10;
		fuck.redFloat *= 1.05;
		fuck.blueFloat *= 0.95;
		fuck.saturation *= 0.6;
		fuck.brightness *= 1.1;
		fuck.yellow *= 1.03;
		fuck.alpha = 255;

		var songName = makeTardlingText(Song.meta.display ?? Song.song, songNameColor, fuck);
		add(songName);
		songName.setPosition(50, 50);

		var diffAsset:FlxGraphic = Paths.image('menus/results/diffs/${Song.difficulty}') ?? Paths.image('menus/results/diffs/_default');
		var diff:FlxSprite = new FlxSprite(50, 50).loadGraphic(diffAsset);
		add(diff);
		songName.x += diff.width + 25;

		var compName = makeTardlingText('${Song.meta.art ?? '(undefined)'}\n\n${Song.meta.music ?? '(undefined)'}\n\n${Song.meta.chart ?? '(undefined)'}');
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
					FlxTween.globalManager.active = true;
					FlxTimer.globalManager.active = true;
					FlxG.switchState(new states.TitleState());
				case 'restart':
					close();
					states.PlayState.pause(false);
					FlxG.resetState();
				default:
					close();
					states.PlayState.pause(false);
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
			states.PlayState.pause(false);
		}
	}
}
