package converters;

import haxe.Json;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import haxe.io.Encoding;
import haxe.io.Path;
import haxe.zip.Compress;
import haxe.zip.Uncompress;
import sys.FileSystem;
import sys.io.File;
import Chart.ChartEvents;
import Chart.ChartLane;
import Chart.ChartMetadata;
import Chart.ChartNote;
import Chart;

using StringTools;

class Base {
	static var args:Array<String> = [];

	public static function convert(_data:Array<String>, ?a:Array<String>) {
		args = a;
		print(ChartConverter.col2ansi(0x99ccff));
		print('\x1b[7m v-slice \x1b[27m initiating converter...');
		print('choose variation (blank = default):');
		Sys.print('\x1b[38;2;255;255;255m> ');
		var line = Sys.stdin().readLine().toString();
		var isVariation:Bool = false;
		// none
		if (line.length < 1) {
			line = '';
		} else if (!line.startsWith('-')) {
			line = '-$line';
			isVariation = true;
		}
		Sys.print(ChartConverter.col2ansi(0x99ccee));

		_data = _data.filter((b) -> {
			var a = Path.withoutExtension(b);
			if (line.length > 1)
				return a.endsWith(line);
			return a.endsWith('-chart') || a.endsWith('-metadata');
		});

		print(_data.toString());

		var songName = Path.withoutDirectory(Path.withoutExtension(_data[0].replace('-chart', '').replace(line, '')));

		// -chart should always come first before -metadata !
		var data = Json.parse(File.getContent(_data[0]));
		var meta = Json.parse(File.getContent(_data[1]));
		var events:ChartEvents = {};

		// print(data);
		print('reading metadata...');
		print('');

		print('- adding bpm changes...');
		var metaResult:ChartMetadata = {diff: []};
		var starsMap:Map<String, Int> = [];
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
				char: playData.characters.player ?? 'bf',
				pos: 'plr',
				keys: 4,
				play: true,
				strumPos: 'right',
				vox: 'plr'
			});
			lanes.push({
				char: playData.characters.opponent ?? 'dad',
				pos: 'opp',
				keys: 4,
				play: false,
				strumPos: 'left',
				vox: 'opp'
			});
			lanes.push({
				char: playData.characters.girlfriend ?? 'gf',
				pos: 'spc',
				keys: 0,
				visible: false,
				strumPos: 'center'
			});
			metaResult.stage = playData.stage ?? 'stage';
			for (i in Reflect.fields(playData.ratings)) {
				starsMap.set(i, Reflect.field(playData.ratings, i));
			}

			metaResult.display = meta.songName;
			metaResult.music = meta.artist;
			metaResult.chart = meta.charter;

			// vro
			metaResult.icon = lanes[1].char.split('-')[0];
		}

		print('finished!');
		print('');
		events = convertEvents(data);
		print('');
		print('reading notes...');

		var allCharts:Map<String, Dynamic> = [];

		for (i in (Reflect.fields(data.notes) : Array<Dynamic>)) {
			// might need to manually edit this since i dont think it will automatically
			// give you the easy normal hard order so
			metaResult.diff.push(Std.string(i));
			var result:Chart = {
				stars: starsMap.get(i),
				speed: 1,
				bpm: bpmChanges,
				lanes: lanes,
				notes: []
			};
			var notesResult:Array<ChartNote> = [];

			result.speed = Reflect.field(data.scrollSpeed, i);

			print('\n  \x1b[7m ${i.toUpperCase()} \x1b[27m');

			print('placing notes...');
			for (bruh in (Reflect.field(data.notes, i) : Array<Dynamic>)) {
				if (args.contains('round')) {
					if (bruh.t != null)
						bruh.t = ChartConverter.roundDecimal(bruh.t, 2);
					if (bruh.l != null)
						bruh.l = ChartConverter.roundDecimal(bruh.l, 2);
				}
				// print(bruh);
				notesResult.push({
					time: bruh.t,
					index: Std.int(bruh.d % 4),
					length: bruh.l,
					lane: (bruh.d < 4) ? 0 : 1,
					kind: bruh.k ?? null
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

				var laneNote:String = '${i.time},${i.index}';
				if (i.length >= 10)
					laneNote += ',${i.length}';

				if (i.kind != null) {
					if (i.length < 10)
						laneNote += ',0';

					laneNote += ',${i.kind}';
				}

				result.notes[i.lane] += '[${laneNote}]';
				if (idx < noteLength)
					result.notes[i.lane] += '/';
			}

			print('finished! ($i)');

			for (idx => i in result.notes) {
				var compress = Compress.run(Bytes.ofString(i), 5);
				result.notes[idx] = Base64.encode(compress);
				if (args.contains('debug'))
					print('notes length for $idx : ${result.notes[idx].length}');

				if (args.contains('decomptest')) {
					print(ChartConverter.col2ansi(0xff0000));
					print('DECOMPRESSION TEST !');
					var dec = Base64.decode(result.notes[idx]);
					print('dec : ${dec.getString(0, dec.length)}');
					var uncompress = Uncompress.run(dec, 5);
					print('uncompress : ${uncompress.toString()}');
					print(ChartConverter.col2ansi(0x99ccff));
				}
			}
			if (args.contains('debug')) {
				print(result);
			}

			allCharts.set(i, result);
		}

		var varName = '';
		if (isVariation)
			varName = line.substr(1, line.length);

		saveFiles(songName, varName, allCharts, metaResult, events);

		print('\n  \x1b[7m done! ^w^ \x1b[0m ~');
		print('converted files placed in: \x1b[1m/bin/$songName/${isVariation ? ' ($varName)' : ''}\x1b[0m\n');
	}

	static function saveFiles(song:String, va:String, allCharts:Map<String, Dynamic>, metaResult:ChartMetadata, events:ChartEvents) {
		print('SAVING FILES OMG !!!');
		var dir = '';
		if (va.length > 0 && !va.startsWith('/'))
			dir = '/$va';
		if (!FileSystem.exists('bin/$song'))
			FileSystem.createDirectory('bin/$song');

		for (idx => i in allCharts) {
			if (!FileSystem.exists('bin/$song/charts$dir'))
				FileSystem.createDirectory('bin/$song/charts$dir');

			File.saveContent('bin/$song/charts$dir/$idx.json', Json.stringify(i, null, '\t'));
		}
		File.saveContent('bin/$song/meta${va.length > 0 ? '-' : ''}$va.json', Json.stringify(metaResult, null, '\t'));

		if (!FileSystem.exists('bin/$song/events'))
			FileSystem.createDirectory('bin/$song/events');

		File.saveContent('bin/$song/events/events${va.length > 0 ? '-' : ''}$va.json', Json.stringify(events, null, '\t'));
	}

	static function convertEvents(data:Dynamic):{order:Array<String>, events:Array<Dynamic>} {
		var result = {
			order: [],
			events: []
		}

		print('reading events...');
		var index = -1;
		for (i in (data.events : Array<Dynamic>)) {
			if (!result.order.contains(i.e)) {
				index = result.order.push(i.e) - 1;
				result.events[index] = [];
			}

			index = result.order.indexOf(i.e);

			if (i.v != null)
				result.events[index].push([i.t, 0, i.v]);
		}
		print('finished!');
		if (args.contains('debug'))
			print(result);

		return result;
	}

	static function print(input:Dynamic) {
		Sys.println('  ${Std.string(input)}');
	}
}
