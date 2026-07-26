package objects;

import backend.animation.PsychAnimationController;
import backend.NoteTypesConfig;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

import objects.StrumNote;

import flixel.math.FlxRect;

using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

typedef NoteSplashData = {
	disabled:Bool,
	texture:String,
	useGlobalShader:Bool, //breaks r/g/b but makes it copy default colors for your custom note
	useRGBShader:Bool,
	antialiasing:Bool,
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float
}

/**
 * The note object used as a data structure to spawn and manage notes during gameplay.
 * 
 * If you want to make a custom note type, you should search for: "function set_noteType"
**/
class Note extends FlxSprite
{
	//This is needed for the hardcoded note types to appear on the Chart Editor,
	//It's also used for backwards compatibility with 0.1 - 0.3.2 charts.
	public static final defaultNoteTypes:Array<String> = [
		'', //Always leave this one empty pls
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation'
	];

	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var strumTime:Float = 0;
	public var noteData:Int = 0;

	public var mustPress:Bool = false;
	public var playtestMustPress:Bool = false;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;

	public var wasGoodHit:Bool = false;
	public var missed:Bool = false;

	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var spawned:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;
	
	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var rgbShader:RGBShaderReference;
	public static var globalRgbShaders:Array<RGBPalette> = [];
	public static var forceEditorSixKeyPalette:Bool = false;
	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public static var SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * 0.7;
	public static var colArray(get, null):Array<String>;
	private static function get_colArray():Array<String>
	{
		return getColorArrayForNote();
	}

	public static function usesRGBSupportedNoteSkin(?skin:String):Bool
	{
		if (skin == null || skin.length < 1)
		{
			skin = (PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) ? PlayState.SONG.arrowSkin : defaultNoteSkin;
		}
		if (skin == null || skin.length < 1)
			return true;

		var normalizedSkin:String = skin.trim().toLowerCase().replace('\\', '/');
		var vanillaBaseName:String = 'note_assets';
		var vanillaSkin:String = defaultNoteSkin.trim().toLowerCase().replace('\\', '/');
		var lastSegment:String = normalizedSkin;
		if (lastSegment.indexOf('/') >= 0)
			lastSegment = lastSegment.substring(lastSegment.lastIndexOf('/') + 1);

		return normalizedSkin == vanillaSkin || normalizedSkin == vanillaBaseName || lastSegment == vanillaBaseName;
	}

	private static function getRenderSideCount(?mustPress:Null<Bool>):Int
	{
		if (PlayState.SONG != null)
		{
			var playerCount:Int = backend.Song.getKeyCountForPlayer(PlayState.SONG);
			var opponentCount:Int = backend.Song.getKeyCountForOpponent(PlayState.SONG);
			if (mustPress == true)
				return playerCount;
			if (mustPress == false)
				return opponentCount;
			return (playerCount == 6 || opponentCount == 6) ? 6 : 4;
		}
		return 4;
	}

	public static function getNoteScaleForSide(?mustPress:Null<Bool>):Float
	{
		var sideCount:Int = getRenderSideCount(mustPress);
		var noOpponent:Bool = (PlayState.SONG != null && PlayState.SONG.noOpponent == true);
		return sideCount == 6 ? (noOpponent ? 0.7 : 0.6) : 0.7;
	}

	public static function getColorArrayForNote(?mustPress:Null<Bool>):Array<String>
	{
		var sideCount:Int = getRenderSideCount(mustPress);
		var paletteArray:Array<Array<FlxColor>> = (PlayState.isPixelStage == true) ? ClientPrefs.data.arrowRGBPixel : ClientPrefs.data.arrowRGB;
		var usesSixKeyPalette:Bool = forceEditorSixKeyPalette || (sideCount == 6) || (paletteArray != null && paletteArray.length >= 6);
		if (usesSixKeyPalette)
			return ['purple', 'green', 'red', 'yellow', 'blue', 'navy'];
		return ['purple', 'blue', 'green', 'red'];
	}

	public static function getPaletteIndexForColorName(colorName:String):Int
	{
		switch (colorName)
		{
			case 'purple': return 0;
			case 'green': return 1;
			case 'red': return 2;
			case 'yellow': return 3;
			case 'blue': return 4;
			case 'navy': return 5;
			default: return 0;
		}
	}

