package;

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

		test = new Alphabet();
		test.text = prevtext;
		test.x = test.y = 50;
		add(test);

		input = new FlxInputText(50, FlxG.height - 16 - 50, FlxG.width - 200, prevtext, 16);
		add(input);

		var butt = new FlxUIButton(input.x + input.width + 5, input.y, 'Paste', function()
		{
			@:privateAccess input.insertSubstring(input.text, Clipboard.text, input.caretIndex);
		});
		add(butt);

		if (!FlxG.sound.music.playing)
			FlxG.sound.playMusic('assets/songs/bopeebo/Inst.ogg', 0.6);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		test.text = input.text;

		if (FlxG.keys.justPressed.F5)
		{
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
