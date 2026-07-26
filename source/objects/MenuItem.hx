package objects;

class MenuItem extends FlxSprite
{
	public var targetY:Float = 0;
	public static inline final MAX_DISPLAY_SIZE:Float = 320;
	public var baseScale:Float = 1;
	public var baseDisplayWidth:Float = 0;
	public var baseDisplayHeight:Float = 0;

	public function new(x:Float, y:Float, weekName:String = '')
	{
		super(x, y);
		loadGraphic(Paths.image('storymenu/' + weekName));

		var largestSide:Float = Math.max(width, height);
		if (largestSide > MAX_DISPLAY_SIZE)
		{
			baseScale = MAX_DISPLAY_SIZE / largestSide;
			scale.set(baseScale, baseScale);
			updateHitbox();
		}
		else baseScale = 1;

		baseDisplayWidth = width;
		baseDisplayHeight = height;

		centerOrigin();
		antialiasing = ClientPrefs.data.antialiasing;
		//trace('Test added: ' + WeekData.getWeekNumber(weekNum) + ' (' + weekNum + ')');
	}

	public var isFlashing(default, set):Bool = false;
	private var _flashingElapsed:Float = 0;
	final _flashColor = 0xFF33FFFF;
	final flashes_ps:Int = 6;

	public function set_isFlashing(value:Bool = true):Bool
	{
		isFlashing = value;
		_flashingElapsed = 0;
		color = (isFlashing) ? _flashColor : FlxColor.WHITE;
		return isFlashing;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (isFlashing)
		{
			_flashingElapsed += elapsed;
			color = (Math.floor(_flashingElapsed * FlxG.updateFramerate * flashes_ps) % 2 == 0) ? _flashColor : FlxColor.WHITE;
		}
	}
}
