package util;

import flixel.FlxBasic;

/**
 * ash
 *
 * Attached Sprite Handler
 */
class Ash extends FlxBasic {
	var trackers:Array<AshTracker> = [];

	public static function attach(parent:FlxSprite, child:FlxSprite, ?offX:Float = 0, ?offY:Float = 0) {
		trackers.push({
			parent: parent,
			child: child,
			x: offX,
			y: offY
		});
	}

	public static function clear() {
		trackers = [];
	}

	override public function update(elapsed:Float) {
		for (i in trackers) {
			if (i.parent == null || i.child == null) {
				trackers.remove(i);
			} else {
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
	?y:Float
}
