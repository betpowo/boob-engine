@:structInit typedef Chart = {
	var bpm:Array<{t:Float, bpm:Float}>;
	var notes:Array<String>;
	var lanes:Array<ChartLane>;

	@:optional var stars:Int;
	@:optional var speed:Float;
	@:optional var meta:ChartMetadata;
}

@:structInit typedef ChartEvents = {
	?order:Array<String>,
	?events:Array<Dynamic>
}

@:structInit typedef ChartNote = {
	time:Float,
	index:Int,
	?length:Float,
	?lane:Int,
	?kind:String
}

// no structinit for you AAHAHHHAHHA no one likes you no one USES you you dumb

typedef ChartLane = {
	// :<
	?char:String,
	?pos:String,
	?keys:Int,
	?play:Bool,
	?visible:Bool,
	?strumPos:String,
	?vox:String
}

@:structInit typedef ChartMetadata = {
	?display:String,
	?stage:String,
	?color:Null<String>,
	?icon:String,
	?art:Null<String>,
	?music:Null<String>,
	?chart:Null<String>,
	?diff:Array<String>
}
