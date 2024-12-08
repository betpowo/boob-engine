package substates.popup;

import flash.events.Event;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUICheckBox;
import flixel.input.keyboard.FlxKey;
import objects.Alphabet;
import objects.Character;
import objects.ui.HealthIcon;
import objects.ui.ImageButton;
import objects.ui.editor.*;
import openfl.net.FileFilter;
import openfl.net.FileReference;
import util.CoolUtil;
import util.GradientMap;

class EditorPopupWindow extends FlxSubState {
	var canvas:FlxUI9SliceSprite;

	var init = {w: 1180., h: 620., title: 'EditorPopupWindow'};
	var cam:FlxCamera;

	// how do i do this
	var schema:Array<Dynamic>;

	public function new(w:Float = 1180, h:Float = 620, title:String = 'EditorPopupWindow', ?schema:Array<Dynamic>) {
		super();
		init.w = w;
		init.h = h;
		init.title = title;

		cam = new FlxCamera();
		cam.bgColor = 0x66000000;

		camera = FlxG.cameras.add(cam, false);

		if (schema != null) {
			this.schema = schema;
		}
	}

	var canvasColors:GradientMap;
	var lightened:GradientMap;

	override public function create() {
		super.create();

		var initZoom:Float = 0.85;
		cam.zoom = initZoom;

		cam.alpha = 0;
		FlxTween.tween(cam, {zoom: 1, alpha: 1}, 0.1, {
			ease: FlxEase.expoOut,
		});

		canvasColors = new GradientMap();
		FlxG.sound.play(Paths.sound('charter/openWindow'));

		canvas = util.CoolUtil.make9Slice(null, null, init.w, init.h);
		add(canvas);
		canvas.screenCenter();
		canvas.shader = canvasColors.shader;

		canvasColors.set(0x9999bb, 0x333366);
		lightened = new GradientMap();
		lightened.copy(canvasColors);
		lightened.white = lightened.white.getLightened(0.75);

		var title:Alphabet = new Alphabet(init.title);
		title.setPosition(canvas.x + 25, canvas.y + 25);
		add(title);
		title.forEach((a) -> {
			a.shader = lightened.shader;
		});

		var closeButton = new ImageButton(Paths.image('ui/editor/image_button/plus'));
		closeButton.quickColor(0xddbbdd, 0x554466);
		closeButton.setPosition(canvas.x + (canvas.width - closeButton.width - 25), canvas.y + 25);
		closeButton.inputs = [FlxKey.ESCAPE];
		closeButton.onPress.add(() -> {
			FlxG.sound.play(Paths.sound('charter/exitWindow'));

			FlxTween.cancelTweensOf(cam);
			FlxTween.tween(cam, {zoom: initZoom, alpha: 0}, 0.2, {
				ease: FlxEase.expoIn,
				onComplete: (_) -> {
					close();
				}
			});
		});
		closeButton.sprite.angle = 45;
		add(closeButton);
		title.camera = closeButton.camera = canvas.camera = cam;

		cam.alpha = 0;

		if (schema != null)
			initSchema();
	}