	public static function getVisualColorKeyForLane(lane:Int, ?mustPress:Null<Bool>):String
	{
		var sideCount:Int = forceEditorSixKeyPalette ? 6 : getRenderSideCount(mustPress);
		if (sideCount == 6)
		{
			var colorArray:Array<String> = getColorArrayForNote(mustPress);
			return colorArray[(lane % colorArray.length)];
		}

		return switch (lane % 4)
		{
			case 0: 'purple';
			case 1: 'blue';
			case 2: 'green';
			case 3: 'red';
			default: 'purple';
		};
	}

	public static function getRGBPaletteForNoteData(noteData:Int, ?mustPress:Null<Bool>, ?isPixelStage:Null<Bool>):Array<FlxColor>
	{
		if (noteData < 0) return null;
		var visualColorKey:String = getVisualColorKeyForNoteData(noteData, mustPress, null);
		var paletteIndex:Int = getPaletteIndexForColorName(visualColorKey);
		var paletteArray:Array<Array<FlxColor>> = (isPixelStage == true) ? ClientPrefs.data.arrowRGBPixel : ClientPrefs.data.arrowRGB;
		if (paletteArray != null && paletteIndex >= 0 && paletteIndex < paletteArray.length)
			return paletteArray[paletteIndex];
		return null;
	}

	public static function getVisualColorKeyForNoteData(noteData:Int, ?mustPress:Null<Bool>, ?skin:String):String
	{
		return getVisualColorKeyForLane(noteData, mustPress);
	}

