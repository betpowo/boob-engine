package states;

import haxe.Json;
import sys.io.File;
import flixel.FlxSpriteExt;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import objects.ui.Counter;
import objects.ui.FreeplayCapsule;
import util.RGBPalette;

class FreeplayState extends FlxState {
	var capsuleGrp:FlxTypedSpriteGroup<FreeplayCapsule> = new FlxTypedSpriteGroup<FreeplayCapsule>();
	var scoreNum:Counter = new Counter();
	var list:Array<{
		?name:String,
		?color:FlxColor,
		?diff:Int,
		?icon:String
	}> = [{name: 'Random!', color: 0xcc6666}];
	var randomCapsule:FreeplayCapsule;
	var arrows:Array<FlxSprite> = [new FlxSprite(), new FlxSprite()];
	var diffSprite:FlxSpriteExt = new FlxSpriteExt();

	override function create() {
		super.create();
		bgColor = 0xff999999;
		add(capsuleGrp);

		var grah = Paths.read('data/levels');

		for (i in grah) {
			var json = Json.parse(File.getContent(Paths.file('data/levels/$i')));
			for (s in (json.songs : Array<String>)) {
				if (Paths.exists('songs/$s/meta.json')) {
					var json = Json.parse(File.getContent(Paths.file('songs/$s/meta.json')));
					list.push({
						name: json?.display ?? s,
						color: FlxColor.fromString(json?.color) ?? 0xaaeeff,
						icon: json?.icon ?? null
					});
				} else {
					list.push({
						name: s,
						color: 0xaaeeff,
						diff: 0
					});
				}
				songArray.push(s);
			}
		}

		for (idx => i in list) {
			var cap = addCapsule(i.name, i.color, i.diff);

			if (i.icon != null) {
				cap.icon = cast cap.recycle(FlxSpriteExt);
				cap.icon.frames = Paths.sparrow('menus/freeplay/icons/${i.icon}');
				cap.icon.animation.addByPrefix('idle', 'idle', 12, true);
				cap.icon.animation.addByPrefix('confirm', 'confirm0', 12, false);
				cap.icon.animation.addByPrefix('confirm-hold', 'confirm-hold', 12, true);
				cap.icon.animation.play('idle', true);
				cap.icon.updateHitbox();
				cap.icon.scaleMult.set(3, 3);
				cap.icon.setPosition((cap.icon.frameWidth * -0.5), (cap.icon.frameHeight * -0.5) + 40);
				cap.add(cap.icon);
			}

			if (cap.ID < 6)
				doCapsuleAnim(cap);
		}

		randomCapsule = capsuleGrp.members[0];
		@:privateAccess randomCapsule._diffGroup.visible = false;

		capsuleGrp.setPosition((FlxG.width * .5) - 10, (FlxG.height * .5) - 50);

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

		var shader = new RGBPalette();

		for (i in arrows) {
			i.frames = Paths.sparrow('menus/freeplay/arrow');
			i.animation.addByPrefix('idle', 'arrow pointer loop', 24, true);
			i.animation.play('idle');
			i.updateHitbox();
			i.shader = shader.shader;
			add(i);
		}

		shader.set(0x16abfe, 0xaaffff, 0x000000);
		arrows[0].setPosition(10, 100);
		arrows[1].setPosition(333, 100);
		arrows[1].flipX = true;

		// graphic and position setup is automatically handled by changeDiff
		diffSprite.setPosition(FlxMath.lerp(arrows[0].getMidpoint().x, arrows[1].getMidpoint().x, 0.5), arrows[0].getMidpoint().y);
		diffSprite.antialiasing = true;
		add(diffSprite);

		FlxG.sound.playMusic(Paths.sound('freeplayRandom', 'music'));

		changeSelection(0);
		changeDiff(0);
	}

	function addCapsule(?name:String, ?col:Int, ?diff:Int) {
		var cap = capsuleGrp.recycle(FreeplayCapsule);
		cap.text = name ?? 'FreeplayCapsule';
		cap.color = col ?? 0xaaeeff;
		cap.difficulty = diff ?? 0;
		cap.ID = capsuleGrp.members.length - 1;
		capsuleGrp.add(cap);

		return cap;
	}

	var songArray:Array<String> = [null];
	var diffArray:Array<String> = ['easy', 'normal', 'hard', 'erect', 'nightmare'];

	var curDiffSelected:Int = 1;
	var curSelected:Int = 1;
	var curSelectedLerp:Float = 1;
	var elapsedTime:Float = 0;

