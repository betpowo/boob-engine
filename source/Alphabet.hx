import flixel.FlxSpriteExt;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxPoint;
import tools.Ini.IniData;
import tools.Ini;

using StringTools;

class Alphabet extends FlxTypedSpriteGroup<AlphabetChar>
{
	public var text(default, set):String = '';

	private var _lastLength:Int = 0;

	public function set_text(t:String)
	{
		if (text != t)
		{
			text = t;

			var xPos:Float = 0;
			var yPos:Float = 66;
			var rows:Int = 0;

			forEach((letter) ->
			{
				var i:Int = members.length;
				while (i > 0)
				{
					--i;
					var letter:AlphabetChar = members[i];
					if (letter != null)
					{
						letter.kill();
						members.remove(letter);
						remove(letter);
					}
				}
			});

			for (char in text.split(''))
			{
				switch (char)
				{
					case ' ':
						xPos += 30;
					case '\t':
						xPos += 120;
					case '\n':
						xPos = 0;
						rows += 1;
					default:
						var a:AlphabetChar = recycle(AlphabetChar);
						a.setPosition(xPos, yPos * rows);
						a.change(char);
						a.spawn.set(a.x, a.y);
						add(a);
						xPos += a.frameWidth + 1; // tiny padding
				}
			}
			setScale(scaleX, scaleY);
		}
		return text;
	}

	public function new(text:String = 'Alphabet')
	{
		super();
		this.text = text;
	}

	public function setScale(_x:Float = 1, ?_y:Float = 1)
	{
		scaleX = _x;
		scaleY = _y ?? _x;
	}

	public var scaleX(default, set):Float = 1;
	public var scaleY(default, set):Float = 1;

	function set_scaleX(value:Float):Float
	{
		scale.x = value;
		updateHitbox();
		for (letter in members)
		{
			letter.x = x + (letter.spawn.x * value);
			letter.scale.x = value;
			letter.updateHitbox();
		}
		scaleX = value;
		return value;
	}

	function set_scaleY(value:Float):Float
	{
		scale.y = value;
		updateHitbox();
		for (letter in members)
		{
			letter.y = y + (letter.spawn.y * value);
			letter.scale.y = value;
			letter.updateHitbox();
		}
		scaleY = value;
		return value;
	}

	// cobalt bar wrote this
	public override function setColorTransform(redMultiplier:Float = 1.0, greenMultiplier:Float = 1.0, blueMultiplier:Float = 1.0,
			alphaMultiplier:Float = 1.0, redOffset:Float = 0.0, greenOffset:Float = 0.0, blueOffset:Float = 0.0, alphaOffset:Float = 0.0):Void
	{
		forEachAlive((a) ->
		{
			a.setColorTransform(redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier, redOffset, greenOffset, blueOffset, alphaOffset);
		});
	}
}

/**
 * a single `Alphabet` character
 */
class AlphabetChar extends FlxSpriteExt
{
	public var ini:IniData;
	public var spawn:FlxPoint = new FlxPoint(0, 0);

	public function new(char:String = '?')
	{
		super();
		var image = 'ui/fonts/bold';
		frames = Paths.sparrow(image);
		ini = Ini.parseFile(Paths.ini('images/$image'));
		antialiasing = true;
		moves = false;
		scaleOffset = true;
		change(char);
	}

	public function change(char:String = '?')
	{
		try
		{
			var ogchar:String = char;

			if (~/[a-z]/.match(char))
				char = char.toUpperCase();
			else if (~/[0-9]/.match(char))
				char += '_';

			if (ini?.replacements?.exists(char))
				char = '-${ini.replacements[char]}-';

			animation.addByPrefix('idle', char, 24, true);
			animation.play('idle', true);
			updateHitbox();

			if (ini.exists('offsets'))
			{
				for (k => v in ini.offsets)
				{
					if (k.contains(ogchar))
					{
						// Log.print('hihiihiihih ' + ogchar, 0x6600ff);
						final spli:Array<String> = (v : String).split(',');
						x += Std.parseFloat(spli[0]);
						y += Std.parseFloat(spli[1]);
						// Log.print(spli.toString(), 0x66ff33);
					}
				}
			}
		}
		catch (e)
		{
			Log.print('alpabet fail : $e', 0xff3366);

			animation.addByPrefix('idle', '-question mark-', 24, true);
			animation.play('idle', true);
			updateHitbox();
		}
	}
}
