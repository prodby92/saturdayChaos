package objects;

import backend.Song;
import backend.animation.PsychAnimationController;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

class StrumNote extends FlxSprite
{
	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;
	private var player:Int;

	// Tweakable middleScroll layout settings — adjust these to fine-tune placement
	public static var MIDDLE_SCROLL_SIDE_BASE_PADDING_6KEY:Float = 24; // extra px beyond lane widths for 6-key
	public static var MIDDLE_SCROLL_SIDE_BASE_PADDING_4KEY:Float = 48; // extra px beyond lane widths for 4-key
	public static var MIDDLE_SCROLL_SIDE_MULT_LEFT:Float = 2; // multiplier for left half (6-key)
	public static var MIDDLE_SCROLL_SIDE_MULT_RIGHT:Float = 1.05; // multiplier for right half (6-key)
	public static var STATIC_6KEY_SQUISH_AMOUNT:Float = 12; // extra inward push when 6-key no-opponent static layout is active
	public static var STATIC_6KEY_STRUM_SPACING_DELTA:Float = 12; // reduce inter-note spacing for 6-key static layout
	public static var STATIC_6KEY_STRUM_GAP:Float = -40; // extra gap between player/opponent strums for 6-key static layout
	// 4-key specific multipliers — tweak these to adjust 4-key halves independently
	public static var MIDDLE_SCROLL_SIDE_MULT_LEFT_4KEY:Float = 2; // multiplier for left half (4-key)
	public static var MIDDLE_SCROLL_SIDE_MULT_RIGHT_4KEY:Float = 1.125; // multiplier for right half (4-key)
	public static var MIDDLE_SCROLL_CENTER_ON_SCREEN:Bool = true; // true centers on screen midpoint
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	public var useRGBShader:Bool = true;
	public var force6KeyVisualMapping:Bool = false;
	public function new(x:Float, y:Float, leData:Int, player:Int) {
		animation = new PsychAnimationController(this);

		var resolvedSkin:String = null;
		if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) resolvedSkin = PlayState.SONG.arrowSkin;
		else resolvedSkin = Note.defaultNoteSkin;
		var usesRGBBehavior:Bool = Note.usesRGBSupportedNoteSkin(resolvedSkin) && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB);

		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
		rgbShader.enabled = usesRGBBehavior;
		useRGBShader = usesRGBBehavior;
		
		var arr:Array<FlxColor> = Note.getRGBPaletteForNoteData(leData, player != 0, PlayState.isPixelStage);
		if(arr != null && arr.length >= 3)
		{
			@:bypassAccessor
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}

		noteData = leData;
		this.player = player;
		this.noteData = leData;
		this.ID = noteData;
		super(x, y);

		var skin:String = null;
		if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		else skin = Note.defaultNoteSkin;

		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;

		texture = skin; //Load texture and anims
		scrollFactor.set();
		playAnim('static');
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		// --- CHECK TRACK MANIA STYLE ---
		var usesOpponentSide:Bool = (player == 0);
		var sideKeyCount:Int = usesOpponentSide ? Song.getKeyCountForOpponent(PlayState.SONG) : Song.getKeyCountForPlayer(PlayState.SONG);
		var is6Key:Bool = (PlayState.SONG != null && sideKeyCount == 6);
		var usesRGBBehavior:Bool = Note.usesRGBSupportedNoteSkin(texture) && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB);
		var use6KeyVisualMapping:Bool = force6KeyVisualMapping || (is6Key && (!usesRGBBehavior || Note.usesRGBSupportedNoteSkin(texture)));
		useRGBShader = usesRGBBehavior;
		rgbShader.enabled = usesRGBBehavior;

		if(PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/' + texture));
			
			// Adjust the pixel grid splitting metrics for extra lanes
			var pixelColumns:Int = is6Key ? 6 : 4;
			width = width / pixelColumns;
			height = height / 5;
			loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			var noOpponent:Bool = (PlayState.SONG != null && PlayState.SONG.noOpponent == true);
			var pixelScale:Float = usesRGBBehavior ? (is6Key ? (noOpponent ? 0.7 : 0.6) : 0.7) : 0.7;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom * (pixelScale / 0.7)));

			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purple', [4]);

			// 6-key pixel mapping for gameplay and the RGB editor preview row
			if (use6KeyVisualMapping)
			{
				switch (Math.abs(noteData))
				{
					case 0: // Left
						animation.add('static', [0]);
						animation.add('pressed', [6, 12], 12, false);
						animation.add('confirm', [18, 24], 24, false);
					case 1: // Up
						animation.add('static', [2]);
						animation.add('pressed', [8, 14], 12, false);
						animation.add('confirm', [20, 26], 12, false);
					case 2: // Right
						animation.add('static', [3]);
						animation.add('pressed', [9, 15], 12, false);
						animation.add('confirm', [21, 27], 24, false);
					case 3: // Back
						animation.add('static', [0]);
						animation.add('pressed', [10, 16], 12, false);
						animation.add('confirm', [22, 28], 24, false);
					case 4: // Down
						animation.add('static', [1]);
						animation.add('pressed', [7, 13], 12, false);
						animation.add('confirm', [19, 25], 24, false);
					case 5: // Forward
						animation.add('static', [3]);
						animation.add('pressed', [11, 17], 12, false);
						animation.add('confirm', [23, 29], 24, false);
				}
			}
			else
			{
				// Traditional 4-Key Default Pixel Loop
				switch (Math.abs(noteData) % 4)
				{
					case 0:
						animation.add('static', [0]);
						animation.add('pressed', [4, 8], 12, false);
						animation.add('confirm', [12, 16], 24, false);
					case 1:
						animation.add('static', [1]);
						animation.add('pressed', [5, 9], 12, false);
						animation.add('confirm', [13, 17], 24, false);
					case 2:
						animation.add('static', [2]);
						animation.add('pressed', [6, 10], 12, false);
						animation.add('confirm', [14, 18], 12, false);
					case 3:
						animation.add('static', [3]);
						animation.add('pressed', [7, 11], 12, false);
						animation.add('confirm', [15, 19], 24, false);
				}
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas(texture);
			animation.addByPrefix('green', 'arrowUP');
			animation.addByPrefix('blue', 'arrowDOWN');
			animation.addByPrefix('purple', 'arrowLEFT');
			animation.addByPrefix('red', 'arrowRIGHT');

			antialiasing = ClientPrefs.data.antialiasing;
			
			// Dynamically scales the graphics asset size matching playerPosition()
			var noteScale:Float = usesRGBBehavior ? (is6Key ? 0.6 : 0.7) : 0.7;
			setGraphicSize(Std.int(width * noteScale));

			// Custom texture path: keep the original non-RGB six-lane sprite mapping and scale behavior.
			if (use6KeyVisualMapping && (!usesRGBBehavior || force6KeyVisualMapping || is6Key))
			{
				var useVanillaRgb6KeyAnimations:Bool = usesRGBBehavior && Note.usesRGBSupportedNoteSkin(texture);
				switch (Math.abs(noteData))
				{
					case 0: // Left
						animation.addByPrefix('static', 'arrowLEFT');
						animation.addByPrefix('pressed', 'left press', 24, false);
						animation.addByPrefix('confirm', 'left confirm', 24, false);
					case 1: // Up
						animation.addByPrefix('static', 'arrowUP');
						animation.addByPrefix('pressed', 'up press', 24, false);
						animation.addByPrefix('confirm', 'up confirm', 24, false);
					case 2: // Right
						animation.addByPrefix('static', 'arrowRIGHT');
						animation.addByPrefix('pressed', 'right press', 24, false);
						animation.addByPrefix('confirm', 'right confirm', 24, false);
					case 3: // Back
						animation.addByPrefix('static', 'arrowLEFT');
						if (useVanillaRgb6KeyAnimations)
						{
							animation.addByPrefix('pressed', 'left press', 24, false);
							animation.addByPrefix('confirm', 'left confirm', 24, false);
						}
						else
						{
							animation.addByPrefix('pressed', 'back press', 24, false);
							animation.addByPrefix('confirm', 'back confirm', 24, false);
						}
					case 4: // Down
						animation.addByPrefix('static', 'arrowDOWN');
						animation.addByPrefix('pressed', 'down press', 24, false);
						animation.addByPrefix('confirm', 'down confirm', 24, false);
					case 5: // Forward
						animation.addByPrefix('static', 'arrowRIGHT');
						if (useVanillaRgb6KeyAnimations)
						{
							animation.addByPrefix('pressed', 'right press', 24, false);
							animation.addByPrefix('confirm', 'right confirm', 24, false);
						}
						else
						{
							animation.addByPrefix('pressed', 'forward press', 24, false);
							animation.addByPrefix('confirm', 'forward confirm', 24, false);
						}
				}
			}
			else
			{
				switch (Math.abs(noteData) % 4)
				{
					case 0:
						animation.addByPrefix('static', 'arrowLEFT');
						animation.addByPrefix('pressed', 'left press', 24, false);
						animation.addByPrefix('confirm', 'left confirm', 24, false);
					case 1:
						animation.addByPrefix('static', 'arrowDOWN');
						animation.addByPrefix('pressed', 'down press', 24, false);
						animation.addByPrefix('confirm', 'down confirm', 24, false);
					case 2:
						animation.addByPrefix('static', 'arrowUP');
						animation.addByPrefix('pressed', 'up press', 24, false);
						animation.addByPrefix('confirm', 'up confirm', 24, false);
					case 3:
						animation.addByPrefix('static', 'arrowRIGHT');
						animation.addByPrefix('pressed', 'right press', 24, false);
						animation.addByPrefix('confirm', 'right confirm', 24, false);
				}
			}
		}
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}


	public function playerPosition():Void
	{
		var sideKeyCount:Int = 4;
		if (PlayState.SONG != null)
			sideKeyCount = Std.int(Math.max(4, player == 1 ? Song.getKeyCountForPlayer(PlayState.SONG) : Song.getKeyCountForOpponent(PlayState.SONG)));
		var is6Key:Bool = sideKeyCount == 6;
		var noOpponent:Bool = (PlayState.SONG != null && PlayState.SONG.noOpponent == true);
		var columnsPerPlayer:Int = sideKeyCount;
		var laneCountPerSide:Int = columnsPerPlayer;
		var noteScale:Float = is6Key ? (noOpponent ? 0.7 : 0.6) : 0.7;
		var visualScale:Float = PlayState.isPixelStage ? 1.25 : 1.0;
		scale.set(noteScale * visualScale, noteScale * visualScale);
		updateHitbox();

		var noteWidth:Float = 160 * noteScale;
		var useCenteredPlayerStrums:Bool = (PlayState.SONG != null && PlayState.SONG.noOpponent == true && player == 1);
		var visualLaneIndex:Int = Std.int(Math.abs(noteData) % laneCountPerSide);
		var playerOffsetX:Float = (FlxG.width / 2) - ((laneCountPerSide * noteWidth) / 2) + (visualLaneIndex * noteWidth);
		var opponentOffsetX:Float = 42 + (visualLaneIndex * noteWidth);

		var useStatic6KeySquish:Bool = (PlayState.SONG != null && sideKeyCount == 6 && PlayState.SONG.noOpponent == false);
		var effectiveNoteWidth:Float = noteWidth;
		if (useStatic6KeySquish) effectiveNoteWidth = Math.max(4, noteWidth - STATIC_6KEY_STRUM_SPACING_DELTA);
		if (player == 1)
		{
			if (useCenteredPlayerStrums)
			{
				x = playerOffsetX;
				return;
			}

			if (ClientPrefs.data.middleScroll)
			{
				var centeredWidth:Float = laneCountPerSide * effectiveNoteWidth;
				x = (FlxG.width / 2) - (centeredWidth / 2) + (visualLaneIndex * effectiveNoteWidth);
				return;
			}

			// Keep symmetric edge margin for player strums in non-middleScroll layouts
			var edgeMarginPlayer:Float = 92;
			if (useStatic6KeySquish) edgeMarginPlayer += STATIC_6KEY_SQUISH_AMOUNT + STATIC_6KEY_STRUM_GAP;
			var strumSpacing:Float = effectiveNoteWidth;
			var playerStartXDynamic:Float = FlxG.width - ((laneCountPerSide * strumSpacing) + edgeMarginPlayer);
			x = playerStartXDynamic + (visualLaneIndex * strumSpacing);
			return;
		}

		// Non-middleScroll default layout: keep symmetric margins from screen edges
		var edgeMargin:Float = 92;
		if (useStatic6KeySquish) edgeMargin += STATIC_6KEY_SQUISH_AMOUNT + STATIC_6KEY_STRUM_GAP;
		var strumSpacing:Float = noteWidth;
		if (useStatic6KeySquish) strumSpacing = Math.max(4, noteWidth - STATIC_6KEY_STRUM_SPACING_DELTA);
		if (ClientPrefs.data.middleScroll)
		{
			var halfCount:Int = Std.int(Math.ceil(laneCountPerSide / 2));
			if (visualLaneIndex < halfCount)
			{
				x = edgeMargin + (visualLaneIndex * strumSpacing);
			}
			else
			{
				var rightStartX:Float = FlxG.width - edgeMargin - ((laneCountPerSide - halfCount) * strumSpacing);
				x = rightStartX + ((visualLaneIndex - halfCount) * strumSpacing);
			}
		}
		else
		{
			var playerStartX:Float = FlxG.width - ((laneCountPerSide * strumSpacing) + edgeMargin);
			if (player == 1)
			{
				x = playerStartX + (visualLaneIndex * strumSpacing);
			}
			else
			{
				x = edgeMargin + (visualLaneIndex * strumSpacing);
			}
		}
	}


	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		if(animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}
		if(useRGBShader) rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
	}
}
