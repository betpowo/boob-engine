import flixel.math.FlxMath;

typedef Chart =
{
	var bpm:Float;
	var notes:Array<ChartNote>;
	var speed:Float;
}

typedef ChartNote =
{
	time:Float,
	index:Int,
	?length:Float,
	?lane:Int,
	?spawned:Bool // for playstate
}

class ChartConverter
{
	public static function convert(_data:String):Dynamic
	{
		var data:SwagSong = cast haxe.Json.parse(_data).song;
		var isv:Bool = false;

		if (data == null)
		{
			data = cast haxe.Json.parse(_data);
			isv = true;
		}

		var result:Chart = {notes: [], speed: 1, bpm: 60};
		for (bruh in data.notes)
		{
			if (data.generatedBy != null)
			{
				result.notes.push({
					time: bruh.t,
					index: Std.int(bruh.d % 4),
					length: bruh.l,
					lane: (bruh.d < 4) ? 1 : 0
				});
			}
			else
			{
				var idx:Int = 0;
				while (bruh.sectionNotes > idx)
				{
					var note = bruh.sectionNotes[idx];

					if (note[1] == -1)
						continue; // old psych event note

					var max = 4;
					var _ind = note[1];
					var _pla = bruh.mustHitSection;
					if (_ind >= max)
					{
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
}

// old fnf classes cus haxe is dumb and stupid
typedef SwagSong =
{
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

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var typeOfSection:Int;
	var mustHitSection:Bool;
	var bpm:Int;
	var changeBPM:Bool;
	var altAnim:Bool;
}
