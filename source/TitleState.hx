package;

import flixel.addons.ui.FlxUIButton;

class TitleState extends FlxState
{
	override public function create()
	{
		super.create();

		var butt:FlxUIButton = new FlxUIButton(0, 0, '>w<', function()
		{
			PlayState.chart = Chart.ChartConverter.convert(lime.utils.Assets.getText('assets/songs/darnell/charts/chart.json'));
			FlxG.switchState(new PlayState());
		});
		butt.screenCenter();
		add(butt);

		add(new FlxUIButton(butt.x, butt.y + 40, 'option', function()
		{
			FlxG.switchState(new OptionsState());
		}));
	}
}
