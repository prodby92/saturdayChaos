package states;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;

enum MainMenuColumn {
	LEFT;
	CENTER;
	RIGHT;
}

class MainMenuState extends MusicBeatState
{
	var menuAnim:FlxSprite;
	public static var psychEngineVersion:String = '1.0.4'; // This is also used for Discord RPC
	public static var curSelected:Int = 0;
	public static var curColumn:MainMenuColumn = LEFT;
	var allowMouse:Bool = true; //Turn this off to block mouse movement in menus

	var menuItems:FlxTypedGroup<FlxSprite>;
	var leftItem:FlxSprite;
	var rightItem:FlxSprite;
	var menuItemTargetY:Array<Float> = [];
	var menuBaseX:Float = 0;
	var leftTargetX:Float = 0;
	var leftTargetY:Float = 0;
	var rightTargetX:Float = 0;
	var rightTargetY:Float = 0;

	var menuLeftShift:Float = -220;
	var menuTopPadding:Float = 110;
	var menuBottomMargin:Float = 150;
	var menuDesiredSpacing:Float = 135;
	var menuMinSpacing:Float = 95;
	var menuSlideInTime:Float = 1;
	var menuSlideInStagger:Float = 0.06;
	var menuSlideInDistance:Float = 180;
	var menuSlideOutTime:Float = 1;
	var menuAnimAcceptDrop:Float = 80;
	var menuAnimBaseX:Float = 0;
	var menuAnimBaseY:Float = 0;
	var menuAnimCurrentAnim:String = "story";
	var menuAnimSwitchOutTime:Float = 0.22;
	var menuAnimSwitchInTime:Float = 0.26;
	var menuAnimSwitchOutPadding:Float = 40;
	var menuAnimSwitchOutDrop:Float = 12;
	var menuAnimExitRightPadding:Float = 120;

	var menuAnimOffsetStoryX:Float = 150;
	var menuAnimOffsetStoryY:Float = 0;
	var menuAnimOffsetFreeplayX:Float = 0;
	var menuAnimOffsetFreeplayY:Float = 0;
	var menuAnimOffsetCreditsX:Float = 0;
	var menuAnimOffsetCreditsY:Float = 0;
	var menuAnimOffsetOptionsX:Float = 0;
	var menuAnimOffsetOptionsY:Float = 0;
	var menuAnimIntroRise:Float = 120;

	var bpmBobAmplitude:Float = 6;
	var bpmBobPhaseStep:Float = 0.35;
	var hoverScale:Float = 1.05;
	var selectedScale:Float = 1.05;
	var beatPulseAmount:Float = 0.04;
	var beatPulse:Float = 0;
	var beatPulseDecay:Float = 6;
	var selectBounce:Float = 1;
	var selectBounceDecay:Float = 10;
	var selectBounceAmount:Float = 0.08;
	var selectBounceItem:FlxSprite = null;

