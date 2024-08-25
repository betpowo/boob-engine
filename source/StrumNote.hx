import Note.NoteHitState;
import flash.filters.BitmapFilter;
import flash.filters.BlurFilter;
import flixel.VaryingSprite;
import flixel.graphics.frames.FlxFilterFrames;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSignal.FlxTypedSignal;

typedef StrumNoteSignal = FlxTypedSignal<Note->Void>;

class StrumNote extends Note
{
	public var strumRGB:RGBPalette = new RGBPalette();

	private var dumpRGB:RGBPalette = new RGBPalette();
	var blurSpr:VaryingSprite;
	var holdSpr:FlxSprite;

	public var parentLane:StrumLine = null;
	public var inputs:Array<FlxKey> = null;
	public var notes:Array<Note> = [];
	public var autoHit:Bool = false;
	public var blocked:Bool = false;
	public var hitWindow:Float = 123.0;

	public override function set_hit(v:NoteHitState):NoteHitState
	{
		return hit = NONE;
	}

	public function new(?strumIndex:Int = 2)
	{
		super(strumIndex);
		sustain = null;
		shader = strumRGB.shader;
		strumRGB.set(0x87a3ad, -1, 0);
		dumpRGB.set(FlxColor.interpolate(strumRGB.r, rgb.r, 0.3).getDarkened(0.15), -1, 0x201e31);

		blurSpr = new VaryingSprite();
		blurSpr.frames = Paths.sparrow('ui/note');
		blurSpr.animation.addByPrefix('idle', 'blur', 24, true);
		blurSpr.animation.play('idle', true);
		blurSpr.updateHitbox();
		blurSpr.shader = rgb.shader;
		blurSpr.blend = ADD;
		blurSpr.visible = false;

		holdSpr = new FlxSprite();
		holdSpr.frames = Paths.sparrow('ui/holdEffect');
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
						blurSpr.colorTransform.redOffset = 50;
						blurSpr.colorTransform.greenOffset = blurSpr.colorTransform.blueOffset = -50;
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

	override function draw()
	{
		blurSpr.camera = holdSpr.camera = camera;
		blurSpr.shader = holdSpr.shader = (pressingNote ?? this).rgb.shader;
		if (visible && alpha > 0)
		{
			super.draw();
			if (blurSpr.visible && blurSpr.alpha >= 0)
			{
				blurSpr.x = getMidpoint().x - blurSpr.width * 0.5;
				blurSpr.y = getMidpoint().y - blurSpr.height * 0.5;
				blurSpr.centerOffsets();
				blurSpr.draw();
			}

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

	public var noteHit:StrumNoteSignal = new StrumNoteSignal();
	public var noteHeld:StrumNoteSignal = new StrumNoteSignal();
	public var noteHeldStep:StrumNoteSignal = new StrumNoteSignal();
	public var noteMiss:StrumNoteSignal = new StrumNoteSignal();

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		blurSpr.setPosition(x, y);
		blurSpr.angle = angle;
		blurSpr.angleOffset = angleOffset;
		blurSpr.alpha = alpha;
		blurSpr.scale.copyFrom(scale);
		blurSpr.updateHitbox();
		blurSpr.scaleMult.copyFrom(scaleMult);
		blurSpr.update(elapsed);
		holdSpr.update(elapsed);
		dumpRGB.r = FlxColor.interpolate(strumRGB.r, rgb.r, 0.3).getDarkened(0.15);

		if (inputs is Array && inputs != null)
		{
			for (note in notes)
			{
				// misses
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
						{
							pressingNote = note;
							holdSpr.angle = note.totalAngle;
						}
						else
						{
							holdSpr.visible = false;
							holdSpr.angle = 0;
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
							holdSpr.angle = note.totalAngle;
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
									holdSpr.angle = note.totalAngle;
								}
								noteHit.dispatch(note);
							}

							confirmTime = 0.13;
							note._shouldDoHit = true;
							pressingNote = note;
							note.doHit();

							if (note.hit == HELD)
							{
								enableStepConfirm = true;
								confirmTime = Conductor.stepCrochet;
								noteHeld.dispatch(note);
							}
							else if (note.hit == HIT)
							{
								holdSpr.visible = false;
								enableStepConfirm = false;
								confirmTime = 0.13;
								holdSpr.angle = 0;
							}
						}
					}
				}
				if (confirmTime > 0)
					confirmTime -= elapsed;
				else if (confirmTime != -1)
				{
					animation.play('idle', true);
					confirmTime = -1;
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
			confirmTime = Conductor.stepCrochet;
			noteHeldStep.dispatch(pressingNote);
			// Log.print('yo', 0x00ffff);
		}
	}
}
