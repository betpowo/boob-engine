package substates.popup;

import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUICheckBox;
import flixel.input.keyboard.FlxKey;
import objects.Alphabet;
import objects.ui.ImageButton;
import objects.ui.editor.*;
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
			switch (i.type) {
				// case 'check' | 'checkbox':
				default:
					var check = new UICheckBox((i.checked : Bool));
					if (i.pos != null && (i.pos : Array<Float>).length >= 2)
						check.setPosition(canvas.x + 25 + i.pos[0], canvas.y + 125 + i.pos[1]);
					if (i.label != null) {
						var label = CoolUtil.makeTardlingText((i.label : String), lightened.white, lightened.black);
						label.setPosition(check.x + check.width + 5, check.y + 5);
						add(label);
					}
					add(check);
					if (i.onChange != null)
						check.onChange = i.onChange;

					check.shader = lightened.shader;
			}
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
	}

	override function destroy() {
		FlxG.cameras.remove(cam);
		cam.destroy();
		super.destroy();
	}
}