	public static function getVisualAnimationKeyForNoteData(noteData:Int, ?mustPress:Null<Bool>, ?skin:String):String
	{
		var visualColorKey:String = getVisualColorKeyForNoteData(noteData, mustPress, skin);
		var shouldUseVanilla6KeyMapping:Bool = usesRGBSupportedNoteSkin(skin) && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB) && (forceEditorSixKeyPalette || getRenderSideCount(mustPress) == 6);
		if (shouldUseVanilla6KeyMapping)
		{
			switch (noteData)
			{
				case 3: return 'purple';
				case 5: return 'red';
			}
		}
		return visualColorKey;
	}
	public static var defaultNoteSkin(default, never):String = 'noteSkins/NOTE_assets';

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: !PlayState.isPixelStage,
		useGlobalShader: false,
		useRGBShader: (PlayState.SONG != null) ? !(PlayState.SONG.disableNoteRGB == true) : true,
		r: -1,
		g: -1,
		b: -1,
		a: ClientPrefs.data.splashAlpha
	};

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.02;
	public var missHealth:Float = 0.1;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;
	public var hitsoundChartEditor:Bool = true;
	/**
	 * Forces the hitsound to be played even if the user's hitsound volume is set to 0
	**/
	public var hitsoundForce:Bool = false;
	public var hitsoundVolume(get, default):Float = 1.0;
	function get_hitsoundVolume():Float {
		if(ClientPrefs.data.hitsoundVolume > 0)
			return ClientPrefs.data.hitsoundVolume;
		return hitsoundForce ? hitsoundVolume : 0.0;
	}
	public var hitsound:String = 'hitsound';

	private function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		//trace('fuck cock');
		return value;
	}

	public function resizeByRatio(ratio:Float) //haha funny twitter shit
	{
		if(isSustainNote && animation.curAnim != null && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_texture(value:String):String {
		if(texture != value) reloadNote(value);

		texture = value;
		return value;
	}

	public function defaultRGB()
	{
		var shouldUseRGBBehavior:Bool = usesRGBSupportedNoteSkin((PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) ? PlayState.SONG.arrowSkin : null) && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB);
		if (!shouldUseRGBBehavior)
		{
			rgbShader.r = 0xFFFF0000;
			rgbShader.g = 0xFF00FF00;
			rgbShader.b = 0xFF0000FF;
			return;
		}

		var arr:Array<FlxColor> = getRGBPaletteForNoteData(noteData, mustPress, PlayState.isPixelStage);
		if (arr != null && arr.length >= 3)
		{
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		}
		else
		{
			rgbShader.r = 0xFFFF0000;
			rgbShader.g = 0xFF00FF00;
			rgbShader.b = 0xFF0000FF;
		}
	}

	private function set_noteType(value:String):String {
		noteSplashData.texture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes/noteSplashes';
		defaultRGB();

		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = mustPress;
					//reloadNote('HURTNOTE_assets');
					//this used to change the note texture to HURTNOTE_assets.png,
					//but i've changed it to something more optimized with the implementation of RGBPalette:

					// note colors
					rgbShader.r = 0xFF101010;
					rgbShader.g = 0xFFFF0000;
					rgbShader.b = 0xFF990022;

					// splash data and colors
					noteSplashData.r = 0xFFFF0000;
					noteSplashData.g = 0xFF101010;
					noteSplashData.texture = 'noteSplashes/noteSplashes-electric';

					// gameplay data
					lowPriority = true;
					missHealth = isSustainNote ? 0.25 : 0.1;
					hitCausesMiss = true;
					hitsound = 'cancelMenu';
					hitsoundChartEditor = false;
				case 'Alt Animation':
					animSuffix = '-alt';
				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
			}
			if (value != null && value.length > 1) NoteTypesConfig.applyNoteTypeData(this, value);
			if (hitsound != 'hitsound' && hitsoundVolume > 0) Paths.sound(hitsound); //precache new sound for being idiot-proof
			noteType = value;
		}
		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null, ?noteMustPress:Null<Bool> = null)
	{
		super();

		animation = new PsychAnimationController(this);

		antialiasing = ClientPrefs.data.antialiasing;
		if(createdFrom == null) createdFrom = PlayState.instance;

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;
		this.moves = false;
		if (noteMustPress != null)
			this.mustPress = noteMustPress;

		x += (ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.data.noteOffset;

		this.noteData = noteData;

		var shouldUseVanilla6KeyMapping:Bool = false;
		if(noteData > -1)
		{
			var usesRGBBehavior:Bool = usesRGBSupportedNoteSkin((PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) ? PlayState.SONG.arrowSkin : null) && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB);
			shouldUseVanilla6KeyMapping = usesRGBBehavior && (forceEditorSixKeyPalette || getRenderSideCount(mustPress) == 6);
			rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData, mustPress));
			rgbShader.enabled = usesRGBBehavior;
			texture = '';
			defaultRGB();
			x += swagWidth * (noteData);
			var localLane:Int = noteData;
			if(!isSustainNote) { //Doing this 'if' check to fix the warnings on Senpai songs
				var animToPlay:String = getVisualAnimationKeyForNoteData(localLane, mustPress, texture);
				animation.play(animToPlay + 'Scroll');
			}
		}

		// trace(prevNote);

		if(prevNote != null)
			prevNote.nextNote = this;

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;
			if(ClientPrefs.data.downScroll) flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			var holdLane:Int = noteData;
			var holdAnim:String = getVisualAnimationKeyForNoteData(holdLane, mustPress, texture);
			animation.play(holdAnim + 'holdend');

			updateHitbox();

			offsetX -= width / 2;

			if (PlayState.isPixelStage)
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				var prevAnim:String = getVisualAnimationKeyForNoteData(prevNote.noteData, prevNote.mustPress, prevNote.texture);
				prevNote.animation.play(prevAnim + 'hold');
				if (!inEditor)
				{
					prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
					if(createdFrom != null && createdFrom.songSpeed != null) prevNote.scale.y *= createdFrom.songSpeed;
				}
				prevNote.updateHitbox();
			}

			if(PlayState.isPixelStage)
			{
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
			earlyHitMult = 0;
		}
		else if(!isSustainNote)
		{
			centerOffsets();
			centerOrigin();
		}
		x += offsetX;
	}

	public static function initializeGlobalRGBShader(noteData:Int, ?mustPress:Null<Bool>)
	{
		if (noteData < 0) return new RGBPalette();

		if (globalRgbShaders == null)
			globalRgbShaders = [];

		if (noteData < globalRgbShaders.length && globalRgbShaders[noteData] != null)
			return globalRgbShaders[noteData];

		while (globalRgbShaders.length <= noteData)
			globalRgbShaders.push(null);

		var newRGB:RGBPalette = new RGBPalette();
		var arr:Array<FlxColor> = getRGBPaletteForNoteData(noteData, mustPress, PlayState.isPixelStage);
		
		if (arr != null && arr.length >= 3)
		{
			newRGB.r = arr[0];
			newRGB.g = arr[1];
			newRGB.b = arr[2];
		}
		else
		{
			newRGB.r = 0xFFFF0000;
			newRGB.g = 0xFF00FF00;
			newRGB.b = 0xFF0000FF;
		}
		
		globalRgbShaders[noteData] = newRGB;
		return newRGB;
	}

	var _lastNoteOffX:Float = 0;
	static var _lastValidChecked:String; //optimization
	public var originalHeight:Float = 6;
	public var correctionOffset:Float = 0; //dont mess with this
	public function reloadNote(texture:String = '', postfix:String = '') {
		if(texture == null) texture = '';
		if(postfix == null) postfix = '';

		var skin:String = texture + postfix;
		if(texture.length < 1)
		{
			skin = PlayState.SONG != null ? PlayState.SONG.arrowSkin : null;
			if(skin == null || skin.length < 1)
				skin = defaultNoteSkin + postfix;
		}

		var animName:String = null;
		if(animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		var skinPixel:String = skin;
		var lastScaleY:Float = scale.y;
		var skinPostfix:String = getNoteSkinPostfix();
		var shouldUseRGBBehavior:Bool = usesRGBSupportedNoteSkin(skin) && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB);
		rgbShader.enabled = shouldUseRGBBehavior;
		var customSkin:String = skin + skinPostfix;
		var path:String = PlayState.isPixelStage ? 'pixelUI/' : '';
		if(customSkin == _lastValidChecked || Paths.fileExists('images/' + path + customSkin + '.png', IMAGE))
		{
			skin = customSkin;
			_lastValidChecked = customSkin;
		}
		else skinPostfix = '';

		if(PlayState.isPixelStage) {
			if(isSustainNote) {
				var graphic = Paths.image('pixelUI/' + skinPixel + 'ENDS' + skinPostfix);
				loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));
				originalHeight = graphic.height / 2;
			} else {
				var graphic = Paths.image('pixelUI/' + skinPixel + skinPostfix);
				loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));
			}
			var pixelScaleMultiplier:Float = 1.0;
			var noOpponent:Bool = (PlayState.SONG != null && PlayState.SONG.noOpponent == true);
			if (usesRGBSupportedNoteSkin(skin) && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB))
				pixelScaleMultiplier = (forceEditorSixKeyPalette || getRenderSideCount(mustPress) == 6) ? (noOpponent ? 0.7 : 0.6) : 0.7;
			else
				pixelScaleMultiplier = 0.7;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom * (pixelScaleMultiplier / 0.7)));
			loadPixelNoteAnims();
			antialiasing = false;

			if(isSustainNote) {
				offsetX += _lastNoteOffX;
				_lastNoteOffX = (width - 7) * (PlayState.daPixelZoom / 2);
				offsetX -= _lastNoteOffX;
			}
		} else {
			frames = Paths.getSparrowAtlas(skin);
			loadNoteAnims();
			if(!isSustainNote)
			{
				centerOffsets();
				centerOrigin();
			}
		}

		if(isSustainNote) {
			scale.y = lastScaleY;
		}

		if (!PlayState.isPixelStage)
		{
			// --- 6-KEY DYNAMIC SCROLLING NOTES SCALE INJECTION ---
			var noteScale:Float = getRenderSideCount(mustPress) == 6 ? getNoteScaleForSide(mustPress) : 0.7;

			// Apply the compressed horizontal scale to regular notes or hold note tails
			scale.x = noteScale;
			if(!isSustainNote) {
				scale.y = noteScale;
			}
		}
		
		updateHitbox();
		defaultRGB();

		if(animName != null)
			animation.play(animName, true);
	}

	public static function getNoteSkinPostfix()
	{
		var skin:String = '';
		if(ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin)
			skin = '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	function loadNoteAnims() {
		var visualColorKey:String = getVisualColorKeyForNoteData(noteData, mustPress, texture);
		if (visualColorKey == null)
			return;

		@:privateAccess animation.clearAnimations();

		var shouldUseVanilla6KeyMapping:Bool = usesRGBSupportedNoteSkin(texture) && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB) && (forceEditorSixKeyPalette || getRenderSideCount(mustPress) == 6);
		if (shouldUseVanilla6KeyMapping)
		{
			visualColorKey = getVisualAnimationKeyForNoteData(noteData, mustPress, texture);
		}

		if (isSustainNote)
		{
			attemptToAddAnimationByPrefix('purpleholdend', 'pruple end hold', 24, true); // this fixes some retarded typo from the original note .FLA
			animation.addByPrefix(visualColorKey + 'holdend', visualColorKey + ' hold end', 24, true);
			animation.addByPrefix(visualColorKey + 'hold', visualColorKey + ' hold piece', 24, true);
		}
		else animation.addByPrefix(visualColorKey + 'Scroll', visualColorKey + '0');

		var noteScale:Float = (forceEditorSixKeyPalette || getRenderSideCount(mustPress) == 6) ? ((PlayState.SONG != null && PlayState.SONG.noOpponent == true) ? 0.7 : 0.6) : 0.7;
		setGraphicSize(Std.int(width * noteScale));
		updateHitbox();
	}

	function loadPixelNoteAnims() {
		var visualColorKey:String = getVisualColorKeyForNoteData(noteData, mustPress, texture);
		if (visualColorKey == null)
			return;

		@:privateAccess animation.clearAnimations();

		var shouldUseVanilla6KeyMapping:Bool = usesRGBSupportedNoteSkin(texture) && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB) && (forceEditorSixKeyPalette || getRenderSideCount(mustPress) == 6);
		if (shouldUseVanilla6KeyMapping)
		{
			visualColorKey = getVisualAnimationKeyForNoteData(noteData, mustPress, texture);
		}

		if(isSustainNote)
		{
			animation.add(visualColorKey + 'holdend', [noteData + 4], 24, true);
			animation.add(visualColorKey + 'hold', [noteData], 24, true);
		} else {
			animation.add(visualColorKey + 'Scroll', [noteData + 4], 24, true);
		}
	}

	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if(animFrames.length < 1) return;

		animation.addByPrefix(name, prefix, framerate, doLoop);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult) &&
						strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult));

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (!wasGoodHit && strumTime <= Conductor.songPosition)
			{
				if(!isSustainNote || (prevNote.wasGoodHit && !ignoreNote))
					wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	override public function destroy()
	{
		super.destroy();
		_lastValidChecked = '';
	}

	public function followStrumNote(myStrum:StrumNote, fakeCrochet:Float, songSpeed:Float = 1)
	{
		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;

		distance = (0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if (!myStrum.downScroll) distance *= -1;

		var angleDir = strumDirection * Math.PI / 180;
		if (copyAngle)
			angle = strumDirection - 90 + strumAngle + offsetAngle;

		if(copyAlpha)
			alpha = strumAlpha * multAlpha;

		if(copyX)
			x = strumX + offsetX + Math.cos(angleDir) * distance;

		if(copyY)
		{
			y = strumY + offsetY + correctionOffset + Math.sin(angleDir) * distance;
			if(myStrum.downScroll && isSustainNote)
			{
				if(PlayState.isPixelStage)
				{
					y -= PlayState.daPixelZoom * 9.5;
				}
				y -= (frameHeight * scale.y) - (Note.swagWidth / 2);
			}
		}

	}

	public function clipToStrumNote(myStrum:StrumNote)
	{
		var center:Float = myStrum.y + offsetY + Note.swagWidth / 2;
		if((mustPress || !ignoreNote) && (wasGoodHit || (prevNote.wasGoodHit && !canBeHit)))
		{
			var swagRect:FlxRect = clipRect;
			if(swagRect == null) swagRect = new FlxRect(0, 0, frameWidth, frameHeight);

			if (myStrum.downScroll)
			{
				if(y - offset.y * scale.y + height >= center)
				{
					swagRect.width = frameWidth;
					swagRect.height = (center - y) / scale.y;
					swagRect.y = frameHeight - swagRect.height;
				}
			}
			else if (y + offset.y * scale.y <= center)
			{
				swagRect.y = (center - y) / scale.y;
				swagRect.width = width / scale.x;
				swagRect.height = (height / scale.y) - swagRect.y;
			}
			clipRect = swagRect;
		}
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}
}
