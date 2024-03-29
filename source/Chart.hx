typedef Chart =
{
	var bpm:Float;
	var notes:Array<ChartNote>;
	var speed:Float;
}

typedef ChartNote =
{
	strumTime:Float,
	index:Int,
	?length:Float,
	?isPlayer:Bool
}

class ChartConverter
{
	public static function convert(_data:String):Dynamic
	{
		var data:SwagSong = cast haxe.Json.parse(_data).song;
		var result:Chart = {notes: [], speed: 1, bpm: 60};
		for (bruh in data.notes)
		{
			for (note in bruh.sectionNotes)
			{
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
					strumTime: note[0],
					index: _ind,
					length: note[2],
					isPlayer: _pla
				});
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
	var notes:Array<SwagSection>;
	var bpm:Int;
	var needsVoices:Bool;
	var speed:Float;

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
