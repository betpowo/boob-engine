// hi this is recycled from a game i was making with some friends i coded it almost from scratch
package util;

import flash.media.Sound;
import haxe.PosInfos;
import sys.FileSystem;
import sys.io.File;
import flixel.graphics.FlxGraphic;
import flixel.util.typeLimit.OneOfTwo;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import openfl.system.System;

using StringTools;

typedef Mod = {
	name:String,
	enabled:Bool,
	global:Bool
}

typedef FunkinAsset = OneOfTwo<FlxGraphic, Sound>;

class Paths {
	private static var assetsLoaded:Map<String, FunkinAsset> = [];
	private static var skipExclude:Array<String> = [];

	public static var modList:Array<Mod> = [];
	public static var mod:String;

	public static inline function initMods() {
		var dirList:Array<String> = FileSystem.readDirectory('mods/');
		if (dirList != null) {
			for (m in dirList) {
				if (FileSystem.isDirectory('mods/$m'))
					modList.push({name: m.toLowerCase(), enabled: true, global: false});
			}
		}
	}

	public static inline function getFirstMod():String {
		var m:String = '';
		for (i in modList) {
			if (i.enabled) {
				m = i.name;
				break;
			}
		}
		return m;
	}

	public static function file(f:String, ?pos:PosInfos):String {
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

	public static function read(folder:String):Array<String> {
		var fil:String = file(folder);
		if (FileSystem.isDirectory(fil))
			return FileSystem.readDirectory(fil);

		return [];
	}

	public static function exists(f:String):Bool {
		return FileSystem.exists(file(f));
	}

	public static var useGPU:Bool = true;

	public static function image(f:String, ?root:String = 'images', ?disableGPU:Bool = false):FlxGraphic {
		var key:String = file('$root/$f.png');
		var mapKey:String = key;
		/*if (useGPU)
			mapKey += ':gpu'; */

		var g:FlxGraphic;
		if (FileSystem.exists(key) && !assetsLoaded.exists(mapKey)) {
			var b:BitmapData = BitmapData.fromFile(key);
			#if !hl
			if (useGPU && !disableGPU) {
				// from da psych engine cus im lazy
				var texture:RectangleTexture = FlxG.stage.context3D.createRectangleTexture(b.width, b.height, BGRA, true);
				texture.uploadFromBitmapData(b);
				b.image.data = null;
				b.dispose();
				b.disposeImage();
				b = BitmapData.fromTexture(texture);
			}
			#end

			g = FlxGraphic.fromBitmapData(b, false, key);
			g.persist = true;
			g.destroyOnNoUse = false;
			Assets.cache.setBitmapData(mapKey, b);
			assetsLoaded.set(mapKey, g);
		}
		if (assetsLoaded.get(mapKey) != null)
			return assetsLoaded.get(mapKey);
		trace('$key not found im gonna fucking kill mysel');
		return null;
	}

	public static function sparrow(f:String, ?root:String = 'images'):FlxAtlasFrames {
		var daXML = xml(f, root);

		if (exists(daXML))
			return FlxAtlasFrames.fromSparrow(image(f, root), File.getContent(daXML));

		return FlxAtlasFrames.fromSparrow(image(f, root), daXML);
	}

	public static function ini(f:String, ?root:String = ''):String
		return file('$root/$f.ini');

	public static function font(f:String):String
		return file('fonts/$f');

	public static function script(f:String, ?root:String = 'data/scripts'):String
		return file('$root/$f.hx');

	public static function xml(f:String, ?root:String = 'images'):String
		return file('$root/$f.xml');

	public static function sound(f:String, ?root:String = 'sounds'):Sound {
		var br:String = file('$root/$f.ogg');
		if (!assetsLoaded.exists(br)) {
			var snd:Sound = Sound.fromFile(br);
			assetsLoaded.set(br, snd);
			Assets.cache.setSound(br, snd);
		}
		return assetsLoaded.get(br);
	}

	public static function song(sg:String, f:String = 'Inst', ?sub:String = ''):Sound {
		if (!sub.endsWith('/'))
			sub += '/';
		if (exists(file('songs/$sg/audio/$sub/$f.ogg')))
			return sound(f, 'songs/$sg/audio/$sub');
		return sound(f, 'songs/$sg/audio');
	}

	public static function exclude(s:String) {
		var fil = Paths.file(s);
		if (skipExclude.indexOf(fil) == -1)
			skipExclude.push(fil);
	}

	@:privateAccess
	public static function clear():Bool {
		for (key => val in assetsLoaded) {
			if (val != null && skipExclude.indexOf(key) != -1) {
				if (val is FlxGraphic) {
					@:privateAccess FlxG.bitmap._cache.remove(key);
					openfl.Assets.cache.removeBitmapData(key);

					var grah:FlxGraphic = val; // why
					grah.persist = false;
					grah.destroyOnNoUse = true;
					grah.destroy();
				}
				Assets.cache.clear(key);
				assetsLoaded.remove(key);
			}
		}
		System.gc();
		return true;
	}
}
