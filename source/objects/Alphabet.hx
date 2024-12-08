package objects;

import flixel.FlxSpriteExt;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxPoint;
import tools.Ini.IniData;
import tools.Ini;

using StringTools;

class Alphabet extends FlxTypedSpriteGroup<AlphaCharacter> {
	public var text(default, set):String = '';
	public var alignment(default, set):FlxTextAlign = LEFT;

	// do Not change this
	public var maxWidth:Float = 0;

	private var _lastLength:Int = 0;

	public function set_text(t:String) {
		if (text != t) {
			text = t;

			var xPos:Float = 0;
			var yPos:Float = 66;
			var rows:Int = 0;
			var _mWidth:Float = 0;
			var rowWidths:Array<Float> = [];

			maxWidth = 0;

			forEach((letter) -> {
				var i:Int = members.length;
				while (i > 0) {
					--i;
					var letter:AlphaCharacter = members[i];
					if (letter != null) {
						letter.kill();
						members.remove(letter);
						remove(letter);
					}
				}
			});

			for (idx => char in text.split('')) {
				switch (char) {
					case ' ':
						xPos += 26;
						_mWidth += 26;
					case '\t':
						xPos += 26 * 4;
						_mWidth += 26 * 4;
					case '\n':
						rowWidths[rows] = xPos;
						xPos = 0;
						rows += 1;
						_mWidth = 0;
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
						a.row = rows;

						_mWidth += a.frameWidth + 1;
						if (maxWidth < _mWidth) {
							maxWidth = _mWidth;
						}

						if (a.extraData != null) {
							var b:AlphaCharacter = recycle(AlphaCharacter);
							b.animation.remove('idle');
							b.animation.addByPrefix('idle', a.extraData.anim, 24, true);
							b.animation.play('idle', true);
							b.setPosition((a.spawn.x + a.offset.x) + ((a.frameWidth - b.frameWidth) * 0.5), a.spawn.y + a.offset.y);
							b.letterOffset[0] = a.extraData.x;
							b.letterOffset[1] = a.extraData.y;

							var flip:FlxAxes = a.extraData.flip;
							if (flip.x)
								b.flipX = true;
							if (flip.y)
								b.flipY = true;

							b.updateHitbox();
							b.spawn.set(b.x, b.y);
							add(b);

							b.ID = a.ID;
							// b.rowWidth = _mWidth;
							b.row = rows;
						}

						// a.rowWidth = _mWidth;
				}
			}
			rowWidths.push(xPos);

			forEachAlive((letter) -> {
				letter.rowWidth = rowWidths[letter.row];
			});

			setScale(scaleX, scaleY);
			angle = angle;
			alignment = alignment;
			// trace(rowWidths);
		}
		return text;
	}

	/**
	 * will offset the letters depending on alignment if enabled
	 */
	public var offsetPos:Bool = true;

	public function new(text:String = 'Alphabet') {
		super();
		this.text = text;
	}

	public function setScale(_x:Float = 1, ?_y:Float) {
		scaleX = _x;
		scaleY = _y != null ? _y : _x;
	}

	public var scaleX(default, set):Float = 1;
	public var scaleY(default, set):Float = 1;

	function set_scaleX(value:Float):Float {
		scale.x = value;
		updateHitbox();
		for (letter in members) {
			letter.x = x + (letter.spawn.x * value);
			letter.scale.x = value;
			letter.updateHitbox();
		}
		scaleX = value;
		alignment = alignment;
		return value;
	}

	function set_scaleY(value:Float):Float {
		scale.y = value;
		updateHitbox();
		for (letter in members) {
			letter.y = y + (letter.spawn.y * value);
			letter.scale.y = value;
			letter.updateHitbox();
		}
		scaleY = value;
		alignment = alignment;
		return value;
	}

	// static final stupid:Float = 2 / 5;

	public function set_alignment(a:FlxTextAlign):FlxTextAlign {
		// dont feel like writing it all so i just copy pasted psych engine code cus im lazy (kill me
		alignment = a;
		forEachAlive((letter) -> {
			var newOffset:Float = 0;

			switch (alignment) {
				case CENTER:
					newOffset = letter.rowWidth * .5;
					if (!offsetPos) newOffset -= maxWidth * .5;
				case RIGHT:
					newOffset = letter.rowWidth;
					if (!offsetPos) newOffset -= maxWidth;
				default:
					newOffset = 0;
			}

			letter.updateHitbox();
			letter.offset.x -= newOffset * scaleX;
		});
		return alignment;
	}

