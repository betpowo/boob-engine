package util;

import flixel.FlxBasic;

/**
 * ash
 *
 * Attached Sprite Handler
 */
class Ash extends FlxBasic {
	public static var trackers:Array<AshTracker> = [];

	public static function attach(parent:FlxSprite, child:FlxSprite, ?offX:Float = 0, ?offY:Float = 0):AshTracker {
		var bleh:AshTracker = {
			parent: parent,
			child: child,
			x: offX,
			y: offY,
			lerp: null
		};
		trackers.push(bleh);
		return bleh;
	}

	public static function clear() {
		trackers = [];
	}

	override public function update(elapsed:Float) {
		for (i in trackers) {
			if (i.parent == null || i.child == null) {
				trackers.remove(i);
			} else {
				if (i.lerp != null) {
					i.child.x = FlxMath.lerp(i.child.x, i.parent.x + i.x, elapsed * i.lerp);
					i.child.y = FlxMath.lerp(i.child.y, i.parent.y + i.y, elapsed * i.lerp);
				} else
					i.child.setPosition(i.parent.x + i.x, i.parent.y + i.y);
			}
		}
		super.update(elapsed);
	}
}

typedef AshTracker = {
	?parent:FlxSprite,
	?child:FlxSprite,
	?x:Float,
	?y:Float,
	?lerp:Null<Float>
}
