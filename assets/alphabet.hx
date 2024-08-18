function doFilter(input:String)
{
	if (StringTools.startsWith(input, '!')) // special character
	{
		input = input.substr(1, input.length);
		input = getTrueChar(input);
	}
	// stringtools.contains doesnt work
	if (StringTools.startsWith(input, '_') || StringTools.endsWith(input, '_')) // lowercase letter or number
	{
		input = StringTools.replace(input, '_', '');
	}
	return input;
}

function getTrueChar(input:String)
{
	var map = [
		'at' => '@',
		'accent' => '´', // only now im realizing its acute
		'amp' => '&',
		'arrow' => '↑',
		'bs' => 'ß',
		'comma' => ',',
		'dollar' => '$',
		'period' => '.',
		'iforgor' => '^', // circumflex
		'exclam' => '!',
		'question' => '?',
		'Oslash' => 'Ø',
		'oslash' => 'ø',
		'slash' => '/',
		'heart' => '❤',
		'angryfaic' => '😠',
		'dieresis' => '¨',
		'curl' => '¸', // cedilla
		'plus' => '+',
		'minus' => '-',
		'parenthesis' => '(',
		'squarebr' => '[',
		'curlybr' => '{',
		'tilde' => '~'
	];
	if (map.exists(input))
		input = map.get(input);

	return input;
}

var transforms = [
	'fgpqy' => [0, 7], 'mnñost' => [0, -3], 'j' => [0, 12], '!?' => [0, -20], '¡¿' => [0, 0, 180], ',;_' => [0, 5], '-*' => [0, -16], '+' => [0, -6],
	')]}' => [0, 0, 0, 'xy'], '\\' => [0, 0, 0, 'x']];

var replace = [
	'ÁÂĀĄÄÃÀĂ' => 'A',
	'ÉÊĚËĒĖĘÈ' => 'E',
	'ÍÌÏĨİĬĮÎĪ' => 'I',
	'ÓÒŎŐÔŌÖÕ' => 'O',
	'ÚÜÙÛŨŪŮŲ' => 'U',
	////////////////////
	'áàäâăāąãå' => 'a',
	'éèėêëěę' => 'e',
	'íìïĩĭîīį' => 'i',
	'óòŏôōöõõ' => 'o',
	'úùüŭûūũůų' => 'u',
	////////////////////
	'Ç' => 'C',
	'ç' => 'c',
	'Ñ' => 'N',
	'ñ' => 'n',
	'Ş' => 'S',
	'ş' => 's',
	'ÝŶŸ' => 'Y',
	'ýŷÿ' => 'y',
	'ŻŹŽ' => 'Z',
	'żźžʐ' => 'z',
	////////////////////
	'¡' => '!',
	'¿' => '?',
	':' => '.',
	';' => ',',
	'_' => '-',
	')' => '(',
	']' => '[',
	'}' => '{',
	'\\' => '/'
];

var extraChars = [
	'i' => {char: '.', x: -2, y: -20},
	'j' => {char: '.', x: 18, y: -20},
	':;' => {char: '.', x: 0, y: -20},
	'!?' => {char: '.', x: 4, y: 50},
	'ÁÉÍÓÚÝŹáéíóúýź' => {char: '´', x: 20, y: -20},
	'ÀÈÌÒÙàèìòù' => {
		char: '´',
		x: 20,
		y: -20,
		flip: 'x'
	},
	'ĄÇĘĮŲŞąçęįųş' => {
		char: '¸',
		x: 16,
		y: 30
	},
	'Ñ' => {char: '~', x: 2, y: -20},
	'ñ' => {char: '~', x: -4, y: -20}
];

var extraCharAdd = ['íìï' => [-20, 0]];

function getFromMap(map, key)
{
	for (idx in map.keys())
	{
		var i = map.get(idx);
		var spli = idx.split('');
		if (spli.contains(key))
		{
			return i;
		}
	}
	return null;
}

function onDraw(l:String)
{
	var result = {
		char: l,
		x: 0,
		y: 0,
		flip: 'none',
		angle: 0,
		extra: null
	}

	var offs = getFromMap(transforms, l);
	var repl = getFromMap(replace, l);
	var xtra = getFromMap(extraChars, l);
	var xtof = getFromMap(extraChars, l);

	if (offs != null)
	{
		result.x = offs[0];
		result.y = offs[1];
		if (offs[2] != null)
			result.angle = offs[2];

		if (offs[3] != null)
			result.flip = offs[3];
	}
	if (repl != null)
		result.char = repl;

	if (xtra != null)
	{
		result.extra = xtra;
		if (xtof != null)
		{
			result.extra.x += xtof[0];
			result.extra.y += xtof[1];
		}
	}

	return result;
}
