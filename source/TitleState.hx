package;

import flixel.addons.ui.FlxUIButton;

class TitleState extends FlxState
{
	override public function create()
	{
		super.create();

		var presses:Int = 0;
		var butt:FlxUIButton;
		butt = new FlxUIButton(0, 0, 'test sound', function()
		{
			presses += 1;
			switch (presses)
			{
				case 1:
					butt.label.text = 'test note obj';
					FlxG.sound.play(Paths.sound('charter/noteLay'));
				case 2:
					butt.label.text = 'start :3';
					add(new Note(2));
				default:
					butt.label.text = '>w<';
					FlxG.switchState(new PlayState());
					PlayState.chart = Chart.ChartConverter.convert(lime.utils.Assets.getText('assets/songs/darnell/charts/chart.json'));
			}
		});
		butt.screenCenter();
		add(butt);
	}
}
