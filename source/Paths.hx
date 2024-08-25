// hi this is recycled from a game i was making with some friends i coded it almost from scratch
package;

import flash.media.Sound;
import flixel.graphics.FlxGraphic;
import haxe.PosInfos;
import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import sys.FileSystem;
import sys.io.File;

using StringTools;

typedef Mod =
{
	name:String,
	enabled:Bool,
	global:Bool
}

class Paths
{
	private static var shitLoaded:Map<String, Any> = [];
	public static var modList:Array<Mod> = [];
	public static var mod:String;

	public static inline function initMods()
	{
		var dirList:Array<String> = FileSystem.readDirectory('mods/');
		if (dirList != null)
		{
			for (m in dirList)
			{
				if (FileSystem.isDirectory('mods/$m'))
					modList.push({name: m.toLowerCase(), enabled: true, global: false});
			}
		}
	}

	public static inline function getFirstMod():String
	{
		var m:String = '';
		for (i in modList)
		{
			if (i.enabled)
			{
				m = i.name;
				break;
			}
		}
		return m;
	}

	public static function file(f:String, ?pos:PosInfos):String
	{
		if (f.startsWith('/')) // blank root
			f = f.substring(1);

		var result = 'assets/$f';

		if (result.contains('assets/assets')) // ???
			result = result.replace('assets/assets', 'assets');

		if (FileSystem.exists('mods/$mod/$f'))
			result = 'mods/$mod/$f';

		// trace(result);
		// trace(pos);

		return result;
	}

	public static function exists(f:String):Bool
	{
		return FileSystem.exists(file(f));
	}

	public static var useGPU:Bool = true;

	public static function image(f:String, ?root:String = 'images'):FlxGraphic
	{
		var key:String = file('$root/$f.png');
		var mapKey:String = key;
		/*if (useGPU)
			mapKey += ':gpu'; */

		var g:FlxGraphic;
		if (FileSystem.exists(key) && !shitLoaded.exists(mapKey))
		{
			var b:BitmapData = BitmapData.fromFile(key);
			if (useGPU)
			{
				// from da psych engine cus im lazy
				var texture:RectangleTexture = FlxG.stage.context3D.createRectangleTexture(b.width, b.height, BGRA, true);
				texture.uploadFromBitmapData(b);
				b.image.data = null;
				b.dispose();
				b.disposeImage();
				b = BitmapData.fromTexture(texture);
			}
			g = FlxGraphic.fromBitmapData(b, false, key);
			g.persist = true;
			g.destroyOnNoUse = false;
			shitLoaded.set(mapKey, g);
		}
		if (shitLoaded.get(mapKey) != null)
			return shitLoaded.get(mapKey);
		trace('$key not found im gonna fucking kill mysel');
		return null;
	}

	public static function sparrow(f:String, ?root:String = 'images'):FlxAtlasFrames
	{
		var daXML = xml(f, root);

		if (exists(daXML))
			return FlxAtlasFrames.fromSparrow(image(f, root), File.getContent(daXML));

		return FlxAtlasFrames.fromSparrow(image(f, root), daXML);
	}

	public static function sound(f:String, ?root:String = 'sounds'):Sound
	{
		var br:String = file('$root/$f.ogg');
		if (!shitLoaded.exists(br))
			shitLoaded.set(br, Sound.fromFile(br));
		return shitLoaded.get(br);
	}

	public static function script(f:String, ?root:String = 'data/scripts'):String
		return file('$root/$f.hx');

	public static function xml(f:String, ?root:String = 'images'):String
		return file('$root/$f.xml');

	public static function song(sg:String, f:String = 'Inst', ?sub:String):Sound
	{
		if (sub == null)
			sub = '';
		else if (!sub.endsWith('/'))
			sub += '/';
		if (exists(file('songs/$sg/$sub/$f.ogg')))
			return sound(f, 'songs/$sg/$sub');
		return sound(f, 'songs/$sg');
	}
}
