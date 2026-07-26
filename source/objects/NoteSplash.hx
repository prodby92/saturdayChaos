package objects;

import backend.animation.PsychAnimationController;
import shaders.RGBPalette;
import flixel.system.FlxAssets.FlxShader;

typedef RGB = {
	r:Null<Int>,
	g:Null<Int>,
	b:Null<Int>
}

typedef NoteSplashAnim = {
	name:String,
	noteData:Int,
	prefix:String,
	indices:Array<Int>,
	offsets:Array<Float>,
	fps:Array<Int>
}

typedef NoteSplashConfig = {
	animations:Map<String, NoteSplashAnim>,
	scale:Float,
	allowRGB:Bool,
	allowPixel:Bool,
	rgb:Array<Null<RGB>>
}

class NoteSplash extends FlxSprite
{
	public var rgbShader:PixelSplashShaderRef;
	public var texture:String;
	public var config(default, set):NoteSplashConfig;
	public var babyArrow:StrumNote;
	public var noteData:Int = 0;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var inEditor:Bool = false;

	var spawned:Bool = false;
	var noteDataMap:Map<Int, String> = new Map();
	var activeConfigKey:String = null;

	public static var defaultNoteSplash(default, never):String = "noteSplashes/noteSplashes";
	public static var configs:Map<String, NoteSplashConfig> = new Map();
	public static var splashScaleMultiplier:Float = 1.4;

	public function new(?x:Float = 0, ?y:Float = 0, ?splash:String)
	{
		super(x, y);

		animation = new PsychAnimationController(this);

		rgbShader = new PixelSplashShaderRef();
		shader = rgbShader.shader;

		loadSplash(splash);
	}

	public var maxAnims(default, set):Int = 0;
	public function loadSplash(?splash:String, ?mustPress:Null<Bool>)
	{
		config = null;
		maxAnims = 0;

		if(splash == null)
		{
			splash = defaultNoteSplash + getSplashSkinPostfix();
			if (PlayState.SONG != null && PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) splash = PlayState.SONG.splashSkin;
		}

		texture = splash;
		frames = Paths.getSparrowAtlas(texture);
		if (frames == null)
		{
			texture = defaultNoteSplash + getSplashSkinPostfix();
			frames = Paths.getSparrowAtlas(texture);
			if (frames == null)
			{
				texture = defaultNoteSplash;
				frames = Paths.getSparrowAtlas(texture);
			}
		}

		var path:String = 'images/$texture';
		var colorArray:Array<String> = getSplashColorArrayForNote(mustPress);
		var configKey:String = path + '|' + (mustPress == true ? 'player' : mustPress == false ? 'opponent' : 'default');
		if (configs.exists(configKey))
		{
			this.config = configs.get(configKey);
			activeConfigKey = configKey;
			for (anim in this.config.animations)
			{
				if (anim.noteData % colorArray.length == 0)
					maxAnims++;
			}
			return;
		}
		else if (Paths.fileExists('$path.json', TEXT))
		{
			var config:Dynamic = haxe.Json.parse(Paths.getTextFromFile('$path.json'));
			if (config != null)
			{
				var tempConfig:NoteSplashConfig = {
					animations: new Map(),
					scale: config.scale,
					allowRGB: config.allowRGB,
					allowPixel: config.allowPixel,
					rgb: config.rgb
				}

				for (i in Reflect.fields(config.animations))
				{
					var anim:NoteSplashAnim = Reflect.field(config.animations, i);
					tempConfig.animations.set(i, anim);
					if (anim.noteData % colorArray.length == 0)
						maxAnims++;
				}

				this.config = tempConfig;
				activeConfigKey = configKey;
				configs.set(configKey, this.config);
				return;
			}
		}

		// Splashes with no json
		var tempConfig:NoteSplashConfig = createConfig();
		var anim:String = 'note splash';
		var fps:Array<Null<Int>> = [22, 26];
		var offsets:Array<Array<Float>> = [[0, 0]];
		if (Paths.fileExists('$path.txt', TEXT)) // Backwards compatibility with 0.7 splash txts
		{
			var configFile:Array<String> = CoolUtil.listFromString(Paths.getTextFromFile('$path.txt'));
			if (configFile.length > 0)
			{
				anim = configFile[0];
				if (configFile.length > 1)
				{
					var framerates:Array<String> = configFile[1].split(' ');
					fps = [Std.parseInt(framerates[0]), Std.parseInt(framerates[1])];
					if (fps[0] == null) fps[0] = 22;
					if (fps[1] == null) fps[1] = 26;

					if (configFile.length > 2)
					{
						offsets = [];
						for (i in 2...configFile.length)
						{
							if (configFile[i].trim() != '')
							{
								var animOffs:Array<String> = configFile[i].split(' ');
								var x:Float = Std.parseFloat(animOffs[0]);
								var y:Float = Std.parseFloat(animOffs[1]);
								if (Math.isNaN(x)) x = 0;
								if (Math.isNaN(y)) y = 0;
								offsets.push([x, y]);
							}
						}
					}
				}
			}
		}

		var failedToFind:Bool = false;
		while (true)
		{
			for (v in colorArray)
			{
				if (!checkForAnim('$anim $v ${maxAnims+1}'))
				{
					failedToFind = true;
					break;
				}
			}
			if (failedToFind) break;
			maxAnims++;
		}

		for (animNum in 0...maxAnims)
		{
			for (i => col in colorArray)
			{
				var data:Int = i % colorArray.length + (animNum * colorArray.length);
				var name:String = animNum > 0 ? '$col' + (animNum + 1) : col;
				var offset:Array<Float> = offsets[FlxMath.wrap(data, 0, Std.int(offsets.length-1))];
				addAnimationToConfig(tempConfig, 1, name, '$anim $col ${animNum + 1}', fps, offset, [], data);
			}
		}

		this.config = tempConfig;
		activeConfigKey = configKey;
		configs.set(configKey, this.config);
	}

