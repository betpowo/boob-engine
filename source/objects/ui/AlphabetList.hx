package objects.ui;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSignal;
import objects.Alphabet;

class AlphabetList extends FlxTypedSpriteGroup<Alphabet>
{
	public var list(default, set):Array<String> = [];
	public var cutoff:Int = 4;
	public var curSelected(default, set):Int = 0;
	public var onChange:FlxSignal = new FlxSignal();
	public var press:Int->Void;
	public var followFunction:Alphabet->Float->Void;
	public var pressInputs:Array<FlxKey> = [SPACE, ENTER];
	public var prevInputs:Array<FlxKey> = [W, UP];
	public var nextInputs:Array<FlxKey> = [S, DOWN];

	public function set_curSelected(v:Int):Int
	{
		if (list.length > 1)
			curSelected = FlxMath.wrap(v, 0, list.length - 1);
		else
			curSelected = 0;
		onChange.dispatch();
		return curSelected;
	}

	public function set_list(v:Array<String>):Array<String>
	{
		list = v;
		refresh();
		return list;
	}

	public function refresh()
	{
		if (list.length > 0)
		{
			var lastID:Int = 0;
			for (idx => i in list)
			{
				var alp:Alphabet = members[idx];
				if (alp != null)
				{
					if (alp.text != i)
						alp.text = i;
				}
				else
				{
					var alp:Alphabet = recycle(Alphabet);
					alp.text = i;
					alp.setPosition(x, y);
					alp.ID = idx;
				}
				lastID = idx;
			}

			while (members.length > lastID + 1)
			{
				var letter:Alphabet = members[members.length - 1];
				if (letter != null)
				{
					letter.kill();
					members.remove(letter);
					remove(letter);
				}
			}
		}
		else
		{
			for (letter in members)
			{
				if (letter != null)
				{
					letter.kill();
					members.remove(letter);
					remove(letter);
				}
			}
		}
		curSelected = curSelected > list.length - 1 ? list.length - 1 : curSelected;
	}

	public function new()
	{
		super();

		onChange.add(() ->
		{
			FlxG.sound.play(Paths.sound('ui/scroll'), 0.7);
		});

		followFunction = function(a, elapsed)
		{
			var target:Int = a.ID - curSelected;
			a.x = FlxMath.lerp(a.x, x + (target * 20), elapsed * 10);
			a.y = FlxMath.lerp(a.y, y + (target * 156), elapsed * 10);
			a.alpha = target == 0 ? 1 : 0.6;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (members.length > 0)
		{
			forEach(alp ->
			{
				alp.active = Math.abs(alp.ID - curSelected) <= cutoff;
				if (followFunction != null)
					followFunction(alp, elapsed);
			});
			if (press != null && FlxG.keys.anyJustPressed(pressInputs))
				press(curSelected);

			if (members.length > 1)
			{
				if (FlxG.keys.anyJustPressed(prevInputs))
					curSelected -= 1;
				if (FlxG.keys.anyJustPressed(nextInputs))
					curSelected += 1;
			}
		}
	}
}
