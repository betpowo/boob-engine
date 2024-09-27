import sys.FileSystem;

using StringTools;

class ChartConverter {
	public static function col2ansi(?color:Int):String {
		if (color != null) {
			var red:Int = (color >> 16) & 0xff;
			var green:Int = (color >> 8) & 0xff;
			var blue:Int = color & 0xff;
			return '\x1b[38;2;$red;$green;${blue}m';
		}
		return '\x1b[0m';
	}

	static function main() {
		printLogo(0x33cccc);
		var args = Sys.args().map((a) -> {
			return a.replace('-', '');
		});
		if (!args.contains('round')) {
			print(col2ansi(0xcc00cc));
			print('TIP: did you know you can round millisecond timestamps?');
			print('type "chartconverter.bat --round" instead!');
			print('smaller encoded note string, at the cost of sliiight desync.');
			print(col2ansi(null));
		}
		// print(Std.string(roundDecimal(10.5432726942, 3)));
		// print(Sys.args().toString());
		print('choose chart directory / folder (FOLDER, not file):');
		Sys.print('\x1b[38;2;255;255;255m> ');
		var line = Sys.stdin().readLine().toString();
		Sys.print('\x1b[0m');
		/*switch (Sys.systemName()) {
			case 'Linux': */
		line = line.replace('\\', '/');
		/*case 'Windows':
			line = line.replace('/', '\\');
		}*/
		print('reading $line...\n');
		var content = FileSystem.readDirectory(line);
		print(FileSystem.absolutePath(line));
		print(content.toString());
		print('');
		converters.Base.convert(content.map((a) -> {
			return FileSystem.absolutePath(line) + '/$a';
		}), args);
	}

	static function print(input:String) {
		Sys.println('  $input');
	}

	public static function roundDecimal(v:Float, ?d:Int = 2):Float {
		return Math.round(v * Math.pow(10, d)) / Math.pow(10, d);
	}

	static function printLogo(color:Int) {
		for (i in [
			'',
			'   ___         __                              __         ',
			'  / _/__ _____/ /_  _______  ___ _  _____ ____/ /________ ',
			' / _/ _ `/ __/ __/ / __/ _ \\/ _ \\ |/ / -_) __/ __/ __/ -_)',
			'/_/ \\_,_/_/  \\__/  \\__/\\___/_//_/___/\\__/_/  \\__/_/  \\__/ ',
			'',
			"converts your charts from some formats to boob engine's",
			'chart format, kinda wip just to let you know',
			'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~',
			''
		]) {
			print('${col2ansi(color)}$i');
		}
		Sys.print('\x1b[0m');
	}
}