	private static function getSplashColorArrayForNote(?mustPress:Null<Bool>):Array<String>
	{
		var usesSixKeyPalette:Bool = Note.forceEditorSixKeyPalette;
		if (!usesSixKeyPalette && PlayState.SONG != null)
		{
			var playerCount:Int = backend.Song.getKeyCountForPlayer(PlayState.SONG);
			var opponentCount:Int = backend.Song.getKeyCountForOpponent(PlayState.SONG);
			var sideCount:Int = (mustPress == true) ? playerCount : (mustPress == false) ? opponentCount : ((playerCount == 6 || opponentCount == 6) ? 6 : 4);
			usesSixKeyPalette = (sideCount == 6);
		}

		if (usesSixKeyPalette)
			return ['purple', 'green', 'red', 'yellow', 'blue', 'navy'];

		return ['purple', 'blue', 'green', 'red'];
	}

	public function spawnSplashNote(?x:Float = 0, ?y:Float = 0, ?noteData:Int = 0, ?note:Note, ?randomize:Bool = true)
	{
		if (note != null && note.noteSplashData.disabled)
			return;

		aliveTime = 0;

		if (!inEditor)
		{
			var loadedTexture:String = defaultNoteSplash + getSplashSkinPostfix();
			if (note != null && note.noteSplashData.texture != null) loadedTexture = note.noteSplashData.texture;
			else if (PlayState.SONG != null && PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) loadedTexture = PlayState.SONG.splashSkin;

			var splashMustPress:Null<Bool> = note != null ? note.mustPress : null;
			var requestedConfigKey:String = 'images/$loadedTexture|' + (splashMustPress == true ? 'player' : splashMustPress == false ? 'opponent' : 'default');
			var shouldReloadConfig:Bool = (texture != loadedTexture) || (config == null) || (activeConfigKey != requestedConfigKey);
			if (shouldReloadConfig) loadSplash(loadedTexture, splashMustPress);
		}

		setPosition(x, y);

		if (babyArrow != null)
		{
			var anchorX:Float = babyArrow.x - Note.swagWidth * 0.95 - 50;
			var anchorY:Float = babyArrow.y - Note.swagWidth;
			setPosition(anchorX, anchorY);
		}

		if (note != null)
			noteData = note.noteData;

		var colorArray:Array<String> = getSplashColorArrayForNote(note != null ? note.mustPress : null);
		var splashColorCount:Int = Std.int(Math.max(1, colorArray.length));
		var baseLane:Int = Std.int(FlxMath.wrap(noteData, 0, splashColorCount - 1));
		var resolvedLane:Int = baseLane;
		var matchedAnim:NoteSplashAnim = null;
		var colorKey:String = colorArray[resolvedLane];
		for (anim in config.animations)
		{
			var normalizedName:String = anim.name != null ? anim.name.toLowerCase() : '';
			var normalizedPrefix:String = anim.prefix != null ? anim.prefix.toLowerCase() : '';
			var directMatch:Bool = normalizedName == colorKey.toLowerCase();
			var noteDataMatch:Bool = anim.noteData == resolvedLane;
			var prefixMatch:Bool = normalizedPrefix.indexOf(colorKey.toLowerCase()) >= 0;
			if (directMatch || noteDataMatch || prefixMatch)
			{
				matchedAnim = anim;
				break;
			}
		}
		var animationNoteData:Int = resolvedLane;
		if (matchedAnim != null)
			animationNoteData = matchedAnim.noteData;
		else if (config.animations != null)
		{
			var animationCount:Int = 0;
			for (_ in config.animations)
				animationCount++;
			var maxFallbackLane:Int = Std.int(Math.max(0, animationCount - 1));
			var fallbackLane:Int = Std.int(FlxMath.wrap(noteData, 0, maxFallbackLane));
			var fallbackAnim:NoteSplashAnim = null;
			var i:Int = 0;
			for (anim in config.animations)
			{
				if (i == fallbackLane)
				{
					fallbackAnim = anim;
					break;
				}
				i++;
			}
			if (fallbackAnim != null)
				animationNoteData = fallbackAnim.noteData;
			else
				animationNoteData = resolvedLane;
		}
		else
			animationNoteData = resolvedLane;

		this.noteData = animationNoteData;
		var anim:String = playDefaultAnim();

		// If the requested animation didn't exist (recycled splash), try a fallback
		if (animation.curAnim == null)
		{
			var base:Int = resolvedLane % splashColorCount;
			var fallback:String = null;
			for (k in noteDataMap.keys())
			{
				var key:Int = k;
				if ((key % Math.max(1, splashColorCount)) == base)
				{
					fallback = noteDataMap.get(key);
					break;
				}
			}

			if (fallback != null && animation.exists(fallback))
			{
				animation.play(fallback, true);
				anim = fallback;
			}
			else
			{
				// As a last resort reset to first frame to avoid showing previous splash frame
				if (animation.curAnim != null)
					animation.curAnim.curFrame = 0;
				else if (frames != null && frames.frames != null && frames.frames.length > 0)
					frame = frames.frames[0];
			}
		}

		var colorCount:Int = splashColorCount;
		var tempShader:RGBPalette = null;
		var resolvedNoteSkin:String = null;
		if (PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1)
			resolvedNoteSkin = PlayState.SONG.arrowSkin;
		else if (note != null && note.texture != null && note.texture.length > 0)
			resolvedNoteSkin = note.texture;
		else
			resolvedNoteSkin = Note.defaultNoteSkin;
		var shouldUseRGBBehavior:Bool = config.allowRGB && Note.usesRGBSupportedNoteSkin(resolvedNoteSkin) && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB);
		if (shouldUseRGBBehavior)
		{
			var paletteColors:Array<FlxColor> = Note.getRGBPaletteForNoteData(resolvedLane % colorCount, note != null ? note.mustPress : null, PlayState.isPixelStage);
			if (inEditor || (note == null || note.noteSplashData.useRGBShader) && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB))
			{
				tempShader = new RGBPalette();
				// If Note RGB is enabled:
				if ((note == null || !note.noteSplashData.useGlobalShader) || inEditor)
				{
					var colors = config.rgb;
					if (colors != null)
					{
						for (i in 0...colors.length)
						{
							if (i > 2) break;

							var arr:Array<FlxColor> = (paletteColors != null && paletteColors.length >= 3) ? paletteColors : [0xFFFF0000, 0xFF00FF00, 0xFF0000FF];
							var rgb = colors[i];
							if (rgb == null)
							{
								if (i == 0) tempShader.r = arr[0];
								else if (i == 1) tempShader.g = arr[1];
								else if (i == 2) tempShader.b = arr[2];
								continue;
							}

							var r:Null<Int> = rgb.r; 
							var g:Null<Int> = rgb.g;
							var b:Null<Int> = rgb.b;

							if (r == null || Math.isNaN(r) || r < 0) r = arr[0];
							if (g == null || Math.isNaN(g) || g < 0) g = arr[1];
							if (b == null || Math.isNaN(b) || b < 0) b = arr[2];

							var color:FlxColor = FlxColor.fromRGB(r, g, b);
							if (i == 0) tempShader.r = color;
							else if (i == 1) tempShader.g = color;
							else if (i == 2) tempShader.b = color;
						}
					}
					else
					{
						var fallbackColors:Array<FlxColor> = (paletteColors != null && paletteColors.length >= 3) ? paletteColors : [0xFFFF0000, 0xFF00FF00, 0xFF0000FF];
						tempShader.r = fallbackColors[0];
						tempShader.g = fallbackColors[1];
						tempShader.b = fallbackColors[2];
					}

					if (note != null)
					{
						if (note.noteSplashData.r != -1) tempShader.r = note.noteSplashData.r;
						if (note.noteSplashData.g != -1) tempShader.g = note.noteSplashData.g;
						if (note.noteSplashData.b != -1) tempShader.b = note.noteSplashData.b;
					}
				}
				else
				{
					var fallbackColors:Array<FlxColor> = (paletteColors != null && paletteColors.length >= 3) ? paletteColors : [0xFFFF0000, 0xFF00FF00, 0xFF0000FF];
					tempShader.r = fallbackColors[0];
					tempShader.g = fallbackColors[1];
					tempShader.b = fallbackColors[2];
				}
			}
		}
		rgbShader.copyValues(tempShader);
		if (!config.allowPixel) rgbShader.pixelAmount = 1;
		else if (PlayState.isPixelStage) rgbShader.pixelAmount = 6;

		applyAnimationOffsets(anim);
		updateAnchorPosition();

		animation.finishCallback = function(name:String) {
			kill();
			spawned = false;
		}

		alpha = ClientPrefs.data.splashAlpha;
		if (note != null) alpha = note.noteSplashData.a;

		antialiasing = ClientPrefs.data.antialiasing;
		if (note != null) antialiasing = note.noteSplashData.antialiasing;
		if (PlayState.isPixelStage && config.allowPixel) antialiasing = false;

		var minFps:Int = 22;
		var maxFps:Int = 26;
		var currentConf:NoteSplashAnim = config != null && config.animations != null ? config.animations.get(anim) : null;
		if (currentConf != null)
		{
			minFps = currentConf.fps[0];
			if (minFps < 0) minFps = 0;

			maxFps = currentConf.fps[1];
			if (maxFps < 0) maxFps = 0;
		}

		if (animation.curAnim != null)
			animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);

		spawned = true;
	}
	
	public function applyAnimationOffsets(?animName:String)
	{
		var conf:NoteSplashAnim = null;
		if (config != null && config.animations != null)
		{
			conf = config.animations.get(animName);
			if (conf == null && animation.curAnim != null)
				conf = config.animations.get(animation.curAnim.name);
		}

		var useDirectAnchorPositioning:Bool = inEditor || babyArrow != null;
		if (!useDirectAnchorPositioning)
		{
			centerOffsets();
			centerOrigin();
		}
		offset.set(0, 0);
		if (conf != null && conf.offsets != null && conf.offsets.length >= 2)
		{
			offset.x += conf.offsets[0];
			offset.y += conf.offsets[1];
		}
		if (isVanillaSplash())
		{
			offset.y -= 10;
		}
		if (babyArrow != null)
		{
			var previewXOffset:Float = 0;
			var previewYOffset:Float = 0;
			if (texture != null && texture.indexOf('noteSplashes-electric') >= 0)
			{
				previewXOffset = 0;
				previewYOffset = 0;
			}
			else if (texture != null && texture.indexOf('noteSplashes-sparkles') >= 0)
			{
				previewXOffset = 0;
				previewYOffset = 0;
			}
			offset.x += previewXOffset;
			offset.y += previewYOffset;
		}
	}

	function updateAnchorPosition()
	{
		if (babyArrow != null)
		{
			var targetX:Float = babyArrow.x - Note.swagWidth * 0.95;
			var targetY:Float = babyArrow.y - Note.swagWidth - 10;
			if (!inEditor && isVanillaSplash()) targetX -= 10;

			if (inEditor || copyX)
				x = targetX;
			if (inEditor || copyY)
				y = targetY;
		}
	}

	public function playDefaultAnim()
	{
		var anim:String = noteDataMap.get(noteData);
		if (anim != null && animation.exists(anim))
			animation.play(anim, true);

		return anim;
	}

	function checkForAnim(anim:String)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, anim); // adds valid frames to animFrames

		return animFrames.length > 0;
	}

	var aliveTime:Float = 0;
	static var buggedKillTime:Float = 1.5; //automatically kills note splashes if they break to prevent it from flooding your HUD
	override function update(elapsed:Float)
	{
		if (spawned)
		{
			aliveTime += elapsed;
			// Safety: force-kill splashes after a timeout to avoid stuck last-frame sprites
			if (aliveTime >= buggedKillTime)
			{
				if (animation.finishCallback != null) animation.finishCallback = null;
				kill();
				spawned = false;
			}
		}

		updateAnchorPosition();
		super.update(elapsed);
	}

	function isVanillaSplash():Bool
	{
		return (texture != null && texture.toLowerCase().indexOf('noteSplashes-vanilla') >= 0)
			|| (ClientPrefs.data.splashSkin != null && ClientPrefs.data.splashSkin.trim().toLowerCase() == 'vanilla');
	}

	public static function getSplashSkinPostfix()
	{
		var skin:String = '';
		if (ClientPrefs.data.splashSkin != ClientPrefs.defaultData.splashSkin)
			skin = '-' + ClientPrefs.data.splashSkin.trim().toLowerCase().replace(' ', '-');
		return skin;
	}

	public static function createConfig():NoteSplashConfig
	{
		return {
			animations: new Map(),
			scale: 1,
			allowRGB: true,
			allowPixel: true,
			rgb: null
		}
	}

	public static function addAnimationToConfig(config:NoteSplashConfig, scale:Float, name:String, prefix:String, fps:Array<Int>, offsets:Array<Float>, indices:Array<Int>, noteData:Int):NoteSplashConfig
	{
		if (config == null) config = createConfig();

		config.animations.set(name, {name: name, noteData: noteData, prefix: prefix, indices: indices, offsets: offsets, fps: fps});
		config.scale = scale;
		return config;
	}

	function set_config(value:NoteSplashConfig):NoteSplashConfig 
	{
		if (value == null) value = createConfig();

		@:privateAccess
		animation.clearAnimations();
		noteDataMap.clear();

		for (i in value.animations)
		{
			var key:String = i.name;
			if (i.prefix.length > 0 && key != null && key.length > 0)
			{
				if (i.indices != null && i.indices.length > 0)
					animation.addByIndices(key, i.prefix, i.indices, "", i.fps[1], false);
				else
					animation.addByPrefix(key, i.prefix, i.fps[1], false);

				noteDataMap.set(i.noteData, key);
			}
		}

		var baseScale:Float = 1;
		var configScale:Float = value.scale;
		if (!Math.isNaN(configScale))
			baseScale = configScale;
		var noteScale:Float = Note.getNoteScaleForSide();
		var finalScale:Float = baseScale * noteScale * splashScaleMultiplier;
		scale.set(finalScale, finalScale);
		return config = value;
	}

	function set_maxAnims(value:Int)
	{
		if (value > 0)
			noteData = Std.int(FlxMath.wrap(noteData, 0, (value * Note.colArray.length) - 1));
		else
			noteData = 0;

		return maxAnims = value;
	}
}

