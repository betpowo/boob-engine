package flixel;

import flash.geom.Matrix;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

/**
 * god bless flxskewedsprite for existing otherwise this would be impossible for me to figure out
 */
class VaryingSprite extends FlxSprite
{
	public var angleOffset:Float = 0.0;
	public var scaleMult:FlxPoint = new FlxPoint(1, 1);
	public var alphaMult:Float = 1.0;
	public var scaleOffset:Bool = false;

	override function drawComplex(camera:FlxCamera):Void
	{
		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		inline _matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x * scaleMult.x, scale.y * scaleMult.y);

		if (bakedRotationAngle <= 0)
		{
			var radians:Float = (angle + angleOffset) * FlxAngle.TO_RAD;
			var _sinAngleCustom = Math.sin(radians);
			var _cosAngleCustom = Math.cos(radians);

			if (radians != 0)
				_matrix.rotateWithTrig(_cosAngleCustom, _sinAngleCustom);
		}

		var ogoffx = offset.x;
		var ogoffy = offset.y;
		if (scaleOffset)
		{
			offset.x = ogoffx * scale.x * scaleMult.x;
			offset.y = ogoffy * scale.y * scaleMult.y;
		}

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
}
