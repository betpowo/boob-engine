import flixel.FlxSpriteExt;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxPoint;
import tools.Ini.IniData;
import tools.Ini;

using StringTools;

class Alphabet extends FlxTypedSpriteGroup<AlphaCharacter>
{
	public var text(default, set):String = '';
	public var alignment:FlxTextAlign = LEFT;

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
					var letter:AlphaCharacter = members[i];
					if (letter != null)
					{
						letter.kill();
						members.remove(letter);
						remove(letter);
					}
				}
			});

			for (idx => char in text.split(''))
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
					case '\r':
						continue;
					default:
						var a:AlphaCharacter = recycle(AlphaCharacter);
						a.setPosition(xPos, yPos * rows);
						a.change(char);
						a.spawn.set(a.x, a.y);
						add(a);
						xPos += a.frameWidth + 1; // tiny padding
						a.ID = idx;

						if (a.extraData != null)
						{
							var b:AlphaCharacter = recycle(AlphaCharacter);
							b.animation.remove('idle');
							b.animation.addByPrefix('idle', a.extraData.anim, 24, true);
							b.animation.play('idle', true);
							b.updateHitbox();
							b.setPosition(a.spawn.x + ((a.frameWidth - b.frameWidth) * 0.5), a.spawn.y);
							b.x += a.extraData.x;
							b.y += a.extraData.y;

							var flip:FlxAxes = a.extraData.flip;
							if (flip.x)
								b.flipX = true;
							if (flip.y)
								b.flipY = true;

							b.spawn.set(b.x, b.y);
							add(b);

							b.ID = a.ID;
						}
				}
			}
			setScale(scaleX, scaleY);
			angle = angle;
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

	override function set_angle(a:Float):Float
	{
		angle = a;
		forEachAlive((letter) ->
		{
			letter.angle = a;
			var pot:FlxPoint = FlxPoint.get((letter.spawn.x * scaleX) + x, (letter.spawn.y * scaleY) + y);
			pot.pivotDegrees(FlxPoint.weak(x, y), a);
			letter.setPosition(pot.x, pot.y);
			pot.put();
		});
		return super.set_angle(a);
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
 * only extends `FlxSpriteExt` just so i can rotate the offset property
 */
class AlphaCharacter extends FlxSpriteExt
{
	public static var ini:IniData;

	public var spawn:FlxPoint = new FlxPoint(0, 0);
	public var character:String = '?';

	static var sheets:Array<String> = null;

	public function new(char:String = '?')
	{
		super();
		if (ini == null)
			ini = Ini.parseFile(Paths.ini('images/ui/alphabet'));

		if (sheets == null)
			sheets = (ini.global.sheets : String).split(",");

		var atlas = Paths.sparrow('ui/alphabet/' + sheets[0]);
		Paths.exclude('images/ui/alphabet/${sheets[0]}.png');

		for (i in 1...sheets.length)
		{
			atlas.addAtlas(Paths.sparrow('ui/alphabet/' + sheets[i]));
			Paths.exclude('images/ui/alphabet/${sheets[i]}.png');
		}

		frames = atlas;

		antialiasing = true;
		moves = false;
		// scaleOffset = true;
		// change(char);
	}

	public var extraData:Dynamic = null;

	public function change(char:String = '?')
	{
		try
		{
			character = char;

			if (ini.exists('replacements'))
			{
				for (k => v in ini.replacements)
				{
					if (k.contains(char))
					{
						char = ini.replacements[k];
						// Log.print(ini.replacements[k], 0xccff00);
						// Log.print(k, 0x00cccc);
					}
				}
			}

			// Log.print(char, 0xcc00ff);

			animation.addByPrefix('idle', char, 24, true);
			animation.play('idle', true);
			updateHitbox();

			if (ini.exists('transform'))
			{
				for (k => v in ini.transform)
				{
					if (k.contains(character))
					{
						// Log.print('hihiihiihih ' + character, 0x6600ff);
						final spli:Array<String> = (v : String).split(',');
						x += Std.parseFloat(spli[0]);
						y += Std.parseFloat(spli[1]);
						var flip = FlxAxes.fromString(spli[2] ?? 'none');
						if (flip.x)
							flipX = true;
						if (flip.y)
							flipY = true;
						// Log.print(spli.toString(), 0x66ff33);
					}
				}
			}

			extraData = null;

			if (ini.exists('extra'))
			{
				for (k => v in ini.extra)
				{
					if (k.contains(character))
					{
						final spli:Array<String> = (v : String).split(',');
						extraData = {
							anim: spli[0],
							x: Std.parseFloat(spli[1]),
							y: Std.parseFloat(spli[2]),
							flip: FlxAxes.fromString(spli[3] ?? 'none')
						}
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