class PixelSplashShaderRef 
{
	public var shader:PixelSplashShader = new PixelSplashShader();
	public var enabled(default, set):Bool = true;
	public var pixelAmount(default, set):Float = 1;

	public function copyValues(tempShader:RGBPalette)
	{
		if (tempShader != null)
		{
			for (i in 0...3)
			{
				shader.r.value[i] = tempShader.shader.r.value[i];
				shader.g.value[i] = tempShader.shader.g.value[i];
				shader.b.value[i] = tempShader.shader.b.value[i];
			}
			shader.mult.value[0] = tempShader.shader.mult.value[0];
		}
		else enabled = false;
	}

	public function set_enabled(value:Bool)
	{
		enabled = value;
		shader.mult.value = [value ? 1 : 0];
		return value;
	}

	public function set_pixelAmount(value:Float)
	{
		pixelAmount = value;
		shader.uBlocksize.value = [value, value];
		return value;
	}

	public function reset()
	{
		shader.r.value = [0, 0, 0];
		shader.g.value = [0, 0, 0];
		shader.b.value = [0, 0, 0];
	}

	public function new()
	{
		reset();
		enabled = true;

		if (!PlayState.isPixelStage) pixelAmount = 1;
		else pixelAmount = PlayState.daPixelZoom;
		//trace('Created shader ' + Conductor.songPosition);
	}
}

class PixelSplashShader extends FlxShader
{
	@:glFragmentHeader('
		#pragma header

		uniform vec3 r;
		uniform vec3 g;
		uniform vec3 b;
		uniform float mult;
		uniform vec2 uBlocksize;

		vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) {
			vec2 blocks = openfl_TextureSize / uBlocksize;
			vec4 color = flixel_texture2D(bitmap, floor(coord * blocks) / blocks);
			if (!hasTransform) {
				return color;
			}

			if (color.a == 0.0 || mult == 0.0) {
				return color * openfl_Alphav;
			}

			vec4 newColor = color;
			newColor.rgb = min(color.r * r + color.g * g + color.b * b, vec3(1.0));
			newColor.a = color.a;

			color = mix(color, newColor, mult);

			if (color.a > 0.0) {
				return vec4(color.rgb, color.a);
			}
			return vec4(0.0, 0.0, 0.0, 0.0);
		}')

	@:glFragmentSource('
		#pragma header

		void main() {
			gl_FragColor = flixel_texture2DCustom(bitmap, openfl_TextureCoordv);
		}')

	public function new()
	{
		super();
	}
}