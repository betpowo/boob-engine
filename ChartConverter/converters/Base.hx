package converters;

import haxe.Json;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import haxe.io.Encoding;
import haxe.io.Path;
import haxe.zip.Compress;
import haxe.zip.Uncompress;
import sys.io.File;
import Chart.ChartLane;
import Chart.ChartMetadata;
import Chart.ChartNote;
import Chart;

using StringTools;

class Base {
	public static function convert(_data:Array<String>) {
		print(ChartConverter.col2ansi(0x99ccff));
		print('\x1b[7m v-slice \x1b[27m initiating converter...');
		print('choose variation (blank = default):');
		Sys.print('\x1b[38;2;255;255;255m> ');
		var line = Sys.stdin().readLine().toString();
		if (!line.startsWith('-'))
			line = '-$line';
		Sys.print(ChartConverter.col2ansi(0x99ccee));

		_data = _data.filter((b) -> {
			var a = Path.withoutExtension(b);
			return a.endsWith(line);
		});

		print(_data.toString());

		var songName = Path.withoutDirectory(Path.withoutExtension(_data[0].replace('-chart', '').replace(line, '')));

		// -chart should always come first before -metadata !
		var data = Json.parse(File.getContent(_data[0]));
		var meta = Json.parse(File.getContent(_data[1]));

		// print(data);
		print('reading metadata...');
		print('');

		print('- adding bpm changes...');
		var metaResult:ChartMetadata = {};
		var bpmChanges:Array<{t:Float, bpm:Float}> = [];
		var lanes:Array<ChartLane> = [];
		for (i in (meta.timeChanges : Array<Dynamic>)) {
			bpmChanges.push({t: i.t, bpm: i.bpm});
		}
		bpmChanges.sort((a, b) -> {
			return Std.int(a.t - b.t);
		});

		print('- adding visual props (stage, characters...)');
		var playData:Dynamic = meta.playData;
		if (playData != null) {
			lanes.push({
				char: playData.opponent ?? 'dad',
				pos: 'opp',
				keys: 4,
				play: false
			});
			lanes.push({
				char: playData.player ?? 'bf',
				pos: 'plr',
				keys: 4,
				play: false
			});
			lanes.push({
				char: playData.girlfriend ?? 'gf',
				pos: 'spc',
				keys: 0,
			});
			metaResult.stage = playData.stage ?? 'stage';
		}

		print('finished!');
		print('');
		print('reading notes...');
		for (i in (Reflect.fields(data.notes) : Array<Dynamic>)) {
			var result:Chart = {notes: [], lanes: lanes, bpm: bpmChanges};
			var notesResult:Array<ChartNote> = [];

			print('\n  \x1b[7m ${i.toUpperCase()} \x1b[27m');

			print('placing notes...');
			for (bruh in (Reflect.field(data.notes, i) : Array<Dynamic>)) {
				notesResult.push({
					time: bruh.t,
					index: Std.int(bruh.d % 4),
					length: bruh.l,
					lane: (bruh.d < 4) ? 1 : 0
				});
			}
			print('- sorting notes...');
			notesResult.sort((a, b) -> {
				return Std.int(a.time - b.time);
			});

			print('- encoding notes...');

			var noteLength = notesResult.length - 1;
			for (idx => i in notesResult) {
				if (result.notes[i.lane] == null)
					result.notes[i.lane] = '';

				result.notes[i.lane] += '[${i.time},${i.index},${i.length}]';
				if (idx != noteLength)
					result.notes[i.lane] += '/';
			}

			print('finished! ($i)');
			for (idx => i in result.notes) {
				var compress = Compress.run(Bytes.ofString(i), 4);
				result.notes[idx] = Base64.encode(compress);
			}

			print(result);
		}

		print('');
		print('finished with the notes');

		print('\n  \x1b[7m done! ^w^ \x1b[0m ~');
		print('converted files placed in: \x1b[1m/bin/$songName/\x1b[0m\n');
	}

	static function print(input:Dynamic) {
		Sys.println('  $input');
	}
}
