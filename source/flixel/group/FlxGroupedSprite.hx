package flixel.group;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;

class FlxGroupedSprite extends FlxSprite {
	// ???
	public var group(get, null):FlxGroupedSprite;

	public function get_group():FlxGroupedSprite {
		return this;
	}

	public var members:Array<FlxSprite> = [];

	public var length(get, null):Int;

	public function get_length()
		return members.length;

	public function add(obj:FlxSprite) {
		members.push(obj);
		obj.camera = this.camera;
	}

	public function remove(obj:FlxSprite) {
		members.remove(obj);
	}

	public function insert(pos:Int = 0, obj:FlxSprite) {
		members.insert(pos, obj);
		obj.camera = this.camera;
	}

	override public function set_antialiasing(v:Bool):Bool {
		for (i in members) {
			if (i != null)
				i.antialiasing = v;
		}
		return super.set_antialiasing(v);
	}

	override public function set_camera(c:FlxCamera):FlxCamera {
		for (i in members) {
			if (i != null)
				i.camera = c;
		}
		return super.set_camera(c);
	}

	override public function set_cameras(c:Array<FlxCamera>):Array<FlxCamera> {
		for (i in members) {
			if (i != null)
				i.cameras = c;
		}
		return super.set_cameras(c);
	}

	public function new(?x:Float = 0, ?y:Float = 0) {
		super(x, y);
		// flixelType = SPRITEGROUP;
		origin.set(0, 0);
	}

	override function updateHitbox() {
		for (mem in members) {
			if (mem.active)
				mem.updateHitbox();
		}
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
		for (mem in members) {
			if (mem.active)
				mem.update(elapsed);
		}
	}

	override function draw() {
		for (mem in members) {
			// wip?
			if (mem is FlxGroupedSprite || mem.flixelType == SPRITEGROUP) {
				mem.x += x;
				mem.y += y;
				mem.angle += angle;
				mem.scale.x *= scale.x;
				mem.scale.y *= scale.y;
				mem.offset.x += offset.x;
				mem.offset.y += offset.y;

				mem.draw();

				mem.x -= x;
				mem.y -= y;
				mem.angle -= angle;
				mem.scale.x /= scale.x;
				mem.scale.y /= scale.y;
				mem.offset.x -= offset.x;
				mem.offset.y -= offset.y;
			} else {
				for (cam in mem.getCamerasLegacy()) {
					if (mem.visible && mem.isOnScreen(cam) && mem != null) {
						drawSpriteComplex(mem, cam);
					}
				}
			}
		}
	}

	function drawSpriteComplex(spr:FlxSprite, camera:FlxCamera):Void {
		if (spr == null || camera == null)
			return;

		spr._frame.prepareMatrix(spr._matrix, FlxFrameAngle.ANGLE_0, spr.checkFlipX(), spr.checkFlipY());

		spr._matrix.translate(-spr.origin.x, -spr.origin.y);
		spr._matrix.scale(spr.scale.x, spr.scale.y);

		if (spr.bakedRotationAngle <= 0) {
			@:privateAccess
			if (spr._angleChanged) {
				var radians:Float = spr.angle * FlxAngle.TO_RAD;
				spr._sinAngle = FlxMath.fastSin(radians);
				spr._cosAngle = FlxMath.fastCos(radians);
				spr._angleChanged = false;
			}

			if (spr.angle != 0)
				spr._matrix.rotateWithTrig(spr._cosAngle, spr._sinAngle);
		}

		spr.getScreenPosition(_point, camera).subtractPoint(spr.offset);
		_point.add(spr.origin.x, spr.origin.y);

		spr._matrix.translate(_point.x, _point.y);

		inline postTransform(spr._matrix);

		if (isPixelPerfectRender(camera)) {
			spr._matrix.tx = Math.floor(spr._matrix.tx);
			spr._matrix.ty = Math.floor(spr._matrix.ty);
		}

		camera.drawPixels(spr._frame, spr.framePixels, spr._matrix, spr.colorTransform, spr.blend ?? blend, spr.antialiasing, spr.shader);
	}