	override function set_angle(a:Float):Float {
		angle = a;
		forEachAlive((letter) -> {
			letter.angle = a;
			var pot:FlxPoint = FlxPoint.get((letter.spawn.x * scaleX) + x, (letter.spawn.y * scaleY) + y);
			pot.pivotDegrees(FlxPoint.weak(x, y), a);
			letter.setPosition(pot.x, pot.y);
			pot.put();
			letter.updateHitbox();
		});
		alignment = alignment;
		return super.set_angle(a);
	}

	// cobalt bar wrote this
	public override function setColorTransform(redMultiplier:Float = 1.0, greenMultiplier:Float = 1.0, blueMultiplier:Float = 1.0,
			alphaMultiplier:Float = 1.0, redOffset:Float = 0.0, greenOffset:Float = 0.0, blueOffset:Float = 0.0, alphaOffset:Float = 0.0):Void {
		forEachAlive((a) -> {
			a.setColorTransform(redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier, redOffset, greenOffset, blueOffset, alphaOffset);
		});
	}
}

/**
 * a single `Alphabet` character
 * only extends `FlxSpriteExt` just so i can change some stuff with rendering
 */
class AlphaCharacter extends FlxSpriteExt {
	public static var ini:IniData;

	public var spawn:FlxPoint = new FlxPoint(0, 0);
	public var character:String = '?';
	public var row:Int = 0;
	public var rowWidth:Float = 0;

	public static var sheets:Array<String> = null;

	public function new(char:String = '?') {
		super();
		if (ini == null)
			ini = Ini.parseFile(Paths.ini('images/ui/alphabet'));

		if (sheets == null)
			sheets = (ini.global.sheets : String).split(",");

		var atlas = Paths.sparrow('ui/alphabet/' + sheets[0]);
		Paths.exclude('images/ui/alphabet/${sheets[0]}.png');

		for (i in 1...sheets.length) {
			atlas.addAtlas(Paths.sparrow('ui/alphabet/' + sheets[i]));
			Paths.exclude('images/ui/alphabet/${sheets[i]}.png');
		}

		frames = atlas;

		antialiasing = true;
		moves = false;
		additiveOffset = true;
		rotateOffset = true;
		scaleOffsetY = true;
		// change(char);
	}

	public var extraData:Dynamic = null;
	public var letterOffset:Array<Float> = [0, 0];

	public function change(char:String = '?') {
		try {
			character = char;

			if (ini.exists('replacements')) {
				for (k => v in ini.replacements) {
					if (k.contains(char)) {
						char = ini.replacements[k];
						// Log.print(ini.replacements[k], 0xccff00);
						// Log.print(k, 0x00cccc);
					}
				}
			}

			// Log.print(char, 0xcc00ff);

			animation.addByPrefix('idle', char, 24, true);
			animation.play('idle', true);

			if (ini.exists('transform')) {
				for (k => v in ini.transform) {
					if (k.contains(character)) {
						// Log.print('hihiihiihih ' + character, 0x6600ff);
						final spli:Array<String> = (v : String).split(',');
						letterOffset[0] = Std.parseFloat(spli[0]);
						letterOffset[1] = Std.parseFloat(spli[1]);
						var flip = FlxAxes.fromString(spli[2] ?? 'none');
						if (flip.x)
							flipX = true;
						if (flip.y)
							flipY = true;
						// Log.print(spli.toString(), 0x66ff33);
					}
				}
			}
			if (ini.exists('equalsoffset') && character == '=') {
				final spli:Array<String> = cast(ini.equalsoffset, String).split(',');
				letterOffset[0] = Std.parseFloat(spli[0]);
				letterOffset[1] = Std.parseFloat(spli[1]);
			}

			extraData = null;

			if (ini.exists('extra')) {
				for (k => v in ini.extra) {
					if (k.contains(character)) {
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
			updateHitbox();
		} catch (e) {
			Log.print('alpabet fail : $e', 0xff3366);

			animation.addByPrefix('idle', '?', 24, true);
			animation.play('idle', true);
			updateHitbox();
		}
	}

	override public function updateHitbox() {
		super.updateHitbox();
		// offset.y doesnt work properly ???
		// y += letterOffset[1];
		offset.set(letterOffset[0], letterOffset[1]);
		origin.set(0, 0);
	}
}
