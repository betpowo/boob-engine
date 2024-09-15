package states;

import flixel.FlxSpriteExt;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import objects.ui.Counter;
import objects.ui.FreeplayCapsule;

class FreeplayState extends FlxState {
	var capsuleGrp:FlxTypedSpriteGroup<FreeplayCapsule> = new FlxTypedSpriteGroup<FreeplayCapsule>();
	var scoreNum:Counter = new Counter();

	override function create() {
		super.create();
		bgColor = 0xff999999;
		add(capsuleGrp);

		var list:Array<{
			name:String,
			color:FlxColor,
			diff:Int,
			?icon:String
		}> = [
			{
				name: 'THE CUM SONG',
				color: 0xffffff,
				diff: 99,
				icon: 'gf'
			},
			{name: 'Pico (Pico Mix)', color: 0xff9933, diff: 7},
			{name: 'THE OTHER CUM SONG', color: 0x6600ff, diff: 9},
			{
				name: 'EVIL capsule..,,',
				color: 0xff0000,
				diff: 66,
				icon: 'dad'
			},
			{name: 'iGottaAddScrollingBruh', color: 0x33cc99, diff: 1},
			{name: 'dude', color: 0x996666, diff: 0},
			{
				name: null,
				color: 0xaaeeff,
				diff: 0,
				icon: 'bf'
			}
			];
		for (idx => i in list) {
			var cap = addCapsule(i.name, i.color, i.diff);

			if (i.icon != null) {
				cap.icon = new FlxSpriteExt();
				cap.icon.frames = Paths.sparrow('menus/freeplay/icons/${i.icon}');
				cap.icon.animation.addByPrefix('idle', 'idle', 24, true);
				cap.icon.animation.play('idle', true);
				cap.icon.updateHitbox();
				cap.icon.scaleMult.set(3, 3);
				cap.icon.setPosition((cap.icon.frameWidth * -0.5) + 10, (cap.icon.frameHeight * -0.5) + 50);
				cap.add(cap.icon);
			}
		}

		capsuleGrp.setPosition((FlxG.width * 0.5) - 20, (FlxG.height * .5) - 70);

		var black = new FlxSprite().makeGraphic(1, 1, -1);
		black.setGraphicSize(FlxG.width, 90);
		black.color = 0x000000;
		black.updateHitbox();
		add(black);

		scoreNum.alignment = RIGHT;
		scoreNum.setPosition(FlxG.width - 20, 20);
		scoreNum.setGraphicSize(-1, 50);
		scoreNum.updateHitbox();
		add(scoreNum);

		changeSelection(0);
	}

	function addCapsule(?name:String, ?col:Int, ?diff:Int) {
		var cap = capsuleGrp.recycle(FreeplayCapsule);
		cap.text = name ?? 'FreeplayCapsule';
		cap.color = col ?? 0xaaeeff;
		cap.difficulty = diff ?? 0;
		cap.ID = capsuleGrp.members.length - 1;
		capsuleGrp.add(cap);

		/*
			cap.offset.x = FlxG.width * -1;
			FlxTween.tween(cap.offset, {x: 30}, 0.3, {
				startDelay: (cap.ID * 0.2),
				ease: FlxEase.sineIn,
				onComplete: (_) -> {
					var bounce = FlxTween.tween(cap.offset, {x: 0}, 1, {
						startDelay: 0.01,
						ease: FlxEase.backOut
					});

					switch (FlxG.random.int(1, 3) - 1) {
						case 0:
							FlxTween.tween(cap, {angle: FlxG.random.float(-1, -6)}, 0.1, {
								startDelay: 0.01,
								ease: FlxEase.sineOut,
								onComplete: (_) -> {
									FlxTween.tween(cap, {angle: 0}, 1, {
										ease: FlxEase.bounceOut
									});
								}
							});
						case 1:
							bounce.cancel();
							FlxTween.tween(cap.offset, {x: -60}, 0.3, {
								startDelay: 0.02,
								ease: FlxEase.sineOut,
								onComplete: (_) -> {
									FlxTween.tween(cap.offset, {x: 0}, 1, {
										ease: FlxEase.bounceOut
									});
								}
							});
						default:
							cap.scale.set(0.4, 1.2);

							cap.offset.y = 5;
							FlxTween.tween(cap.offset, {y: 0}, 1, {
								startDelay: 0.01,
								ease: FlxEase.backOut
							});

							FlxTween.tween(cap.scale, {x: 1, y: 1}, 0.5, {
								ease: FlxEase.expoOut
							});
					}
				}
			});
		 */

		return cap;
	}

	var curSelected:Int = 0;
	var curSelectedLerp:Float = 0;

	override function update(elapsed) {
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE) {
			FlxG.switchState(new states.TitleState());
		}

		if (FlxG.keys.justPressed.UP)
			changeSelection(-1);

		if (FlxG.keys.justPressed.DOWN)
			changeSelection(1);

		curSelectedLerp = FlxMath.lerp(curSelectedLerp, curSelected, elapsed * 13);

		for (i in capsuleGrp.members) {
			var sel = i.ID - curSelectedLerp;
			i.x = capsuleGrp.x + ((sel * sel * -1) * 30);
			i.y = capsuleGrp.y + (sel * 150);
		}

		scoreNum.number = FlxG.game.ticks;
	}

	function changeSelection(huh) {
		curSelected += huh;
		curSelected = FlxMath.wrap(curSelected, 0, capsuleGrp.members.length - 1);
		FlxG.sound.play(Paths.sound('ui/scroll'));

		// i Do not wanna add defaultColor property
		@:privateAccess
		for (i in capsuleGrp.members) {
			i.moves = false;
			if (i.drag.x == 0)
				i.drag.x = (i.color : Int);
			var sel = i.ID - curSelected;
			var col = new FlxColor(Std.int(i.drag.x));
			if (sel != 0) {
				col.brightness *= 0.8;
				col.saturation *= 2;
				col.blueFloat *= 1.1;
				col.greenFloat *= 0.9;
			}
			i.color = col;
			i.frontGlow.visible = sel == 0;
			i.textObj.alpha = sel == 0 ? 1 : 0.8;
		}
	}
}
