package;

import Alphabet.AlphaCharacter;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUIButton;
import flixel.system.FlxAssets;
import lime.system.Clipboard;

class AlphabetTestState extends FlxState
{
	var test:Alphabet;
	var input:FlxInputText;

	static var prevtext:String = 'Alphabet';

	override public function create()
	{
		super.create();

		test = new Alphabet('');
		test.text = prevtext;
		test.x = test.y = 50;
		add(test);

		input = new FlxInputText(50, FlxG.height - 16 - 50, FlxG.width - 512, prevtext, 16);
		add(input);

		add(new FlxUIButton(input.x + input.width + 5, input.y, '-X', function()
		{
			test.scaleX -= 0.1;
		}));

		add(new FlxUIButton(input.x + input.width + 5 + 70, input.y, '+X', function()
		{
			test.scaleX += 0.1;
		}));

		add(new FlxUIButton(input.x + input.width + 5 + 140, input.y, '-Y', function()
		{
			test.scaleY -= 0.1;
		}));

		add(new FlxUIButton(input.x + input.width + 5 + 210, input.y, '+Y', function()
		{
			test.scaleY += 0.1;
		}));

		add(new FlxUIButton(input.x + input.width + 5 + 280, input.y, '-angle', function()
		{
			test.angle -= 15;
		}));

		add(new FlxUIButton(input.x + input.width + 5 + 350, input.y, '+angle', function()
		{
			test.angle += 15;
		}));

		add(new FlxUIButton(input.x, input.y - 30, '\\n', function()
		{
			input.text += '\n';
		}));
		add(new FlxUIButton(input.x + 70, input.y - 30, 'left', function()
		{
			test.alignment = LEFT;
		}));
		add(new FlxUIButton(input.x + 140, input.y - 30, 'center', function()
		{
			test.alignment = CENTER;
		}));
		add(new FlxUIButton(input.x + 210, input.y - 30, 'right', function()
		{
			test.alignment = RIGHT;
		}));

		if (!FlxG.sound.music.playing)
			FlxG.sound.playMusic('assets/songs/bopeebo/Inst.ogg', 0.6);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		test.text = input.text;

		if (FlxG.keys.justPressed.F5)
		{
			AlphaCharacter.ini = null;
			prevtext = input.text;
			FlxG.resetState();
			FlxG.sound.play(FlxAssets.getSound('flixel/sounds/flixel')).persist = true;
		}

		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.sound.music.stop();
			FlxG.switchState(new PlayState());
		}
	}
}
