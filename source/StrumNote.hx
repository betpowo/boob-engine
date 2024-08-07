import Note.NoteHitState;
import flash.filters.BitmapFilter;
import flash.filters.BlurFilter;
import flixel.graphics.frames.FlxFilterFrames;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSignal.FlxTypedSignal;

class StrumNote extends Note
{
	public var strumRGB:RGBPalette = new RGBPalette();

	private var dumpRGB:RGBPalette = new RGBPalette();
	var blurSpr:Note;
	var holdSpr:FlxSprite = new FlxSprite();

	public var inputs:Array<FlxKey> = null;
	public var notes:Array<Note> = [];
	public var autoHit:Bool = false;
	public var blocked:Bool = false;
	public var hitWindow:Float = 123.0;

	public override function set_hit(v:NoteHitState):NoteHitState
	{
		return hit = NONE;
	}

	public function new(?noteData:Int = 2)
	{
		super(noteData);
		sustain = null;
		shader = strumRGB.shader;
		strumRGB.set(0x87a3ad, -1, 0);
		dumpRGB.set(FlxColor.interpolate(strumRGB.r, rgb.r, 0.3).getDarkened(0.15), -1, 0x201e31);
		blurSpr = new Note(noteData);
		blurSpr.shader = rgb.shader;
		blurSpr.blend = ADD;
		blurSpr.alpha = 0.75;
		blurSpr.visible = false;
		createFilterFrames(blurSpr, new BlurFilter(58, 58));

		holdSpr.frames = FlxAtlasFrames.fromSparrow('assets/hold.png', 'assets/hold.xml');
		holdSpr.animation.addByPrefix('start', 'start', 12, false);
		holdSpr.animation.addByPrefix('hold', 'hold', 24, true);
		holdSpr.animation.play('hold', true);
		holdSpr.updateHitbox();
		holdSpr.animation.finishCallback = function(a)
		{
			if (a == 'start')
				holdSpr.animation.play('hold', true);
		}
		holdSpr.shader = rgb.shader;
		holdSpr.visible = false;

		animation.addByIndices('confirm', 'idle', [0, 0, 0], '', 24, false);
		animation.addByIndices('press', 'idle', [0, 0, 0], '', 24, false);
		animation.callback = function(a, b, c)
		{
			if (a == 'confirm')
			{
				shader = strumRGB.shader;
				switch (b)
				{
					case 0:
						var mult = 1.15;
						scaleMult.set(mult, mult);
						blurSpr.visible = true;
						blurSpr.alphaMult = 1;
						blurSpr.colorTransform.redOffset = blurSpr.colorTransform.greenOffset = blurSpr.colorTransform.blueOffset = 30;
					case 1:
						blurSpr.colorTransform.redOffset = blurSpr.colorTransform.greenOffset = blurSpr.colorTransform.blueOffset = 0;
					case 2:
						var mult = 1.06;
						blurSpr.alphaMult = 0.75;
						scaleMult.set(mult, mult);
				}
			}
			else if (a == 'press')
			{
				shader = dumpRGB.shader;
				blurSpr.visible = false;
				switch (b)
				{
					case 0:
						var mult = 0.9;
						scaleMult.set(mult, mult);
					case 2:
						var mult = 0.95;
						scaleMult.set(mult, mult);
						blurSpr.alpha = 0.75;
				}
			}
			else
			{
				scaleMult.set(1, 1);
				blurSpr.visible = false;
				shader = strumRGB.shader;
			}
		}
		Conductor.stepHit.add(stepHit);
	}

	function createFilterFrames(sprite:FlxSprite, filter:BitmapFilter)
	{
		var filterFrames = FlxFilterFrames.fromFrames(sprite.frames, 64, 64, [filter]);
		updateFilter(sprite, filterFrames);
		return filterFrames;
	}

	function updateFilter(spr:FlxSprite, sprFilter:FlxFilterFrames)
	{
		sprFilter.applyToSprite(spr, false, true);
	}

