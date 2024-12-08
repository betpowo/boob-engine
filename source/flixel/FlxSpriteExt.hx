package flixel;

import flash.geom.Matrix;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;

/**
 * god bless flxskewedsprite for existing otherwise this would be impossible for me to figure out
 */
class FlxSpriteExt extends FlxSprite {
	public var angleOffset:Float = 0.0;
	public var scaleMult:FlxPoint = new FlxPoint(1, 1);
	public var alphaMult:Float = 1.0;

	// i cant use flxaxes???
	public var scaleOffsetX:Bool = false;
	public var scaleOffsetY:Bool = false;

	public var rotateOffset:Bool = false;

	/**
		WHY IS IT NOT ADDITIVE IN THE FIRST PLACE
	**/
	public var additiveOffset:Bool = false;

	/**
		useless, but just for fun
	**/
	public var offsetOffset:FlxPoint = new FlxPoint(0, 0);

	public var unroundRect:Bool = false;

	override function drawComplex(camera:FlxCamera):Void {
		/*
			_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
			inline _matrix.translate(-origin.x, -origin.y);
			_matrix.scale(scale.x * scaleMult.x, scale.y * scaleMult.y);
		 */

		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0);
		inline _matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x * scaleMult.x, scale.y * scaleMult.y);
		if (checkFlipX()) {
			_matrix.a *= -1;
			_matrix.c *= -1;
			_matrix.tx *= -1;
		}
		if (checkFlipY()) {
			_matrix.b *= -1;
			_matrix.d *= -1;
			_matrix.ty *= -1;
		}

		if (bakedRotationAngle <= 0) {
			var radians:Float = (angle + angleOffset) * FlxAngle.TO_RAD;
			var _sinAngleCustom = Math.sin(radians);
			var _cosAngleCustom = Math.cos(radians);

			if (radians != 0)
				_matrix.rotateWithTrig(_cosAngleCustom, _sinAngleCustom);
		}

		var ogoffx = offset.x;
		var ogoffy = offset.y;

		offset.addPoint(offsetOffset);

		if (scaleOffsetX)
			offset.x *= scale.x * scaleMult.x;
		if (scaleOffsetY)
			offset.y *= scale.y * scaleMult.y;
		if (rotateOffset)
			offset.degrees += angle + angleOffset;

		if (additiveOffset)
			getScreenPosition(_point, camera).addPoint(offset);
		else
			getScreenPosition(_point, camera).subtractPoint(offset);
		_point.addPoint(origin);
		if (isPixelPerfectRender(camera))
			_point.floor();

		offset.x = ogoffx;
		offset.y = ogoffy;

		inline _matrix.translate(_point.x, _point.y);

		var ogAlpha = colorTransform.alphaMultiplier;
		colorTransform.alphaMultiplier = ogAlpha * alphaMult;
		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
		colorTransform.alphaMultiplier = ogAlpha;
	}

	override function isOnScreen(?camera:FlxCamera):Bool {
		return super.isOnScreen(camera);
	}

	/**
	 * Calculates the smallest globally aligned bounding box that encompasses this sprite's graphic as it
	 * would be displayed. Honors scrollFactor, rotation, scale, offset and origin.
	 * @param newRect Optional output `FlxRect`, if `null`, a new one is created.
	 * @param camera  Optional camera used for scrollFactor, if null `FlxG.camera` is used.
	 * @return A globally aligned `FlxRect` that fully contains the input sprite.
	 * @since 4.11.0
	 */
	override public function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect {
		// lmfao
		if (additiveOffset) {
			if (newRect == null)
				newRect = FlxRect.get();

			if (camera == null)
				camera = FlxG.camera;

			newRect.setPosition(x, y);
			if (pixelPerfectPosition)
				newRect.floor();
			_scaledOrigin.set(origin.x * scale.x, origin.y * scale.y);
			newRect.x += -Std.int(camera.scroll.x * scrollFactor.x) + offset.x + origin.x - _scaledOrigin.x;
			newRect.y += -Std.int(camera.scroll.y * scrollFactor.y) + offset.y + origin.y - _scaledOrigin.y;
			if (isPixelPerfectRender(camera))
				newRect.floor();
			newRect.setSize(frameWidth * Math.abs(scale.x), frameHeight * Math.abs(scale.y));
			return newRect.getRotatedBounds(angle, _scaledOrigin, newRect);
		}
		return super.getScreenBounds(newRect, camera);
	}

	override function set_clipRect(rect:FlxRect):FlxRect {
		if (rect != null)
			clipRect = unroundRect ? rect : rect.round();
		else
			clipRect = null;
		if (frames != null)
			frame = frames.frames[animation.frameIndex];
		return rect;
	}
}
