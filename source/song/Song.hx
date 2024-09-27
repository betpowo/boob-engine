package song;

import haxe.Json;
import sys.io.File;
import song.Chart.ChartEvents;
import song.Chart.ChartMetadata;
import song.Chart.ChartNote;
import song.Chart.ChartParser;

class Song {
	public static var song:String = 'test';
	public static var difficulty:String = 'normal';
	public static var variation:String = null;

	static final DEFAULT_CHART:Chart = {
		stars: 0,
		speed: 1,
		lanes: [
			{
				char: 'bf',
				pos: 'plr',
				keys: 4,
				visible: true,
				strumPos: 'center',
				vox: null,
				play: true
			}
		],
		notes: [''],
		bpm: [{t: 0, bpm: 60}]
	};

	static final DEFAULT_META:ChartMetadata = {
		display: 'unknown',
		icon: null,
		stage: 'stage',
		diff: ['normal']
	};

	static final DEFAULT_EVENTS:ChartEvents = {
		order: [],
		events: []
	}

	public static var chart:Chart = DEFAULT_CHART;
	public static var meta:ChartMetadata = DEFAULT_META;
	public static var events:ChartEvents = DEFAULT_EVENTS;

	public static var parsedNotes:Array<ChartNote> = [];

	public static function load(song:String, ?diff:String, ?vari:String) {
		Song.song = song;
		difficulty = diff ?? 'normal';
		variation = vari;

		chart = parse(song, difficulty, variation);
		meta = parseMeta(song, variation);
		events = parseEvents(song, variation);

		return true;
	}

	static function parse(song:String, ?diff:String, ?vari:String):Chart {
		var result:Chart = DEFAULT_CHART;

		final songLocation:String = Paths.file('songs/$song');

		var data = Json.parse(File.getContent(songLocation + '/charts' + (vari != null ? '/$vari' : '') + '/$diff.json'));
		result = data ?? result;

		parsedNotes = ChartParser.parseNotes(result.notes);

		return result;
	}

	static function parseMeta(song:String, ?vari:String):ChartMetadata {
		var result:ChartMetadata = DEFAULT_META;

		final songLocation:String = Paths.file('songs/$song');

		var data = Json.parse(File.getContent(songLocation + '/meta' + (vari != null ? '-$vari' : '') + '.json'));
		result = data ?? result;
		return result;
	}

	static function parseEvents(song:String, ?vari:String):ChartEvents {
		var result:ChartEvents = DEFAULT_EVENTS;

		final songLocation:String = Paths.file('songs/$song');

		var data = Json.parse(File.getContent(songLocation + '/events' + (vari != null ? '-$vari' : '') + '.json'));
		result = data ?? result;
		return result;
	}
}
