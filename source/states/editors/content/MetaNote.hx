package states.editors.content;

import objects.Note;
import shaders.RGBPalette;
import flixel.util.FlxDestroyUtil;

class MetaNote extends Note
{
	public static var noteTypeTexts:Map<Int, FlxText> = [];
	public var isEvent:Bool = false;
	public var songData:Array<Dynamic>;
	public var sustainSprite:FlxSprite;
	public var chartY:Float = 0;
	public var chartNoteData:Int = 0;

	public function new(time:Float, data:Int, songData:Array<Dynamic>)
	{
		super(time, data, null, false, true);
		this.songData = songData;
		this.strumTime = time;
		this.chartNoteData = data;
		var shouldUseRgb:Bool = (rgbShader != null && rgbShader.enabled);
		var chartData:Int = data;
		this.noteData = ChartingState.getChartingNoteData(chartData);
		this.mustPress = (songData != null && songData[1] != null) ? ChartingState.getChartingMustPress(songData[1]) : true;
		this.playtestMustPress = this.mustPress;
		
		if(!PlayState.isPixelStage)
			loadNoteAnims();
		else
			loadPixelNoteAnims();

		var rgbEnabled:Bool = shouldUseRgb && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB);
		// Safely initialize or replace the rgbShader — guard against null in editor contexts
		if (rgbShader == null || (rgbShader.parent != null && Note.globalRgbShaders.contains(rgbShader.parent)))
		{
			rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(noteData));
		}
		if (rgbShader != null) rgbShader.enabled = rgbEnabled;

		var visualAnimationKey:String = Note.getVisualAnimationKeyForNoteData(this.noteData, this.mustPress, this.texture);
		animation.play(visualAnimationKey + 'Scroll');
		updateHitbox();
		setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE);
		updateHitbox();
	}

	public function setStrumTime(v:Float)
	{
		this.songData[0] = v;
		this.strumTime = v;
	}

	override function reloadNote(texture:String = '', postfix:String = '')
	{
		super.reloadNote(texture, postfix);
		if (inEditor)
		{
			var visualAnimationKey:String = Note.getVisualAnimationKeyForNoteData(this.noteData, this.mustPress, this.texture);
			animation.play(visualAnimationKey + 'Scroll', true);
			scale.set(1, 1);
			setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE);
			updateHitbox();
		}
	}

	public function changeNoteData(data:Int)
	{
		chartNoteData = data;
		var chartData:Int = data;
		noteData = ChartingState.getChartingNoteData(chartData);
		mustPress = ChartingState.getChartingMustPress(chartData);
		if(songData != null)
			songData[1] = chartData;
		playtestMustPress = mustPress;

		// Refresh editor note visuals when key count / lane mapping changes.
		if (!PlayState.isPixelStage)
		{
			loadNoteAnims();
			var visualAnimationKey:String = Note.getVisualAnimationKeyForNoteData(this.noteData, this.mustPress, this.texture);
			animation.play(visualAnimationKey + 'Scroll', true);
			scale.set(1, 1);
			setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE);
		}
		else
		{
			loadPixelNoteAnims();
			var visualAnimationKey:String = Note.getVisualAnimationKeyForNoteData(this.noteData, this.mustPress, this.texture);
			animation.play(visualAnimationKey + 'Scroll', true);
			scale.set(1, 1);
			setGraphicSize(Std.int(ChartingState.GRID_SIZE * PlayState.daPixelZoom), Std.int(ChartingState.GRID_SIZE * PlayState.daPixelZoom));
		}
		centerOffsets();
		centerOrigin();
		updateHitbox();
	}

	var _lastZoom:Float = -1;
	public function setSustainLength(v:Float, stepCrochet:Float, zoom:Float = 1)
	{
		_lastZoom = zoom;
		v = Math.round(v / (stepCrochet / 2)) * (stepCrochet / 2);
		songData[2] = sustainLength = Math.max(Math.min(v, stepCrochet * 128), 0);

		if(sustainLength > 0)
		{
			if(sustainSprite == null)
			{
				sustainSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
				sustainSprite.scrollFactor.x = 0;
			}
			sustainSprite.setGraphicSize(8, Math.max(ChartingState.GRID_SIZE/4, (Math.round((v * ChartingState.GRID_SIZE + ChartingState.GRID_SIZE) / stepCrochet) * zoom) - ChartingState.GRID_SIZE/2));
			sustainSprite.updateHitbox();
		}
	}

	public var hasSustain(get, never):Bool;
	function get_hasSustain() return (!isEvent && sustainLength > 0);

	public function updateSustainToZoom(stepCrochet:Float, zoom:Float = 1)
	{
		if(_lastZoom == zoom) return;
		setSustainLength(sustainLength, stepCrochet, zoom);
	}

	public function updateSustainToStepCrochet(stepCrochet:Float)
	{
		if(_lastZoom < 0) return;
		setSustainLength(sustainLength, stepCrochet, _lastZoom);
	}
	
	var _noteTypeText:FlxText;
	public function findNoteTypeText(num:Int)
	{
		var txt:FlxText = null;
		if(num != 0)
		{
			if(!noteTypeTexts.exists(num))
			{
				txt = new FlxText(0, 0, ChartingState.GRID_SIZE, (num > 0) ? Std.string(num) : '?', 16);
				txt.autoSize = false;
				txt.alignment = CENTER;
				txt.borderStyle = SHADOW;
				txt.shadowOffset.set(2, 2);
				txt.borderColor = FlxColor.BLACK;
				txt.scrollFactor.x = 0;
				noteTypeTexts.set(num, txt);
			}
			else txt = noteTypeTexts.get(num);
		}
		return (_noteTypeText = txt);
	}

	override function draw()
	{
		if(sustainSprite != null && sustainSprite.exists && sustainSprite.visible && sustainLength > 0)
		{
			sustainSprite.x = this.x + this.width/2 - sustainSprite.width/2;
			sustainSprite.y = this.y + this.height/2;
			sustainSprite.alpha = this.alpha;
			sustainSprite.draw();
		}
		super.draw();

		if(_noteTypeText != null && _noteTypeText.exists && _noteTypeText.visible)
		{
			_noteTypeText.x = this.x + this.width/2 - _noteTypeText.width/2;
			_noteTypeText.y = this.y + this.height/2 - _noteTypeText.height/2;
			_noteTypeText.alpha = this.alpha;
			_noteTypeText.draw();
		}
	}

	override function destroy()
	{
		sustainSprite = FlxDestroyUtil.destroy(sustainSprite);
		super.destroy();
	}
}

