package tools;

/**
 * Simple map wrapper which allows getting values with dot access.
 */
@:forward
abstract StringMap<V>(Map<String, V>) from Map<String, V> to Map<String, V> {
	public inline function new():Void {
		this = [];
	}
	
	@:op([])
    @:op(a.b)
    public inline function get(k:String):V {
		return this.get(k);
	}

	@:op([])
    @:op(a.b)
    public inline function set(k:String, v:V):Void {
		this.set(k, v);
	}

	@:from static inline function fromMap<V>(m:Map<String, V>):StringMap<V> {
		return cast m;
	}

	public inline function toString():String {
		return this.toString();
	}
}