	override function draw()
	{
		blurSpr.camera = holdSpr.camera = camera;
		blurSpr.shader = holdSpr.shader = (pressingNote ?? this).rgb.shader;
		if (visible && alpha > 0)
		{
			super.draw();
			if (blurSpr.visible && blurSpr.alpha >= 0)
				blurSpr.draw();

			if (holdSpr.visible && holdSpr.alpha >= 0)
			{
				holdSpr.x = getMidpoint().x - holdSpr.width * 0.5;
				holdSpr.y = getMidpoint().y - holdSpr.height * 0.5;
				holdSpr.centerOffsets();
				holdSpr.draw();
			}
		}
	}

	var confirmTime:Float = 0.0;
	var pressingNote:Note = null;
	var enableStepConfirm:Bool = false;

	public var noteHit:FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();
	public var noteHeld:FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();
	public var noteMiss:FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		blurSpr.setPosition(x, y);
		blurSpr.angle = angle;
		blurSpr.alpha = alpha;
		blurSpr.scale.copyFrom(scale);
		blurSpr.scaleMult.copyFrom(scaleMult);
		blurSpr.update(elapsed);
		holdSpr.update(elapsed);
		dumpRGB.r = FlxColor.interpolate(strumRGB.r, rgb.r, 0.3).getDarkened(0.15);

		if (inputs is Array && inputs != null)
		{
			for (note in notes)
			{
				// sustain notes
				if (Conductor.time >= note.strumTime + 300)
				{
					noteMiss.dispatch(note);
					note.kill();
				}
			}

			if (FlxG.keys.anyPressed(inputs) && !blocked)
			{
				for (note in notes)
				{
					// sustain notes
					if ((note.hit == HELD && note._shouldDoHit))
					{
						note._shouldDoHit = true;
						note.doHit();
						noteHeld.dispatch(note);

						if (note.hit != HIT)
							pressingNote = note;
						else
						{
							holdSpr.visible = false;
							enableStepConfirm = false;
						}
					}
				}
			}

			if (FlxG.keys.anyJustPressed(inputs) && !blocked)
			{
				for (note in notes)
				{
					// normal notes
					if (Math.abs(note.strumTime - Conductor.time) <= hitWindow && note.hit == NONE)
					{
						if (note.sustain.length > 60)
						{
							note._shouldDoHit = true;
							holdSpr.visible = true;
							holdSpr.animation.play('start', true);
							enableStepConfirm = true;
						}
						note.doHit();
						pressingNote = note;
						noteHit.dispatch(note);
					}
				}

				animation.play((pressingNote != null) ? 'confirm' : 'press', true);
			}

			if (FlxG.keys.anyJustReleased(inputs))
			{
				for (note in notes)
				{
					// sustain notes
					note._shouldDoHit = false;
				}

				holdSpr.visible = false;
				enableStepConfirm = false;

				pressingNote = null;
				animation.play('idle', true);
			}
		}
		else
		{
			if (autoHit)
			{
				for (note in notes)
				{
					if (note.strumTime <= Conductor.time)
					{
						if (note.hit != HIT)
						{
							if (note.hit == NONE)
							{
								animation.play('confirm', true);
								if (note.sustain.length > 60)
								{
									holdSpr.visible = true;
									holdSpr.animation.play('start', true);
								}
								else
								{
									noteHit.dispatch(note);
								}
							}

							confirmTime = 0.13;
							note._shouldDoHit = true;
							pressingNote = note;
							note.doHit();

							if (note.hit == HELD)
							{
								noteHeld.dispatch(note);
								enableStepConfirm = true;
							}
							else if (note.hit == HIT)
							{
								holdSpr.visible = false;
								enableStepConfirm = false;
							}
						}
					}
				}
				if (confirmTime > 0)
					confirmTime -= elapsed;
				else
				{
					animation.play('idle', true);
					confirmTime = 0;
					holdSpr.visible = false;
					enableStepConfirm = false;
				}
			}
		}
	}

	function stepHit()
	{
		if (enableStepConfirm)
		{
			animation.play('confirm', true);
			confirmTime = 0.13;
		}
	}
}
