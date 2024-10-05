package objects.ui;

import flixel.FlxSpriteExt;
import flixel.addons.ui.FlxUIAssets;
import flixel.math.FlxRect;

class NineSliceSprite extends FlxSpriteExt {
	/*
		override function set_width(v:Float) {
			var og = super.set_width(v);
			setGrid(grid1[0], grid1[1], grid2[0], grid2[1]);
			return og;
		}

		override function set_height(v:Float) {
			var og = super.set_height(v);
			setGrid(grid1[0], grid1[1], grid2[0], grid2[1]);
			return og;
		}
	 */
	public function new(x:Float = 0, y:Float = 0, w:Float = 18, h:Float = 18) {
		super(x, y);
		loadGraphic(FlxUIAssets.IMG_CHROME);
		setGrid(5, 5, 13, 13);
		setSize(h, h);
		rotateOffset = true;
		additiveOffset = true;
	}

	var grid1:Array<Float> = [5, 5];
	var grid2:Array<Float> = [13, 13];

	var slices:Array<Array<Dynamic>> = [];

	public function setGrid(x1:Float = 5, y1:Float = 5, x2:Float = 13, y2:Float = 13) {
		grid1[0] = x1;
		grid1[1] = y1;
		grid2[0] = x2;
		grid2[1] = y2;

		if (slices.length != 9) {
			for (i in 0...9)
				slices.push([FlxRect.get(), '']);
		}

		final w = frameWidth;
		final h = frameHeight;

		final fuck:Array<Dynamic> = [
			[0, 0, x1, y1, 'top.left'],
			[x1, 0, x2 - x1, y1, 'top'],
			[x2, 0, w - x2, y1, 'top.right'],

			[0, y1, x1, y2 - y1, 'left'],
			[x1, y1, x2 - x1, y2 - y1, 'middle'],
			[x2, y1, w - x2, y2 - y1, 'right'],

			[0, y2, x1, h - y2, 'bottom.left'],
			[x1, y2, x2 - x1, h - y2, 'bottom'],
			[x2, y2, w - x2, h - y2, 'bottom.right']
		];

		for (idx => i in fuck) {
			slices[idx][0].set(i[0], i[1], i[2], i[3]);
			slices[idx][1] = i[4];
		}
		origin.set(0, 0);
		// centerOriginPoint();
	}

	override public function draw() {
		for (s in slices) {
			setupPart(s[0], s[1]);
			super.draw();
		}
	}

	inline function setupPart(rect:FlxRect, ?id:String = '?') {
		if (clipRect == null)
			clipRect = FlxRect.get();

		clipRect = clipRect.copyFrom(rect);

		offset.set();

		scale.set(1, 1);

		final x1 = grid1[0];
		final y1 = grid1[1];
		final x2 = grid2[0];
		final y2 = grid2[1];

		switch (id) {
			case 'top' | 'bottom':
				final top:Bool = id == 'top';
				setGraphicSize(width - (x1 + x2), top ? y1 : y2);
				offset.x -= x1 * scale.x;
				offset.x += x1;
				if (!top) {
					offset.y -= (height - (y2)) * scale.y;
					offset.y += height - (y2);
				}

			case 'top.left' | 'top.right' | 'bottom.left' | 'bottom.right':
				final top:Bool = id.startsWith('top.');
				final left:Bool = id.endsWith('.left');

				if (!left)
					offset.x += width - x2;
				if (!top)
					offset.y += height - y2;

			case 'left' | 'right':
				final left:Bool = id == 'left';
				setGraphicSize(left ? x1 : x2, height - (y1 + y2));
				offset.y += y1;
				if (!left)
					offset.x += width - (x2);

			case 'middle':
				setGraphicSize(width - (x1 + x2), height - (y1 + y2));
				offset.subtract(x1 * scale.x, y1 * scale.y);
				offset.add(x1, y1);
		}
		offset.subtract(origin.x, origin.y);
	}

	override function updateHitbox() {
		FlxG.log.warn("can't updateHitbox on a NineSliceSprite, did you forget this class uses width / height instead of frameWidth / frameHeight?");
	}

	public function centerOriginPoint() {
		origin.set(.5 * width, .5 * height);
	}
}