	//Centered/Text options
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		'credits'
	];

	var leftOption:String = #if ACHIEVEMENTS_ALLOWED 'achievements' #else null #end;
	var rightOption:String = 'options';

	var magenta:FlxSprite;
	var camFollow:FlxObject;

	static var showOutdatedWarning:Bool = false;
	override function create()
	{

		super.create();

		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		persistentUpdate = persistentDraw = true;

		var bg:FlxBackdrop = new FlxBackdrop(Paths.image('bgsleepy'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set();
		bg.velocity.set(30, 30);
		add(bg);
menuAnim = new FlxSprite(FlxG.width - 500, 150);
menuAnim.frames = Paths.getSparrowAtlas("menuAnim", "shared");

menuAnim.animation.addByPrefix("story", "story", 24, true);
menuAnim.animation.addByPrefix("freeplay", "freeplay", 24, true);
menuAnim.animation.addByPrefix("options", "options", 24, true);
menuAnim.animation.addByPrefix("credits", "credits", 24, true);

menuAnim.scrollFactor.set(0, 0);
menuAnim.animation.play("story");
menuAnimBaseX = menuAnim.x;
menuAnimBaseY = menuAnim.y;
menuAnimCurrentAnim = "story";
applyMenuAnimPosition(menuAnimCurrentAnim);
var menuAnimTargetY:Float = menuAnim.y;
menuAnim.y = menuAnimTargetY + menuAnimIntroRise;
FlxTween.tween(menuAnim, {y: menuAnimTargetY}, 1, {ease: FlxEase.cubeOut});
add(menuAnim);
		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxBackdrop(Paths.image('bgsleepyMagenta'));
		magenta.antialiasing = ClientPrefs.data.antialiasing;
		magenta.scrollFactor.set();
		magenta.velocity.set(30, 30);
		magenta.visible = false;
		add(magenta);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		menuItemTargetY = [];

		menuBaseX = (FlxG.width * 0.5) + menuLeftShift;
		var availableHeight:Float = FlxG.height - menuBottomMargin - menuTopPadding;
		var spacing:Float = menuDesiredSpacing;
		if (optionShit.length > 1)
		{
			spacing = Math.min(menuDesiredSpacing, availableHeight / (optionShit.length - 1));
			spacing = Math.max(spacing, menuMinSpacing);
		}

		for (num => option in optionShit)
		{
			var item:FlxSprite = createMenuItem(option, 0, 0);
			var targetX:Float = menuBaseX - (item.width * 0.5);
			var targetY:Float = menuTopPadding + (num * spacing) + getItemYOffset(option);
			menuItemTargetY.push(targetY);

			item.x = Math.min(-item.width - 40, targetX - menuSlideInDistance);
			item.y = targetY;
			FlxTween.tween(item, {x: targetX}, menuSlideInTime, {ease: FlxEase.cubeOut, startDelay: num * menuSlideInStagger});
		}

		if (leftOption != null)
		{
			leftItem = createMenuItem(leftOption, 0, 0);
			leftTargetX = 60;
			leftTargetY = (FlxG.height - 190) + getItemYOffset(leftOption);
			leftItem.x = -leftItem.width - 40;
			leftItem.y = leftTargetY;
			FlxTween.tween(leftItem, {x: leftTargetX}, menuSlideInTime, {ease: FlxEase.cubeOut, startDelay: optionShit.length * menuSlideInStagger});
		}
		if (rightOption != null)
		{
			rightItem = createMenuItem(rightOption, 0, 0);
			rightTargetX = FlxG.width - 60 - rightItem.width;
			rightTargetY = (FlxG.height - 190) + getItemYOffset(rightOption);
			rightItem.x = FlxG.width + 40;
			rightItem.y = rightTargetY;
			FlxTween.tween(rightItem, {x: rightTargetX}, menuSlideInTime, {ease: FlxEase.cubeOut, startDelay: optionShit.length * menuSlideInStagger});
		}

		var psychVer:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		psychVer.scrollFactor.set();
		psychVer.setFormat(Paths.font("noto.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(psychVer);
		var fnfVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Saturday Chaos" + Application.current.meta.get('version'), 12);
		fnfVer.scrollFactor.set();
		fnfVer.setFormat(Paths.font("noto.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(fnfVer);
		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		#if CHECK_FOR_UPDATES
		if (showOutdatedWarning && ClientPrefs.data.checkForUpdates && substates.OutdatedSubState.updateVersion != psychEngineVersion) {
			persistentUpdate = false;
			showOutdatedWarning = false;
			openSubState(new substates.OutdatedSubState());
		}
		#end

		FlxG.camera.follow(camFollow, null, 0.15);
	}

	function createMenuItem(name:String, x:Float, y:Float):FlxSprite
	{
		var menuItem:FlxSprite = new FlxSprite(x, y);
		menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_$name');
		menuItem.animation.addByPrefix('idle', '$name idle', 24, true);
		menuItem.animation.addByPrefix('selected', '$name selected', 24, true);
		menuItem.animation.play('idle');
		menuItem.updateHitbox();
		
		menuItem.antialiasing = ClientPrefs.data.antialiasing;
		menuItem.scrollFactor.set();
		menuItems.add(menuItem);
		return menuItem;
	}

	var selectedSomethin:Bool = false;

	var timeNotMoving:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + 0.5 * elapsed, 0.8);

		if (beatPulse > 0)
			beatPulse = Math.max(0, beatPulse - elapsed * beatPulseDecay);
		if (selectBounce > 0)
			selectBounce = Math.max(0, selectBounce - elapsed * selectBounceDecay);

		if (!selectedSomethin)
		{
			updateMenuMotion(elapsed);

			if (controls.UI_UP_P)
				changeItem(-1);

			if (controls.UI_DOWN_P)
				changeItem(1);

			var allowMouseMovement:Bool = allowMouse;
			if (allowMouseMovement && ((FlxG.mouse.deltaScreenX != 0 && FlxG.mouse.deltaScreenY != 0) || FlxG.mouse.justPressed)) //FlxG.mouse.deltaScreenX/Y checks is more accurate than FlxG.mouse.justMoved
			{
				allowMouseMovement = false;
				FlxG.mouse.visible = true;
				timeNotMoving = 0;

				var selectedItem:FlxSprite;
				switch(curColumn)
				{
					case CENTER:
						selectedItem = menuItems.members[curSelected];
					case LEFT:
						selectedItem = leftItem;
					case RIGHT:
						selectedItem = rightItem;
				}

				if(leftItem != null && FlxG.mouse.overlaps(leftItem))
				{
					allowMouseMovement = true;
					if(selectedItem != leftItem)
					{
						curColumn = LEFT;
						changeItem();
					}
				}
				else if(rightItem != null && FlxG.mouse.overlaps(rightItem))
				{
					allowMouseMovement = true;
					if(selectedItem != rightItem)
					{
						curColumn = RIGHT;
						changeItem();
					}
				}
				else
				{
					var dist:Float = -1;
					var distItem:Int = -1;
					for (i in 0...optionShit.length)
					{
						var memb:FlxSprite = menuItems.members[i];
						if(FlxG.mouse.overlaps(memb))
						{
							var distance:Float = Math.sqrt(Math.pow(memb.getGraphicMidpoint().x - FlxG.mouse.screenX, 2) + Math.pow(memb.getGraphicMidpoint().y - FlxG.mouse.screenY, 2));
							if (dist < 0 || distance < dist)
							{
								dist = distance;
								distItem = i;
								allowMouseMovement = true;
							}
						}
					}

					if(distItem != -1 && selectedItem != menuItems.members[distItem])
					{
						curColumn = CENTER;
						curSelected = distItem;
						changeItem();
					}
				}
			}
			else
			{
				timeNotMoving += elapsed;
				if(timeNotMoving > 2) FlxG.mouse.visible = false;
			}

			switch(curColumn)
			{
				case CENTER:
					if(controls.UI_LEFT_P && leftOption != null)
					{
						curColumn = LEFT;
						changeItem();
					}
					else if(controls.UI_RIGHT_P && rightOption != null)
					{
						curColumn = RIGHT;
						changeItem();
					}

				case LEFT:
					if(controls.UI_RIGHT_P)
					{
						curColumn = CENTER;
						changeItem();
					}

				case RIGHT:
					if(controls.UI_LEFT_P)
					{
						curColumn = CENTER;
						changeItem();
					}
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.mouse.visible = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT || (FlxG.mouse.justPressed && allowMouseMovement))
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				selectedSomethin = true;
				FlxG.mouse.visible = false;

				if (ClientPrefs.data.flashing)
					FlxFlicker.flicker(magenta, 1.1, 0.15, false);

				var item:FlxSprite;
				var option:String;
				switch(curColumn)
				{
					case CENTER:
						option = optionShit[curSelected];
						item = menuItems.members[curSelected];

					case LEFT:
						option = leftOption;
						item = leftItem;

					case RIGHT:
						option = rightOption;
						item = rightItem;
				}

				startMenuExitAnimations(option, item);

				FlxFlicker.flicker(item, menuSlideOutTime, 0.06, false, false, function(flick:FlxFlicker)
				{
					switch (option)
					{
						case 'story_mode':
							MusicBeatState.switchState(new StoryMenuState());
						
						case 'freeplay':
							MusicBeatState.switchState(new FreeplayState());
                        
						#if MODS_ALLOWED
						case 'mods':
							MusicBeatState.switchState(new ModsMenuState());
						#end

						#if ACHIEVEMENTS_ALLOWED
						case 'achievements':
							MusicBeatState.switchState(new AchievementsMenuState());
						#end

						case 'credits':
							MusicBeatState.switchState(new CreditsState());
						case 'options':
							
							MusicBeatState.switchState(new OptionsState());
							OptionsState.onPlayState = false;
							if (PlayState.SONG != null)
							{
								PlayState.SONG.arrowSkin = null;
								PlayState.SONG.splashSkin = null;
								PlayState.stageUI = 'normal';
							}
						case 'donate':
							CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
							selectedSomethin = false;
							item.visible = true;
						default:
							trace('Menu Item ${option} doesn\'t do anything');
							selectedSomethin = false;
							item.visible = true;
					}
				});
				
				// Keep non-selected items visible; they already slide out.
			}
			#if desktop
			if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				FlxG.mouse.visible = false;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);
	}

	function changeItem(change:Int = 0)
	{
		if(change != 0) curColumn = CENTER;
		curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'));

		for (item in menuItems)
		{
			item.animation.play('idle');
			item.centerOffsets();
		}

		var selectedItem:FlxSprite;
		switch(curColumn)
		{
			case CENTER:
				selectedItem = menuItems.members[curSelected];
			case LEFT:
				selectedItem = leftItem;
			case RIGHT:
				selectedItem = rightItem;
		}
if (selectedItem != null)
{
	selectedItem.animation.play('selected');
	selectedItem.centerOffsets();
	camFollow.y = selectedItem.getGraphicMidpoint().y;
	selectBounce = 1;
	selectBounceItem = selectedItem;
}
			// Update right-side animated sprite based on selection
if (menuAnim != null)
{
	var nextAnim:String = getMenuAnimNameForSelection();
	if (nextAnim != null)
		switchMenuAnim(nextAnim);
}

	}

	function updateMenuMotion(elapsed:Float):Void
	{
		var beatTime:Float = (Conductor.songPosition / 1000) * (Conductor.bpm / 60);
		var phase:Float = beatTime * Math.PI * 2;
		var pulse:Float = 1 + (beatPulse * beatPulseAmount);
		var lerp:Float = 1 - Math.pow(0.001, elapsed);
		var selectedItem:FlxSprite = getSelectedItem();

		for (i in 0...optionShit.length)
		{
			var item:FlxSprite = menuItems.members[i];
			if (item == null)
				continue;

			var bob:Float = Math.sin(phase + (i * bpmBobPhaseStep)) * bpmBobAmplitude;
			item.y = menuItemTargetY[i] + bob;

			var hovered:Bool = allowMouse && FlxG.mouse.visible && FlxG.mouse.overlaps(item);
			var targetScale:Float = getBaseScale(item, selectedItem, hovered) * pulse;
			if (item == selectBounceItem)
				targetScale *= 1 + (selectBounce * selectBounceAmount);

			item.scale.set(
				FlxMath.lerp(item.scale.x, targetScale, lerp),
				FlxMath.lerp(item.scale.y, targetScale, lerp)
			);
		}

		if (leftItem != null)
		{
			var bob:Float = Math.sin(phase + (optionShit.length * bpmBobPhaseStep)) * bpmBobAmplitude;
			leftItem.y = leftTargetY + bob;

			var hovered:Bool = allowMouse && FlxG.mouse.visible && FlxG.mouse.overlaps(leftItem);
			var targetScale:Float = getBaseScale(leftItem, selectedItem, hovered) * pulse;
			if (leftItem == selectBounceItem)
				targetScale *= 1 + (selectBounce * selectBounceAmount);

			leftItem.scale.set(
				FlxMath.lerp(leftItem.scale.x, targetScale, lerp),
				FlxMath.lerp(leftItem.scale.y, targetScale, lerp)
			);
		}

		if (rightItem != null)
		{
			var bob:Float = Math.sin(phase + ((optionShit.length + 1) * bpmBobPhaseStep)) * bpmBobAmplitude;
			rightItem.y = rightTargetY + bob;

			var hovered:Bool = allowMouse && FlxG.mouse.visible && FlxG.mouse.overlaps(rightItem);
			var targetScale:Float = getBaseScale(rightItem, selectedItem, hovered) * pulse;
			if (rightItem == selectBounceItem)
				targetScale *= 1 + (selectBounce * selectBounceAmount);

			rightItem.scale.set(
				FlxMath.lerp(rightItem.scale.x, targetScale, lerp),
				FlxMath.lerp(rightItem.scale.y, targetScale, lerp)
			);
		}

		if (selectedItem != null)
			camFollow.y = selectedItem.getGraphicMidpoint().y;
	}

	function getBaseScale(item:FlxSprite, selectedItem:FlxSprite, hovered:Bool):Float
	{
		var scale:Float = 1;
		if (item == selectedItem)
			scale = selectedScale;
		if (hovered)
			scale = Math.max(scale, hoverScale);
		return scale;
	}

	function getSelectedItem():FlxSprite
	{
		return switch(curColumn)
		{
			case CENTER: menuItems.members[curSelected];
			case LEFT: leftItem;
			case RIGHT: rightItem;
		}
	}

	function getItemYOffset(name:String):Float
	{
		return switch(name)
		{
			case 'story_mode': -8;
			case 'freeplay': 0;
			case 'mods': 4;
			case 'credits': 10;
			case 'achievements': 4;
			case 'options': 0;
			default: 0;
		}
	}

	function startMenuExitAnimations(option:String, selectedItem:FlxSprite):Void
	{
		if (menuAnim != null)
		{
			var exitY:Float = FlxG.height + menuAnim.height + menuAnimAcceptDrop;
			FlxTween.tween(menuAnim, {x: menuAnim.x, y: exitY}, menuSlideOutTime, {ease: FlxEase.expoIn});
		}

		for (i in 0...optionShit.length)
		{
			var item:FlxSprite = menuItems.members[i];
			if (item == null)
				continue;

			var dir:Int = -1;
			var targetX:Float = item.x + dir * (FlxG.width + item.width);
			FlxTween.tween(item, {x: targetX}, menuSlideOutTime, {ease: FlxEase.expoIn});
		}

		if (leftItem != null)
		{
			var dir:Int = -1;
			var targetX:Float = leftItem.x + dir * (FlxG.width + leftItem.width);
			FlxTween.tween(leftItem, {x: targetX}, menuSlideOutTime, {ease: FlxEase.expoIn});
		}

		if (rightItem != null)
		{
			var dir:Int = 1;
			var targetX:Float = rightItem.x + dir * (FlxG.width + rightItem.width);
			FlxTween.tween(rightItem, {x: targetX}, menuSlideOutTime, {ease: FlxEase.expoIn});
		}
	}

	function getMenuAnimNameForSelection():String
	{
		if (curColumn == CENTER)
		{
			return switch(optionShit[curSelected])
			{
				case 'story_mode': "story";
				case 'freeplay': "freeplay";
				case 'credits': "credits";
				default: menuAnimCurrentAnim;
			}
		}
		else if (curColumn == RIGHT && rightOption == 'options')
		{
			return "options";
		}
		return menuAnimCurrentAnim;
	}

	function switchMenuAnim(nextAnim:String):Void
	{
		if (menuAnim == null)
			return;
		if (nextAnim == menuAnimCurrentAnim)
			return;

		menuAnimCurrentAnim = nextAnim;
		FlxTween.cancelTweensOf(menuAnim);

		var offscreenX:Float = FlxG.width + menuAnim.width + menuAnimSwitchOutPadding;
		var outY:Float = menuAnim.y + menuAnimSwitchOutDrop;
		var targetX:Float = menuAnimBaseX + getMenuAnimOffsetX(nextAnim);
		var targetY:Float = menuAnimBaseY + getMenuAnimOffsetY(nextAnim);

		FlxTween.tween(menuAnim, {x: offscreenX, y: outY}, menuAnimSwitchOutTime, {ease: FlxEase.cubeIn, onComplete: function(_)
		{
			menuAnim.animation.play(nextAnim);
			menuAnim.x = offscreenX;
			menuAnim.y = outY;
			FlxTween.tween(menuAnim, {x: targetX, y: targetY}, menuAnimSwitchInTime, {ease: FlxEase.cubeOut});
		}});
	}

	function applyMenuAnimPosition(animName:String):Void
	{
		if (menuAnim == null)
			return;
		menuAnim.x = menuAnimBaseX + getMenuAnimOffsetX(animName);
		menuAnim.y = menuAnimBaseY + getMenuAnimOffsetY(animName);
	}

	function getMenuAnimOffsetX(animName:String):Float
	{
		return switch(animName)
		{
			case "story": menuAnimOffsetStoryX;
			case "freeplay": menuAnimOffsetFreeplayX;
			case "credits": menuAnimOffsetCreditsX;
			case "options": menuAnimOffsetOptionsX;
			default: 0;
		}
	}

	function getMenuAnimOffsetY(animName:String):Float
	{
		return switch(animName)
		{
			case "story": menuAnimOffsetStoryY;
			case "freeplay": menuAnimOffsetFreeplayY;
			case "credits": menuAnimOffsetCreditsY;
			case "options": menuAnimOffsetOptionsY;
			default: 0;
		}
	}

	override function beatHit()
	{
		super.beatHit();
		if (!selectedSomethin)
			beatPulse = 1;
	}
}