	function initSchema() {
		for (i in schema) {
			var pos = {x: 0, y: 0};
			if (i.pos != null && (i.pos : Array<Float>).length >= 2) {
				pos.x = i.pos[0];
				pos.y = i.pos[1];
			}
			switch (i.type) {
				case 'check' | 'checkbox':
					var check = new UICheckBox((i.checked : Bool));
					check.setPosition(canvas.x + 25 + pos.x, canvas.y + 125 + pos.y);
					if (i.label != null) {
						var label = CoolUtil.makeTardlingText((i.label : String), lightened.white, lightened.black);
						label.setPosition(check.x + check.width + 5, check.y + 5);
						add(label);
					}
					add(check);
					if (i.onChange != null)
						check.onChange = i.onChange;

					check.shader = lightened.shader;

				case 'label' | 'text':
					var label = CoolUtil.makeTardlingText((i.label : String), lightened.white, lightened.black);
					label.setPosition(canvas.x + 25 + pos.x, canvas.y + 125 + pos.y);
					add(label);

				case 'slider' | 'slide' | 'range':
					var sli = new objects.ui.editor.UISlider(i.percent ?? 0.5, i.width ?? 250);
					sli.setPosition(canvas.x + 25 + pos.x, canvas.y + 125 + pos.y);

					if (i.min != null)
						sli.min = i.min;
					if (i.max != null)
						sli.max = i.max;

					if (i.label != null) {
						var label = CoolUtil.makeTardlingText((i.label : String), lightened.white, lightened.black);
						label.setPosition(sli.x + sli.width + 25, sli.y - 25);
						add(label);
					}
					sli.bar.shader = sli.bar.emptySprite.shader = sli.handle.shader = lightened.shader;

					if (i.onChange != null) {
						sli.onChange = i.onChange;
					}
					sli.value = i.value ?? 0.5;

					// trace('${sli.min},${sli.max}');
					// trace('${i.min},${i.max}');

					add(sli);

				case 'button' | 'image-button':
					var butt = new ImageButton(Paths.image((i.image : String) ?? 'ui/editor/image_button/help'));
					if (i.onPress != null)
						butt.onPress.add(() -> {
							i.onPress();
						});

					if (i.inputs != null)
						butt.inputs = i.inputs;

					if (i.colors != null) {
						var cols:Array<FlxColor> = cast i.colors;
						butt.quickColor(cols[0], cols[1]);
					}
					butt.setPosition(canvas.x + 25 + pos.x, canvas.y + 125 + pos.y);
					add(butt);
					butt.camera = cam;

				// :skull:
				case 'layer' | 'char' | 'layer-button' | 'char-button':
					var butt = new ImageButton(Paths.image('ui/editor/image_button/help'));
					var ini = Character.getIni(i.char);
					butt.sprite.visible = false;

					var col = lightened.black;
					col.alphaFloat = 1;

					var outlin = new FlxColor(col);
					outlin.brightness *= 0.55;
					outlin.greenFloat *= 0.45;
					outlin.blueFloat *= 1.15;

					butt.quickColor(col, outlin);
					butt.button.resize(512, 160);
					add(butt);

					if (i.inputs != null)
						butt.inputs = i.inputs;

					var icon = new HealthIcon();
					icon.icon = ini.global.icon;
					icon.setPosition(10, 10);
					add(icon);

					var text = new FlxText();
					text.size = 32;
					text.text = ini.global.name ?? 'Unknown';
					text.color = lightened.white;
					text.borderColor = lightened.black;
					text.borderStyle = OUTLINE;
					text.borderSize = 3;
					text.setPosition(icon.x + icon.width, 40);
					add(text);

					var subtext = new FlxText();
					subtext.size = 12;
					subtext.text = i.char;
					subtext.color = lightened.white;
					subtext.borderColor = lightened.black;
					subtext.borderStyle = OUTLINE;
					subtext.borderSize = 3;
					subtext.alpha = 0.6;
					add(subtext);

					if (i.charList != null) {
						butt.onPress.add(() -> {
							var fr:FileReference = new FileReference();
							fr.addEventListener(Event.SELECT, function(e) {
								if (e.target == null || !(e.target.name : String).endsWith('.ini')) {
									this.camera.flash(0x33ff0000, 0.2, null, true);
									this.camera.shake(2 / FlxG.width, 0.1);
									FlxG.sound.play(Paths.sound('ui/cancel'));
									return;
								}
								var charID = (e.target.name : String).replace('.ini', '');
								var ini = Character.getIni(charID);
								text.text = ini.global.name ?? 'Unknown';
								subtext.text = charID;
								icon.icon = ini.global.icon ?? '_default';
								if (i.after != null) {
									i.after(charID);
								}
							}, false, 0, true);
							fr.addEventListener(Event.CANCEL, function(e) {}, false, 0, true);
							var filters:Array<FileFilter> = new Array<FileFilter>();
							filters.push(new FileFilter("(.ini) character file", "*.ini"));
							fr.browse();
						});
					}

					butt.setPosition(canvas.x + 25 + pos.x, canvas.y + 125 + pos.y);

					icon.x += butt.x;
					icon.y += butt.y;
					text.x += butt.x;
					text.y += butt.y;

					text.drawFrame(true);
					subtext.setPosition(text.x, text.y + text.height + 5);

					butt.camera = icon.camera = text.camera = cam;

					text.fieldWidth = Std.int(butt.button.width - 100);
			}
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (FlxG.mouse.justPressed) {
			FlxG.sound.play(Paths.sound('charter/ClickDown'));
		} else if (FlxG.mouse.justReleased) {
			FlxG.sound.play(Paths.sound('charter/ClickUp'));
		}
	}

	override function destroy() {
		FlxG.cameras.remove(cam);
		cam.destroy();
		super.destroy();
	}
}