	function postTransform(_matrix:FlxMatrix) {
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);

		if (angle != 0)
			_matrix.rotateWithTrig(FlxMath.fastCos(angle * FlxAngle.TO_RAD), FlxMath.fastSin(angle * FlxAngle.TO_RAD));

		getScreenPosition(_point, camera).subtractPoint(offset);
		_point.add(origin.x, origin.y);
		_matrix.translate(_point.x, _point.y);
	}

	// i didnt wanna write these fom scratch ok

	/**
	 * This functionality isn't supported in SpriteGroup
	 */
	override function set_width(Value:Float):Float {
		return Value;
	}

	override function get_width():Float {
		if (length == 0)
			return 0;

		return findMaxXHelper() - findMinXHelper();
	}

	/**
	 * Returns the left-most position of the left-most member.
	 * If there are no members, x is returned.
	 * 
	 * @since 5.0.0
	 */
	public function findMinX() {
		return length == 0 ? x : findMinXHelper();
	}

	function findMinXHelper() {
		var value = Math.POSITIVE_INFINITY;
		for (member in members) {
			if (member == null)
				continue;

			var minX:Float;
			if (member is FlxGroupedSprite || member is FlxGroupedSprite || member.flixelType == SPRITEGROUP)
				minX = (cast member : FlxGroupedSprite).findMinX();
			else
				minX = member.x;

			if (minX < value)
				value = minX;
		}
		return value;
	}

	/**
	 * Returns the right-most position of the right-most member.
	 * If there are no members, x is returned.
	 * 
	 * @since 5.0.0
	 */
	public function findMaxX() {
		return length == 0 ? x : findMaxXHelper();
	}

	function findMaxXHelper() {
		var value = Math.NEGATIVE_INFINITY;
		for (member in members) {
			if (member == null)
				continue;

			var maxX:Float;
			if (member is FlxGroupedSprite || member.flixelType == SPRITEGROUP)
				maxX = (cast member : FlxGroupedSprite).findMaxX();
			else
				maxX = member.x + member.width;

			if (maxX > value)
				value = maxX;
		}
		return value;
	}

	/**
	 * This functionality isn't supported in SpriteGroup
	 */
	override function set_height(Value:Float):Float {
		return Value;
	}

	override function get_height():Float {
		if (length == 0)
			return 0;

		return findMaxYHelper() - findMinYHelper();
	}

	/**
	 * Returns the top-most position of the top-most member.
	 * If there are no members, y is returned.
	 * 
	 * @since 5.0.0
	 */
	public function findMinY() {
		return length == 0 ? y : findMinYHelper();
	}

	function findMinYHelper() {
		var value = Math.POSITIVE_INFINITY;
		for (member in members) {
			if (member == null)
				continue;

			var minY:Float;
			if (member is FlxGroupedSprite || member.flixelType == SPRITEGROUP)
				minY = (cast member : FlxGroupedSprite).findMinY();
			else
				minY = member.y;

			if (minY < value)
				value = minY;
		}
		return value;
	}

	/**
	 * Returns the top-most position of the top-most member.
	 * If there are no members, y is returned.
	 * 
	 * @since 5.0.0
	 */
	public function findMaxY() {
		return length == 0 ? y : findMaxYHelper();
	}

	function findMaxYHelper() {
		var value = Math.NEGATIVE_INFINITY;
		for (member in members) {
			if (member == null)
				continue;

			var maxY:Float;
			if (member is FlxGroupedSprite || member.flixelType == SPRITEGROUP)
				maxY = (cast member : FlxGroupedSprite).findMaxY();
			else
				maxY = member.y + member.height;

			if (maxY > value)
				value = maxY;
		}
		return value;
	}

	public function centerOriginPoint() {
		origin.set(width * .5, height * .5);
	}
}