	override function update(elapsed:Float) {
		super.update(elapsed);
		elapsedTime += elapsed;

		if (FlxG.keys.justPressed.ESCAPE) {
			FlxG.switchState(new states.TitleState());
		}

		if (FlxG.keys.justPressed.UP)
			changeSelection(-1);

		if (FlxG.keys.justPressed.DOWN)
			changeSelection(1);

		if (FlxG.keys.justPressed.LEFT) {
			arrows[0].setColorTransform(1, 1, 1, 1, 128, 100, 10);
			changeDiff(-1);
		}

		if (FlxG.keys.justPressed.RIGHT) {
			arrows[1].setColorTransform(1, 1, 1, 1, 128, 100, 10);
			changeDiff(1);
		}

		if (FlxG.keys.justReleased.LEFT)
			arrows[0].setColorTransform();
		if (FlxG.keys.justReleased.RIGHT)
			arrows[1].setColorTransform();

		curSelectedLerp = FlxMath.lerp(curSelectedLerp, curSelected, elapsed * 13);

		for (i in capsuleGrp.members) {
			var sel = i.ID - curSelectedLerp;
			i.x = capsuleGrp.x + ((sel * sel * -1) * 30);
			i.y = capsuleGrp.y + (sel * 150);
		}

		scoreNum.number = FlxG.game.ticks;

		if (randomCapsule != null) {
			// bro
			list[0].color = FlxColor.fromHSB(elapsedTime * 69, list[0].color.saturation, list[0].color.brightness);
			randomCapsule.set_color(list[0].color);
			// @:privateAccess trace(randomCapsule.glowFilter.color);
		}

		if (FlxG.keys.justPressed.ENTER)
			select();
	}

	function select() {
		// random
		if (curSelected == 0)
			changeSelection(FlxG.random.int(1, capsuleGrp.members.length - 1));

		var cap = capsuleGrp.members[curSelected];
		if (cap.icon != null) {
			cap.icon.animation.play('confirm', true);
		}

		FlxG.sound.play(Paths.sound('ui/confirm'));
	}

	function changeSelection(bleh:Int = 0) {
		var lastSelect:Int = curSelected;

		curSelected += bleh;
		curSelected = FlxMath.wrap(curSelected, 0, capsuleGrp.members.length - 1);

		if (bleh != 0)
			FlxG.sound.play(Paths.sound('ui/scroll'));

		// i Do not wanna add defaultColor property
		// edit: i had to (colorMult)
		@:privateAccess
		for (i in capsuleGrp.members) {
			i.moves = false;
			var sel = i.ID - curSelected;
			i.frontGlow.visible = sel == 0;
			i.textObj.alpha = sel == 0 ? 1 : 0.8;
			i.colorMult = 0xFFffffff;
			if (sel != 0) {
				i.colorMult.brightness *= 0.8;
				i.colorMult.saturation *= 2;
				i.colorMult.blueFloat *= 1.1;
				i.colorMult.greenFloat *= 0.9;
				i.colorMult = i.colorMult;
			}
		}
	}

	function changeDiff(bleh:Int = 0) {
		curDiffSelected = FlxMath.wrap(curDiffSelected + bleh, 0, diffArray.length - 1);
		var newDiff:String = diffArray[curDiffSelected];

		var testFrames = Paths.sparrow('menus/freeplay/diff/' + newDiff);
		if (testFrames != null) {
			diffSprite.frames = testFrames;
			diffSprite.animation.addByPrefix('idle', 'idle', 24, true);
			diffSprite.animation.play('idle');
			diffSprite.updateHitbox();
		} else {
			diffSprite.loadGraphic(Paths.image('menus/freeplay/diff/' + newDiff));
		}
		diffSprite.offset.x = Math.floor(diffSprite.width * 0.5);
		diffSprite.offset.y = Math.floor(diffSprite.height * 0.5);

		diffSprite.offsetOffset.y = 14;
		diffSprite.scaleMult.set(1.05, 1.05);
		FlxTween.cancelTweensOf(diffSprite.offsetOffset);
		FlxTween.cancelTweensOf(diffSprite.scaleMult);
		FlxTween.tween(diffSprite.offsetOffset, {y: 0}, 0.6, {ease: FlxEase.elasticOut});
		FlxTween.tween(diffSprite.scaleMult, {x: 1, y: 1}, 2 / 24, {
			ease: function(t) {
				return Math.floor(t);
			}
		});

		if (bleh != 0)
			FlxG.sound.play(Paths.sound('ui/scroll'));
	}

	function doCapsuleAnim(cap:FreeplayCapsule) {
		cap.offset.x = FlxG.width * -1;
		cap.scale.set(1, 0.6);
		FlxTween.tween(cap.offset, {x: 30}, 0.3, {
			startDelay: (cap.ID * 0.1),
			ease: FlxEase.sineIn,
			onComplete: (_) -> {
				cap.scale.set(0.6, 1.1);
				cap.offset.y = 15;
				var bounce = FlxTween.tween(cap.offset, {x: 0, y: 0}, 1.4, {
					startDelay: 0.01,
					ease: FlxEase.expoOut
				});
				var bounce = FlxTween.tween(cap.scale, {x: 1, y: 1}, 0.5, {
					startDelay: 0.01,
					ease: FlxEase.expoOut
				});
				/*
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
				 */
			}
		});
	}
}
