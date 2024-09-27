package states;

import sys.io.File;
import flixel.addons.ui.FlxUIButton;
import flixel.input.keyboard.FlxKey;
import objects.Alphabet;
import objects.ui.ImageButton;
import song.Song;
import util.GradientMap;

class TitleState extends FlxState {
	override public function create() {
		super.create();

		bgColor = 0xff666666;

		fuck(50, 'boob engine!', 0xff000000, 0xffffff);
		fuck(150, 'I MAY BE STUPID', 0xffffff, 0xff000000);

		var bleh:Array<ImageButton> = [];
		for (idx => i in ['cog', 'paper', 'delete']) {
			var button:ImageButton = new ImageButton(Paths.image('ui/editor/$i'));
			button.setPosition(50 + (111 * idx), FlxG.height - 150);
			add(button);
			bleh.push(button);
		}

		bleh[1].inputs = [FlxKey.N, FlxKey.SPACE];

		bleh[2].quickColor(0xff3399, 0x660066);
		bleh[2].inputs = [FlxKey.C];

		var butt:FlxUIButton = new FlxUIButton(0, 0, '>w<', function() {
			Song.load('bopeebo', 'hard', 'pico');
			FlxG.switchState(new PlayState());
		});
		butt.screenCenter();
		add(butt);

		add(new FlxUIButton(butt.x, butt.y + 40, 'option', function() {
			FlxG.switchState(new OptionsState());
		}));

		add(new FlxUIButton(butt.x, butt.y + 80, 'chartacter serklsvct', function() {
			FlxG.switchState(new CharacterState());
		}));

		add(new FlxUIButton(butt.x, butt.y + 120, 'fri plei', function() {
			FlxG.switchState(new FreeplayState());
		}));

		var FUCK = new objects.ui.FreeplayCapsule();
		FUCK.text = 'EVIL capsule..,,';
		FUCK.setPosition(50, 50);
		FUCK.color = 0xff0000;
		add(FUCK);

		new FlxTimer().start(3, (_) -> {
			FUCK.angularAcceleration = 4;
		});

		FlxG.sound.playMusic(Paths.sound('girlfriendsRingtone', 'music'));
	}

	function fuck(_y:Float = 50, text:String = 'boob engine!', col:FlxColor = -1, outli:FlxColor = 0) {
		var alp:Alphabet = new Alphabet(text);
		alp.alignment = CENTER;
		alp.setPosition(FlxG.width * 0.5, _y);
		add(alp);

		var grad:GradientMap = new GradientMap();
		alp.forEach(a -> {
			a.shader = grad.shader;
		});
		grad.set(col, outli);
	}
}
