package substates;

import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;
import objects.Alphabet;
import objects.ui.AlphabetList;
import util.GradientMap;

class PauseSubstate extends FlxSubState {
	var bg:FlxSprite;

	override public function create() {
		states.PlayState.pause(true);

		super.create();

		bg = new FlxSprite().makeGraphic(1, 1, -1);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.screenCenter();
		bg.setColorTransform(0, 0, 0, 0);
		add(bg);

		var fontLetters:String = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz:1234567890!?,.()-Ññ&\"'+[]/#";

		var songName = new FlxBitmapText(50, 50, 'bleh', FlxBitmapFont.fromMonospace(Paths.image('ui/tardlingSpritesheet'), fontLetters, FlxPoint.get(49, 62)));
		songName.letterSpacing = -15;
		songName.antialiasing = true;
		add(songName);

		var songNameGM:GradientMap = new GradientMap();
		songName.shader = songNameGM.shader;
		var songNameColor:FlxColor = 0xFFf9feb1;
		songNameGM.white = songNameColor;

		var fuck:FlxColor = new FlxColor(songNameColor);
		fuck.brightness *= 0.6;
		fuck.saturation = 1;
		fuck.magenta += 30;
		fuck.blue += 60;
		fuck.alpha = 255;
		songNameGM.black = fuck;

		songName.y -= 10;
		songName.alpha = 0;
		var bleh = FlxTween.tween(songName, {y: songName.y + 10, alpha: 1}, 0.1, {ease: FlxEase.quartOut, startDelay: 0.3});
		bleh.active = true;

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