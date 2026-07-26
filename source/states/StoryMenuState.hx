package states;

import backend.Song;
import backend.StageData;
import backend.WeekData;
import flixel.addons.display.FlxBackdrop;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import objects.MenuItem;

class StoryMenuState extends MusicBeatState
{
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();

	private static var curWeek:Int = 0;
	var curDifficulty:Int = 0;

	var txtWeekTitle:FlxText;
	var scrollingBg:FlxBackdrop;

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var loadedWeeks:Array<WeekData> = [];

	var weekTargetX:Array<Float> = [];
	var weekTargetY:Array<Float> = [];
	var weekScaleTweens:Array<FlxTween> = [];
	var bgColorTween:FlxTween;

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		persistentUpdate = persistentDraw = true;
		PlayState.isStoryMode = true;
		WeekData.reloadWeekFiles(true);

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end

		if (WeekData.weeksList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState("NO WEEKS ADDED FOR STORY MODE\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
				function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
				function() MusicBeatState.switchState(new states.MainMenuState())));
			return;
		}

		scrollingBg = new FlxBackdrop(Paths.image('bgsleepyDesat'));
		scrollingBg.antialiasing = ClientPrefs.data.antialiasing;
		scrollingBg.scrollFactor.set();
		scrollingBg.velocity.set(30, 30);
		scrollingBg.color = FlxColor.WHITE;
		add(scrollingBg);

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		var num:Int = 0;
		for (i in 0...WeekData.weeksList.length)
		{
			var weekName:String = WeekData.weeksList[i];
			var weekFile:WeekData = WeekData.weeksLoaded.get(weekName);
			var isLocked:Bool = weekIsLocked(weekName);
			if (!isLocked || !weekFile.hiddenUntilUnlocked)
			{
				loadedWeeks.push(weekFile);
				WeekData.setDirectoryFromWeek(weekFile);

				var weekThing:MenuItem = new MenuItem(0, 0, weekName);
				weekThing.ID = num;
				grpWeekText.add(weekThing);
				num++;
			}
		}

		if (loadedWeeks.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState("NO WEEKS AVAILABLE IN STORY MODE.", null, function() MusicBeatState.switchState(new states.MainMenuState())));
			return;
		}

		if (curWeek >= loadedWeeks.length) curWeek = 0;

		txtWeekTitle = new FlxText(0, 100, FlxG.width, "", 42);
		txtWeekTitle.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, CENTER);
		add(txtWeekTitle);

		changeWeek();
		super.create();
	}

	override function update(elapsed:Float)
	{
		if (WeekData.weeksList.length < 1)
		{
			if (controls.BACK && !movedBack && !selectedWeek)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				movedBack = true;
				MusicBeatState.switchState(new MainMenuState());
			}
			super.update(elapsed);
			return;
		}

		if (!movedBack && !selectedWeek)
		{
			var changedWeek:Bool = false;

			if (controls.UI_LEFT_P)
			{
				changedWeek = changeWeek(-1);
			}

			if (controls.UI_RIGHT_P)
			{
				changedWeek = changeWeek(1) || changedWeek;
			}

			if (changedWeek)
				FlxG.sound.play(Paths.sound('scrollMenu'));

			if (FlxG.mouse.wheel != 0)
			{
				if (changeWeek(-FlxG.mouse.wheel))
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			}

			if (controls.ACCEPT)
				selectWeek();
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			MusicBeatState.switchState(new MainMenuState());
		}

		updateWeekPositions(elapsed);
		super.update(elapsed);
	}

	function changeWeek(change:Int = 0):Bool
	{
		var previousWeek:Int = curWeek;
		curWeek += change;
		if (curWeek < 0) curWeek = 0;
		if (curWeek >= loadedWeeks.length) curWeek = loadedWeeks.length - 1;
		if (change != 0 && curWeek == previousWeek)
			return false;

		var leWeek:WeekData = loadedWeeks[curWeek];
		WeekData.setDirectoryFromWeek(leWeek);
		PlayState.storyWeek = curWeek;

		var leName:String = Language.getPhrase('storyname_${leWeek.fileName}', leWeek.storyName);
		txtWeekTitle.text = leName.toUpperCase();
		txtWeekTitle.y = 100;
		txtWeekTitle.x = (FlxG.width - txtWeekTitle.width) * 0.5;
		txtWeekTitle.color = getAdaptiveWeekTitleColor(leWeek);

		curDifficulty = getNormalDifficultyIndex(leWeek);

		refreshWeekVisuals();
		layoutWeeks();
		updateBackgroundColor(leWeek);
		return true;
	}

	function refreshWeekVisuals():Void
	{
		for (num => item in grpWeekText.members)
		{
			var locked:Bool = weekIsLocked(loadedWeeks[num].fileName);
			var selected:Bool = (num == curWeek);
			item.alpha = selected ? (locked ? 0.75 : 1) : (locked ? 0.45 : 0.65);

			var targetScale:Float = item.baseScale * (selected ? 1.08 : 1);
			if (weekScaleTweens[num] != null)
				weekScaleTweens[num].cancel();
			weekScaleTweens[num] = FlxTween.tween(item.scale, {x: targetScale, y: targetScale}, selected ? 0.56 : 0.34, {
				ease: selected ? FlxEase.backOut : FlxEase.quadOut
			});
		}
	}

	function layoutWeeks():Void
	{
		if (grpWeekText.length < 1)
			return;

		var maxWidth:Float = 0;
		for (item in grpWeekText.members)
		{
			if (item == null) continue;
			maxWidth = Math.max(maxWidth, item.baseDisplayWidth);
		}

		var topY:Float = txtWeekTitle.y + txtWeekTitle.height + 45;
		var centerY:Float = topY + ((FlxG.height - topY) * 0.5);
		var centerX:Float = FlxG.width * 0.5;
		var spacingX:Float = maxWidth + 50;

		weekTargetX = [];
		weekTargetY = [];
		for (i in 0...grpWeekText.length)
		{
			var item:MenuItem = grpWeekText.members[i];
			if (item == null) continue;

			var relativePos:Float = i - curWeek;

			var centerPosX:Float = centerX + (relativePos * spacingX);

			weekTargetX[i] = centerPosX;
			weekTargetY[i] = centerY;

			if (item.x == 0 && item.y == 0)
			{
				item.x = weekTargetX[i] - (item.width * 0.5);
				item.y = weekTargetY[i] - (item.height * 0.5);
			}
		}
	}

	function updateWeekPositions(elapsed:Float):Void
	{
		for (i => item in grpWeekText.members)
		{
			if (item == null) continue;
			if (i >= weekTargetX.length || i >= weekTargetY.length) continue;

			var targetX:Float = weekTargetX[i] - (item.width * 0.5);
			var targetY:Float = weekTargetY[i] - (item.height * 0.5);
			item.x = FlxMath.lerp(targetX, item.x, Math.exp(-elapsed * 12));
			item.y = FlxMath.lerp(targetY, item.y, Math.exp(-elapsed * 12));
		}
	}

	function updateBackgroundColor(week:WeekData):Void
	{
		var targetColor:FlxColor = getWeekBackgroundColor(week);
		if (bgColorTween != null)
			bgColorTween.cancel();
		bgColorTween = FlxTween.color(scrollingBg, 0.35, scrollingBg.color, targetColor, {ease: FlxEase.quadOut});
	}

	function getWeekBackgroundColor(week:WeekData):FlxColor
	{
		var bgColor:Array<Int> = week.story_bg_color;
		if (bgColor == null || bgColor.length < 3)
			return FlxColor.WHITE;
		return FlxColor.fromRGB(clampColorChannel(bgColor[0]), clampColorChannel(bgColor[1]), clampColorChannel(bgColor[2]));
	}

	function clampColorChannel(value:Int):Int
	{
		if (value < 0) return 0;
		if (value > 255) return 255;
		return value;
	}

	function getAdaptiveWeekTitleColor(week:WeekData):FlxColor
	{
		var bgColor:Array<Int> = week.story_bg_color;
		if (bgColor == null || bgColor.length < 3)
			return FlxColor.BLACK;

		var baseRed:Int = clampColorChannel(bgColor[0]);
		var baseGreen:Int = clampColorChannel(bgColor[1]);
		var baseBlue:Int = clampColorChannel(bgColor[2]);

		// Use luma to decide if the background tint is light or dark.
		var luma:Float = (0.2126 * baseRed) + (0.7152 * baseGreen) + (0.0722 * baseBlue);
		var red:Int = 0;
		var green:Int = 0;
		var blue:Int = 0;

		if (luma >= 140)
		{
			// Light background -> darker text color.
			red = Std.int(baseRed * 0.35);
			green = Std.int(baseGreen * 0.35);
			blue = Std.int(baseBlue * 0.35);
		}
		else
		{
			// Dark background -> lighter text color.
			red = Std.int(baseRed + ((255 - baseRed) * 0.65));
			green = Std.int(baseGreen + ((255 - baseGreen) * 0.65));
			blue = Std.int(baseBlue + ((255 - baseBlue) * 0.65));
		}
		return FlxColor.fromRGB(red, green, blue);
	}

	function getNormalDifficultyIndex(week:WeekData):Int
	{
		Difficulty.loadFromWeek(week);
		var defaultPath:String = Paths.formatToSongPath(Difficulty.getDefault());
		for (i in 0...Difficulty.list.length)
		{
			if (Paths.formatToSongPath(Difficulty.list[i]) == defaultPath)
				return i;
		}
		return 0;
	}

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0
			&& (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
	}

	function selectWeek()
	{
		if (!weekIsLocked(loadedWeeks[curWeek].fileName))
		{
			var songArray:Array<String> = [];
			var leWeek:Array<Dynamic> = loadedWeeks[curWeek].songs;
			var selectedIndex:Int = curWeek;
			for (i in 0...leWeek.length)
				songArray.push(leWeek[i][0]);

			try
			{
				PlayState.storyPlaylist = songArray;
				PlayState.isStoryMode = true;
				selectedWeek = true;

				var diffic = Difficulty.getFilePath(curDifficulty);
				if (diffic == null) diffic = '';

				PlayState.storyDifficulty = curDifficulty;

				Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
				PlayState.campaignScore = 0;
				PlayState.campaignMisses = 0;
			}
			catch (e:Dynamic)
			{
				trace('ERROR! $e');
				selectedWeek = false;
				stopspamming = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				return;
			}

			if (!stopspamming)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				var selectedItem:MenuItem = grpWeekText.members[selectedIndex];
				selectedItem.isFlashing = true;

				if (weekScaleTweens[selectedIndex] != null)
					weekScaleTweens[selectedIndex].cancel();

				weekScaleTweens[selectedIndex] = FlxTween.tween(selectedItem.scale, {x: selectedItem.baseScale * 0.5, y: selectedItem.baseScale * 0.5}, 0.16, {
					ease: FlxEase.quadIn,
					onComplete: function(_) {
						weekScaleTweens[selectedIndex] = FlxTween.tween(selectedItem.scale, {x: selectedItem.baseScale, y: selectedItem.baseScale}, 0.58, {
							ease: FlxEase.backOut
						});
					}
				});

				stopspamming = true;
			}

			var directory = StageData.forceNextDirectory;
			LoadingState.loadNextDirectory();
			StageData.forceNextDirectory = directory;

			@:privateAccess
			if (PlayState._lastLoadedModDirectory != Mods.currentModDirectory)
			{
				trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
				Paths.freeGraphicsFromMemory();
			}

			LoadingState.prepareToSong();
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
				LoadingState.loadAndSwitchState(new PlayState(), true);
				FreeplayState.destroyFreeplayVocals();
			});

			#if (MODS_ALLOWED && DISCORD_ALLOWED)
			DiscordClient.loadModRPC();
			#end
		}
		else FlxG.sound.play(Paths.sound('cancelMenu'));
	}
}