class EventMetaNote extends MetaNote
{
	public var eventText:FlxText;
	public function new(time:Float, eventData:Dynamic)
	{
		super(time, -1, eventData);
		this.isEvent = true;
		events = eventData[1];
		//trace('events: $events');
		
		loadGraphic(Paths.image('editors/eventIcon'));
		setGraphicSize(ChartingState.GRID_SIZE);
		updateHitbox();

		eventText = new FlxText(0, 0, 400, '', 12);
		eventText.setFormat(Paths.font('vcr.ttf'), 12, FlxColor.WHITE, RIGHT);
		eventText.scrollFactor.x = 0;
		updateEventText();
	}
	
	override function draw()
	{
		if(eventText != null && eventText.exists && eventText.visible)
		{
			eventText.y = this.y + this.height/2 - eventText.height/2;
			eventText.alpha = this.alpha;
			eventText.draw();
		}
		super.draw();
	}

	override function setSustainLength(v:Float, stepCrochet:Float, zoom:Float = 1) {}

	public var events:Array<Array<String>>;
	public function updateEventText()
	{
		var myTime:Float = Math.floor(this.strumTime);
		if(events.length == 1)
		{
			var event = events[0];
			eventText.text = 'Event: ${event[0]} ($myTime ms)\nValue 1: ${event[1]}\nValue 2: ${event[2]}';
		}
		else if(events.length > 1)
		{
			var eventNames:Array<String> = [for (event in events) event[0]];
			eventText.text = '${events.length} Events ($myTime ms):\n${eventNames.join(', ')}';
		}
		else eventText.text = 'ERROR FAILSAFE';
	}

	override function destroy()
	{
		eventText = FlxDestroyUtil.destroy(eventText);
		super.destroy();
	}
}