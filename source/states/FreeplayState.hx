package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import objects.HealthIcon;
import objects.MusicPlayer;

import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import flixel.addons.display.FlxBackdrop;
import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;

import openfl.utils.Assets;

import haxe.Json;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	private static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var bottomString:String;
	var bottomText:FlxText;
	var bottomBG:FlxSprite;

	var player:MusicPlayer;
	var rightDisk:FlxSprite;
	var diskBaseX:Float = 0;
	var diskBaseY:Float = 0;
	var diskFloatTime:Float = 0;
	var diskFloatAmplitude:Float = 14;
	var diskFloatSpeed:Float = 2.2;
	var diskBaseScale:Float = 2;
	var iconBaseScale:Float = 1.5;
	var iconYOffset:Float = 20;
	var selectedIcon:HealthIcon = null;
	var confirmingSong:Bool = false;

	override function create()
	{
		//Paths.clearStoredMemory();
		//Paths.clearUnusedMemory();
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("gettin backshotted rn", null);
		#end

		if(WeekData.weeksList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState("NO WEEKS ADDED FOR FREEPLAY\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
				function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
				function() MusicBeatState.switchState(new states.MainMenuState())));
			return;
		}

		for (i in 0...WeekData.weeksList.length)
		{
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		Mods.loadTopMod();

		bg = new FlxBackdrop(Paths.image('bgsleepyDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set();
		bg.velocity.set(30, 30);
		add(bg);
		createDiskSprites();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, 320, songs[i].songName, true);
			songText.targetY = i;
			songText.distancePerItem.x = 0;
			grpSongs.add(songText);

			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.x = Math.floor((FlxG.width - songText.width) / 2);
			songText.startPosition.x = songText.x;
			songText.snapToPosition();

			Mods.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = null;
			icon.scale.set(iconBaseScale, iconBaseScale);
			icon.updateHitbox();

			
			// too laggy with a lot of songs, so i had to recode the logic for it
			songText.visible = songText.active = songText.isMenuItem = false;
			icon.visible = icon.active = false;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}
		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(0, 48, 0, "", 32);
		scoreText.setFormat(Paths.font("noto.ttf"), 32, FlxColor.WHITE, CENTER);

		scoreBG = new FlxSprite(0, scoreText.y - 6).makeGraphic(10, 72, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);


		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("noto.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;
		lerpSelected = curSelected;

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		bottomBG.alpha = 0.6;
		add(bottomBG);

		var leText:String = Language.getPhrase("freeplay_tip", "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.");
		bottomString = leText;
		var size:Int = 16;
		bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, leText, size);
		bottomText.setFormat(Paths.font("noto.ttf"), size, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();
		add(bottomText);
		
		player = new MusicPlayer(this);
		add(player);
		
		changeSelection();
		updateTexts();
		super.create();
		bounceVisibleSongTexts(getConfirmTweenDuration(0.25));
	}

	override function closeSubState()
	{
		changeSelection(0, false, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	override function beatHit()
	{
		super.beatHit();
		if(!confirmingSong)
			pulseConfirmElements(getConfirmTweenDuration(0.3));
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;
	var holdTime:Float = 0;

	var stopMusicPlay:Bool = false;
	override function update(elapsed:Float)
	{
		if(WeekData.weeksList.length < 1)
			return;

		if(rightDisk != null)
		{
			diskFloatTime += elapsed * diskFloatSpeed;
			rightDisk.y = diskBaseY + Math.sin(diskFloatTime) * diskFloatAmplitude;
		}

		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * elapsed;

		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) //No decimals, add an empty space
			ratingSplit.push('');
		
		while(ratingSplit[1].length < 2) //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if (!player.playingMusic)
		{
			scoreText.text = Language.getPhrase('personal_best', 'PERSONAL BEST: {1} ({2}%)', [lerpScore, ratingSplit.join('.')]);
			positionHighscore();

			if(!confirmingSong)
			{
				if(songs.length > 1)
				{
					if(FlxG.keys.justPressed.HOME)
					{
						curSelected = 0;
						changeSelection();
						holdTime = 0;	
					}
					else if(FlxG.keys.justPressed.END)
					{
						curSelected = songs.length - 1;
						changeSelection();
						holdTime = 0;	
					}
					if (controls.UI_UP_P)
					{
						changeSelection(-shiftMult);
						holdTime = 0;
					}
					if (controls.UI_DOWN_P)
					{
						changeSelection(shiftMult);
						holdTime = 0;
					}

					if(controls.UI_DOWN || controls.UI_UP)
					{
						var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
						holdTime += elapsed;
						var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

						if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
							changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					}

					if(FlxG.mouse.wheel != 0)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
						changeSelection(-shiftMult * FlxG.mouse.wheel, false);
					}
				}

				if (controls.UI_LEFT_P)
				{
					changeDiff(-1);
					_updateSongLastDifficulty();
				}
				else if (controls.UI_RIGHT_P)
				{
					changeDiff(1);
					_updateSongLastDifficulty();
				}
			}
		}

		if (!confirmingSong && controls.BACK)
		{
			if (player.playingMusic)
			{
				FlxG.sound.music.stop();
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				instPlaying = -1;

				player.playingMusic = false;
				player.switchPlayMusic();

				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
			}
			else 
			{
				persistentUpdate = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}
		}

		if(!confirmingSong && FlxG.keys.justPressed.CONTROL && !player.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if(!confirmingSong && FlxG.keys.justPressed.SPACE)
		{
			if(instPlaying != curSelected && !player.playingMusic)
			{
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;

				Mods.currentModDirectory = songs[curSelected].folder;
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				if (PlayState.SONG.needsVoices)
				{
					vocals = new FlxSound();
					try
					{
						var playerVocals:String = getVocalFromCharacter(PlayState.SONG.player1);
						var loadedVocals = Paths.voices(PlayState.SONG.song, (playerVocals != null && playerVocals.length > 0) ? playerVocals : 'Player');
						if(loadedVocals == null) loadedVocals = Paths.voices(PlayState.SONG.song);
						
						if(loadedVocals != null && loadedVocals.length > 0)
						{
							vocals.loadEmbedded(loadedVocals);
							FlxG.sound.list.add(vocals);
							vocals.persist = vocals.looped = true;
							vocals.volume = 0.8;
							vocals.play();
							vocals.pause();
						}
						else vocals = FlxDestroyUtil.destroy(vocals);
					}
					catch(e:Dynamic)
					{
						vocals = FlxDestroyUtil.destroy(vocals);
					}
					
					opponentVocals = new FlxSound();
					try
					{
						//trace('please work...');
						var oppVocals:String = getVocalFromCharacter(PlayState.SONG.player2);
						var loadedVocals = Paths.voices(PlayState.SONG.song, (oppVocals != null && oppVocals.length > 0) ? oppVocals : 'Opponent');
						
						if(loadedVocals != null && loadedVocals.length > 0)
						{
							opponentVocals.loadEmbedded(loadedVocals);
							FlxG.sound.list.add(opponentVocals);
							opponentVocals.persist = opponentVocals.looped = true;
							opponentVocals.volume = 0.8;
							opponentVocals.play();
							opponentVocals.pause();
							//trace('yaaay!!');
						}
						else opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
					}
					catch(e:Dynamic)
					{
						//trace('FUUUCK');
						opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
					}
				}

				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.8);
				FlxG.sound.music.pause();
				instPlaying = curSelected;

				player.playingMusic = true;
				player.curTime = 0;
				player.switchPlayMusic();
				player.pauseOrResume(true);
			}
			else if (instPlaying == curSelected && player.playingMusic)
			{
				player.pauseOrResume(!player.playing);
			}
		}
		else if (!confirmingSong && controls.ACCEPT && !player.playingMusic)
		{
			confirmSelectedSong();
		}
		else if(!confirmingSong && controls.RESET && !player.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		updateTexts(elapsed);
		super.update(elapsed);
	}
	
	function getVocalFromCharacter(char:String)
	{
		try
		{
			var path:String = Paths.getPath('characters/$char.json', TEXT);
			#if MODS_ALLOWED
			var character:Dynamic = Json.parse(File.getContent(path));
			#else
			var character:Dynamic = Json.parse(Assets.getText(path));
			#end
			return character.vocals_file;
		}
		catch (e:Dynamic) {}
		return null;
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) vocals.stop();
		vocals = FlxDestroyUtil.destroy(vocals);

		if(opponentVocals != null) opponentVocals.stop();
		opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
	}

	private function getConfirmTweenDuration(baseDuration:Float = 0.3):Float
	{
		// Reference BPM from TitleState default.
		var refBpm:Float = 180;
		var bpm:Float = (Conductor.bpm > 0 ? Conductor.bpm : refBpm);
		return FlxMath.bound(baseDuration * (refBpm / bpm), 0.12, 0.8);
	}

	private function pulseConfirmElements(duration:Float)
	{
		if(selectedIcon != null && selectedIcon.visible)
		{
			FlxTween.cancelTweensOf(selectedIcon.scale);
			selectedIcon.scale.set(iconBaseScale * 1.2, iconBaseScale * 1.2);
			selectedIcon.updateHitbox();
			FlxTween.tween(selectedIcon.scale, {x: iconBaseScale, y: iconBaseScale}, duration, {
				ease: FlxEase.expoOut,
				onUpdate: function(_) selectedIcon.updateHitbox()
			});
		}

		if(rightDisk != null)
		{
			FlxTween.cancelTweensOf(rightDisk.scale);
			rightDisk.scale.set(diskBaseScale * 1.2, diskBaseScale * 1.2);
			rightDisk.updateHitbox();
			FlxTween.tween(rightDisk.scale, {x: diskBaseScale, y: diskBaseScale}, duration, {
				ease: FlxEase.expoOut,
				onUpdate: function(_) rightDisk.updateHitbox()
			});
		}

		for (item in grpSongs.members)
		{
			if(item == null || !item.visible) continue;
			var baseX:Float = item.scaleX;
			var baseY:Float = item.scaleY;
			item.scaleX = baseX * 1.2;
			item.scaleY = baseY * 1.2;
			FlxTween.cancelTweensOf(item);
			FlxTween.tween(item, {scaleX: baseX, scaleY: baseY}, duration, {ease: FlxEase.expoOut});
		}
	}

	private function bounceVisibleSongTexts(duration:Float)
	{
		for (item in grpSongs.members)
		{
			if(item == null || !item.visible) continue;
			var baseX:Float = item.scaleX;
			var baseY:Float = item.scaleY;
			item.scaleX = baseX * 1.2;
			item.scaleY = baseY * 1.2;
			FlxTween.cancelTweensOf(item);
			FlxTween.tween(item, {scaleX: baseX, scaleY: baseY}, duration, {ease: FlxEase.expoOut});
		}
	}

	private function finishSongSelection()
	{
		persistentUpdate = false;

		@:privateAccess
		if(PlayState._lastLoadedModDirectory != Mods.currentModDirectory)
		{
			trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
			Paths.freeGraphicsFromMemory();
		}
		LoadingState.prepareToSong();
		LoadingState.loadAndSwitchState(new PlayState());
		#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
		stopMusicPlay = true;

		destroyFreeplayVocals();
		#if (MODS_ALLOWED && DISCORD_ALLOWED)
		DiscordClient.loadModRPC();
		#end
	}

	private function confirmSelectedSong()
	{
		var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
		var poop:String = Highscore.formatSong(songLowercase, curDifficulty);

		try
		{
			Song.loadFromJson(poop, songLowercase);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;
			trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
		}
		catch(e:haxe.Exception)
		{
			trace('ERROR! ${e.message}');

			var errorStr:String = e.message;
			if(errorStr.contains('There is no TEXT asset with an ID of')) errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length-1); //Missing chart
			else errorStr += '\n\n' + e.stack;

			missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
			missingText.screenCenter(Y);
			missingText.visible = true;
			missingTextBG.visible = true;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return;
		}

		confirmingSong = true;
		var tweenDuration:Float = getConfirmTweenDuration(0.3);
		pulseConfirmElements(tweenDuration);

		if(selectedIcon != null && selectedIcon.visible)
		{
			FlxTween.cancelTweensOf(selectedIcon);
			FlxTween.tween(selectedIcon, {x: FlxG.width + selectedIcon.width + 40}, tweenDuration, {ease: FlxEase.expoIn});
		}

		if(rightDisk != null)
		{
			FlxTween.cancelTweensOf(rightDisk);
			FlxTween.tween(rightDisk, {x: -rightDisk.width - 40}, tweenDuration, {ease: FlxEase.expoIn});
		}

		new FlxTimer().start(tweenDuration, function(_) finishSongSelection());
	}

	function changeDiff(change:Int = 0)
	{
		if (player.playingMusic)
			return;

		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length-1);
		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty, false);
		var displayDiff:String = Difficulty.getString(curDifficulty);
		if (Difficulty.list.length > 1)
			diffText.text = '< ' + displayDiff.toUpperCase() + ' >';
		else
			diffText.text = displayDiff.toUpperCase();

		positionHighscore();
		missingText.visible = false;
		missingTextBG.visible = false;
	}

	function changeSelection(change:Int = 0, playSound:Bool = true, iconAnim:Bool = true)
	{
		if (player.playingMusic)
			return;

		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length-1);
		_updateSongLastDifficulty();
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor)
		{
			intendedColor = newColor;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 1, bg.color, intendedColor);
		}

		for (num => item in grpSongs.members)
		{
			var icon:HealthIcon = iconArray[num];
			item.alpha = 0.6;
			if (item.targetY == curSelected)
			{
				item.alpha = 1;
				showSelectedIcon(icon, iconAnim);
			}
			else
			{
				icon.visible = icon.active = false;
				FlxTween.cancelTweensOf(icon);
			}
		}
		if(selectedIcon != null && !selectedIcon.visible) selectedIcon = null;
		
		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;
		Difficulty.loadFromWeek();
		
		var savedDiff:String = songs[curSelected].lastDifficulty;
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
		if(savedDiff != null && !Difficulty.list.contains(savedDiff) && Difficulty.list.contains(savedDiff))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if(lastDiff > -1)
			curDifficulty = lastDiff;
		else if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		changeDiff();
		_updateSongLastDifficulty();
	}

	inline private function _updateSongLastDifficulty()
		songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty, false);

	private function createDiskSprites()
	{
		rightDisk = new FlxSprite();
		var atlas = Paths.getSparrowAtlas('spin');
		if(atlas != null)
		{
			rightDisk.frames = atlas;
			var frameIndexes:Array<Int> = [for(i in 0...rightDisk.frames.frames.length) i];
			if(frameIndexes.length > 0)
			{
				rightDisk.animation.add('spin', frameIndexes, 24, true);
				rightDisk.animation.play('spin');
			}
			else
			{
				rightDisk.loadGraphic(Paths.image('spin'));
			}
		}
		else
		{
			rightDisk.loadGraphic(Paths.image('spin'));
		}

		rightDisk.antialiasing = ClientPrefs.data.antialiasing;
		rightDisk.scale.set(diskBaseScale, diskBaseScale);
		rightDisk.updateHitbox();
		diskBaseX = 19 - 30;
		rightDisk.x = diskBaseX;
		diskBaseY = Math.floor((FlxG.height - rightDisk.height) / 2);
		rightDisk.y = diskBaseY;
		add(rightDisk);
	}

	private function positionHighscore()
	{
		var boxY:Float = 42;
		var boxWidth:Int = Std.int(Math.max(scoreText.width, diffText.width) + 40);
		scoreBG.setGraphicSize(boxWidth, 72);
		scoreBG.updateHitbox();
		scoreBG.x = Math.floor((FlxG.width - scoreBG.width) / 2);
		scoreBG.y = boxY;

		scoreText.x = Math.floor((FlxG.width - scoreText.width) / 2);
		scoreText.y = boxY + 6;
		diffText.x = Math.floor((FlxG.width - diffText.width) / 2);
		diffText.y = boxY + 40;
	}

	private function showSelectedIcon(icon:HealthIcon, animate:Bool = true)
	{
		selectedIcon = icon;
		icon.visible = icon.active = true;
		icon.scale.set(iconBaseScale, iconBaseScale);
		icon.updateHitbox();

		var targetX:Float = FlxG.width - icon.width - 5;
		var targetY:Float = Math.floor((FlxG.height - icon.height) / 2) + iconYOffset;
		icon.y = targetY;

		FlxTween.cancelTweensOf(icon);
		if(animate)
		{
			icon.x = targetX + 60;
			FlxTween.tween(icon, {x: targetX}, 0.3, {ease: FlxEase.expoOut});
		}
		else
		{
			icon.x = targetX;
		}
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
		for (i in _lastVisibles)
		{
			grpSongs.members[i].visible = grpSongs.members[i].active = false;
		}
		_lastVisibles = [];

		var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance)));
		for (i in min...max)
		{
			var item:Alphabet = grpSongs.members[i];
			item.visible = item.active = true;
			item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;
			_lastVisibles.push(i);
		}
	}

	override function destroy():Void
	{
		super.destroy();

		FlxG.autoPause = ClientPrefs.data.autoPause;
		if (!FlxG.sound.music.playing && !stopMusicPlay)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
	}	
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";
	public var lastDifficulty:String = null;

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}
