package song;

import haxe.crypto.Base64;
import haxe.io.Bytes;
import haxe.zip.Compress;
import haxe.zip.Uncompress;
import flixel.math.FlxMath;

@:structInit typedef Chart = {
	var bpm:Array<{t:Float, bpm:Float}>;
	var notes:Array<String>;
	var lanes:Array<ChartLane>;

	@:optional var stars:Int;
	@:optional var speed:Float;
	@:optional var meta:ChartMetadata;
}

@:structInit typedef ChartEvents = {
	?order:Array<String>,
	?events:Array<Dynamic>
}

@:structInit typedef ChartNote = {
	time:Float,
	index:Int,
	?length:Float,
	?lane:Int,
	?kind:String,
	?spawned:Bool
}

@:structInit typedef ChartLane = {
	?char:String,
	?pos:String,
	?keys:Int,
	?play:Bool,
	?visible:Bool,
	?strumPos:String,
	?vox:String
}

@:structInit typedef ChartMetadata = {
	?display:String,
	?stage:String,
	?color:Null<String>,
	?icon:String,
	?art:Null<String>,
	?music:Null<String>,
	?chart:Null<String>,
	?diff:Array<String>
}

class ChartParser {
	public static function parseNotes(notes:Array<String>):Array<ChartNote> {
		var result:Array<ChartNote> = [];

		for (idx => i in notes) {
			var dec = haxe.crypto.Base64.decode(i);
			var uncompress = haxe.zip.Uncompress.run(dec, 5);
			var res:Array<String> = uncompress.toString().split('/');

			for (j in res) {
				var ult:Array<String> = j.substr(1, j.length - 1).split(',');
				result.push({
					time: Std.parseFloat(ult[0] ?? '0'),
					index: Std.parseInt(ult[1] ?? '0'),
					length: Std.parseFloat(ult[2] ?? '0'),
					kind: ult[3],

					lane: idx
				});
			}
		}

		return result;
	}

	public static function encodeNotes(notes:Array<ChartNote>):Array<String> {
		var result = [];

		var noteLength = notes.length;
		for (idx => i in notes) {
			if (result[i.lane] == null)
				result[i.lane] = '';

			var laneNote:String = '${i.time},${i.index}';
			if (i.length >= 10)
				laneNote += ',${i.length}';

			if (i.kind != null) {
				if (i.length < 10)
					laneNote += ',0';

				laneNote += ',${i.kind}';
			}

			result[i.lane] += '[${laneNote}]';
			if (idx < noteLength)
				result[i.lane] += '/';
		}

		for (idx => i in result) {
			var compress = Compress.run(Bytes.ofString(i), 5);
			result[idx] = Base64.encode(compress);
		}
		return result;
	}
}

/*
	class ChartConverter {
	public static function convert(_data:String):Dynamic {
		var data:SwagSong = cast haxe.Json.parse(_data).song;
		var isv:Bool = false;

		if (data == null) {
			data = cast haxe.Json.parse(_data);
			isv = true;
		}

		var result:Chart = {notes: [], speed: 1, bpm: 60};
		for (bruh in data.notes) {
			if (data.generatedBy != null) {
				result.notes.push({
					time: bruh.t,
					index: Std.int(bruh.d % 4),
					length: bruh.l,
					lane: (bruh.d < 4) ? 1 : 0
				});
			} else {
				var idx:Int = 0;
				while (bruh.sectionNotes > idx) {
					var note = bruh.sectionNotes[idx];

					if (note[1] == -1)
						continue; // old psych event note

					var max = 4;
					var _ind = note[1];
					var _pla = bruh.mustHitSection;
					if (_ind >= max) {
						_pla = !_pla;
						_ind = _ind % max;
					}
					result.notes.push({
						time: note[0],
						index: _ind,
						length: note[2],
						lane: _pla ? 1 : 0
					});
					idx += 1;
				}
			}
		}
		result.speed = data.speed;
		result.bpm = data.bpm;
		return result;
	}
}*/
// old fnf classes cus haxe is dumb and stupid
typedef SwagSong = {
	var song:String;
	var notes:Array<Dynamic>;
	var bpm:Int;
	var needsVoices:Bool;
	var speed:Float;
	@:optional var generatedBy:String;
	var player1:String;
	var player2:String;
	var validScore:Bool;
}

typedef SwagSection = {
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var typeOfSection:Int;
	var mustHitSection:Bool;
	var bpm:Int;
	var changeBPM:Bool;
	var altAnim:Bool;
}
