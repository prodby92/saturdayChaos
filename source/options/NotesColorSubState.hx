package options;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;
import lime.system.Clipboard;
import flixel.util.FlxGradient;
import objects.Note;
import objects.StrumNote;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

class NotesColorSubState extends MusicBeatSubstate
{
	var onModeColumn:Bool = true;
	var curSelectedMode:Int = 0;
	var curSelectedNote:Int = 0;
	var onPixel:Bool = false;
	var dataArray:Array<Array<FlxColor>>;
	var rgbEditorDisplayOrder:Array<Int> = [0, 1, 2, 3, 4, 5];

	var hexTypeLine:FlxSprite;
	var hexTypeNum:Int = -1;
	var hexTypeVisibleTimer:Float = 0;

	var copyButton:FlxSprite;
	var pasteButton:FlxSprite;

	var colorGradient:FlxSprite;
	var colorGradientSelector:FlxSprite;
	var colorPalette:FlxSprite;
	var colorWheel:FlxSprite;
	var colorWheelSelector:FlxSprite;

	var alphabetR:Alphabet;
	var alphabetG:Alphabet;
	var alphabetB:Alphabet;
	var alphabetHex:Alphabet;

	var modeBG:FlxSprite;
	var notesBG:FlxSprite;

	// controller support
	var controllerPointer:FlxSprite;
	var _lastControllerMode:Bool = false;
	var tipTxt:FlxText;

	public function new() {
		super();
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Note Colors Menu", null);
		#end
		
		onPixel = PlayState.isPixelStage;
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFEA71FD;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
		grid.velocity.set(40, 40);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		add(grid);

		modeBG = new FlxSprite(215, 85).makeGraphic(315, 115, FlxColor.BLACK);
		modeBG.visible = false;
		modeBG.alpha = 0.4;
		add(modeBG);

		notesBG = new FlxSprite(65, 190).makeGraphic(620, 125, FlxColor.BLACK);
		notesBG.visible = false;
		notesBG.alpha = 0.4;
		add(notesBG);

		modeNotes = new FlxTypedGroup<FlxSprite>();
		add(modeNotes);

		myNotes = new FlxTypedGroup<Note>();
		add(myNotes);

		var bg:FlxSprite = new FlxSprite(720).makeGraphic(FlxG.width - 720, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.25;
		add(bg);
		var bg:FlxSprite = new FlxSprite(750, 160).makeGraphic(FlxG.width - 780, 540, FlxColor.BLACK);
		bg.alpha = 0.25;
		add(bg);
		
		var text:Alphabet = new Alphabet(50, 86, 'CTRL', false);
		text.alignment = CENTERED;
		text.setScale(0.4);
		add(text);

		copyButton = new FlxSprite(760, 50).loadGraphic(Paths.image('noteColorMenu/copy'));
		copyButton.alpha = 0.6;
		add(copyButton);

		pasteButton = new FlxSprite(1180, 50).loadGraphic(Paths.image('noteColorMenu/paste'));
		pasteButton.alpha = 0.6;
		add(pasteButton);

		colorGradient = FlxGradient.createGradientFlxSprite(60, 360, [FlxColor.WHITE, FlxColor.BLACK]);
		colorGradient.setPosition(780, 200);
		add(colorGradient);

		colorGradientSelector = new FlxSprite(770, 200).makeGraphic(80, 10, FlxColor.WHITE);
		colorGradientSelector.offset.y = 5;
		add(colorGradientSelector);

		colorPalette = new FlxSprite(820, 580).loadGraphic(Paths.image('noteColorMenu/palette', false));
		colorPalette.scale.set(20, 20);
		colorPalette.updateHitbox();
		colorPalette.antialiasing = false;
		add(colorPalette);
		
		colorWheel = new FlxSprite(860, 200).loadGraphic(Paths.image('noteColorMenu/colorWheel'));
		colorWheel.setGraphicSize(360, 360);
		colorWheel.updateHitbox();
		add(colorWheel);

		colorWheelSelector = new FlxShapeCircle(0, 0, 8, {thickness: 0}, FlxColor.WHITE);
		colorWheelSelector.offset.set(8, 8);
		colorWheelSelector.alpha = 0.6;
		add(colorWheelSelector);

		var txtX = 980;
		var txtY = 90;
		alphabetR = makeColorAlphabet(txtX - 100, txtY);
		add(alphabetR);
		alphabetG = makeColorAlphabet(txtX, txtY);
		add(alphabetG);
		alphabetB = makeColorAlphabet(txtX + 100, txtY);
		add(alphabetB);
		alphabetHex = makeColorAlphabet(txtX, txtY - 55);
		add(alphabetHex);
		hexTypeLine = new FlxSprite(0, 20).makeGraphic(5, 62, FlxColor.WHITE);
		hexTypeLine.visible = false;
		add(hexTypeLine);

		Note.forceEditorSixKeyPalette = true;
		spawnNotes();
		updateNotes(true);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);

		var tipX = 20;
		var tipY = 660;
		var tip:FlxText = new FlxText(tipX, tipY, 0, Language.getPhrase('note_colors_tip', 'Press RESET to Reset the selected Note Part.'), 16);
		tip.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tip.borderSize = 2;
		add(tip);

		tipTxt = new FlxText(tipX, tipY + 24, 0, '', 16);
		tipTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tipTxt.borderSize = 2;
		add(tipTxt);
		updateTip();

		controllerPointer = new FlxShapeCircle(0, 0, 20, {thickness: 0}, FlxColor.WHITE);
		controllerPointer.offset.set(20, 20);
		controllerPointer.screenCenter();
		controllerPointer.alpha = 0.6;
		add(controllerPointer);
		
		FlxG.mouse.visible = !controls.controllerMode;
		controllerPointer.visible = controls.controllerMode;
		_lastControllerMode = controls.controllerMode;
	}

	function updateTip()
	{
		var key:String = !controls.controllerMode ? Language.getPhrase('note_colors_shift', 'Shift') : Language.getPhrase('note_colors_lb', 'Left Shoulder Button');
		tipTxt.text = Language.getPhrase('note_colors_hold_tip', 'Hold {1} + Press RESET key to fully reset the selected Note.', [key]);
	}

	var _storedColor:FlxColor;
	var changingNote:Bool = false;
	var holdingOnObj:FlxSprite;
	var allowedTypeKeys:Map<FlxKey, String> = [
		ZERO => '0', ONE => '1', TWO => '2', THREE => '3', FOUR => '4', FIVE => '5', SIX => '6', SEVEN => '7', EIGHT => '8', NINE => '9',
		NUMPADZERO => '0', NUMPADONE => '1', NUMPADTWO => '2', NUMPADTHREE => '3', NUMPADFOUR => '4', NUMPADFIVE => '5', NUMPADSIX => '6',
		NUMPADSEVEN => '7', NUMPADEIGHT => '8', NUMPADNINE => '9', A => 'A', B => 'B', C => 'C', D => 'D', E => 'E', F => 'F'];

	override function update(elapsed:Float) {
		if (controls.BACK) {
			FlxG.mouse.visible = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
			return;
		}

		super.update(elapsed);

		// Early controller checking
		if(FlxG.gamepads.anyJustPressed(ANY)) controls.controllerMode = true;
		else if(FlxG.mouse.justPressed || FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0) controls.controllerMode = false;
		//
		
		var changedToController:Bool = false;
		if(controls.controllerMode != _lastControllerMode)
		{
			//trace('changed controller mode');
			FlxG.mouse.visible = !controls.controllerMode;
			controllerPointer.visible = controls.controllerMode;

			// changed to controller mid state
			if(controls.controllerMode)
			{
				controllerPointer.x = FlxG.mouse.x;
				controllerPointer.y = FlxG.mouse.y;
				changedToController = true;
			}
			// changed to keyboard mid state
			/*else
			{
				FlxG.mouse.x = controllerPointer.x;
				FlxG.mouse.y = controllerPointer.y;
			}
			// apparently theres no easy way to change mouse position that i know, oh well
			*/
			_lastControllerMode = controls.controllerMode;
			updateTip();
		}

		// controller things
		var analogX:Float = 0;
		var analogY:Float = 0;
		var analogMoved:Bool = false;
		if(controls.controllerMode && (changedToController || FlxG.gamepads.anyInput()))
		{
			for (gamepad in FlxG.gamepads.getActiveGamepads())
			{
				analogX = gamepad.getXAxis(LEFT_ANALOG_STICK);
				analogY = gamepad.getYAxis(LEFT_ANALOG_STICK);
				analogMoved = (analogX != 0 || analogY != 0);
				if(analogMoved) break;
			}
			controllerPointer.x = Math.max(0, Math.min(FlxG.width, controllerPointer.x + analogX * 1000 * elapsed));
			controllerPointer.y = Math.max(0, Math.min(FlxG.height, controllerPointer.y + analogY * 1000 * elapsed));
		}
		var controllerPressed:Bool = (controls.controllerMode && controls.ACCEPT);
		//

		if(FlxG.keys.justPressed.CONTROL)
		{
			onPixel = !onPixel;
			spawnNotes();
			updateNotes(true);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		}

		if(hexTypeNum > -1)
		{
			var keyPressed:FlxKey = cast (FlxG.keys.firstJustPressed(), FlxKey);
			hexTypeVisibleTimer += elapsed;
			var changed:Bool = false;
			if(changed = FlxG.keys.justPressed.LEFT)
				hexTypeNum--;
			else if(changed = FlxG.keys.justPressed.RIGHT)
				hexTypeNum++;
			else if(allowedTypeKeys.exists(keyPressed))
			{
				//trace('keyPressed: $keyPressed, lil str: ' + allowedTypeKeys.get(keyPressed));
				var curColor:String = alphabetHex.text;
				var newColor:String = curColor.substring(0, hexTypeNum) + allowedTypeKeys.get(keyPressed) + curColor.substring(hexTypeNum + 1);

				var colorHex:FlxColor = FlxColor.fromString('#' + newColor);
				setShaderColor(colorHex);
				_storedColor = getShaderColor();
				updateColors();
				
				// move you to next letter
				hexTypeNum++;
				changed = true;
			}
			else if(FlxG.keys.justPressed.ENTER)
				hexTypeNum = -1;
			
			var end:Bool = false;
			if(changed)
			{
				if (hexTypeNum > 5) //Typed last letter
				{
					hexTypeNum = -1;
					end = true;
					hexTypeLine.visible = false;
				}
				else
				{
					if(hexTypeNum < 0) hexTypeNum = 0;
					else if(hexTypeNum > 5) hexTypeNum = 5;
					centerHexTypeLine();
					hexTypeLine.visible = true;
				}
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}
			if(!end) hexTypeLine.visible = Math.floor(hexTypeVisibleTimer * 2) % 2 == 0;
		}
		else
		{
			var add:Int = 0;
			if(analogX == 0 && !changedToController)
			{
				if(controls.UI_LEFT_P) add = -1;
				else if(controls.UI_RIGHT_P) add = 1;
			}

			if(analogY == 0 && !changedToController && (controls.UI_UP_P || controls.UI_DOWN_P))
			{
				onModeColumn = !onModeColumn;
				modeBG.visible = onModeColumn;
				notesBG.visible = !onModeColumn;
			}
	
			if(add != 0)
			{
				if(onModeColumn) changeSelectionMode(add);
				else changeSelectionNote(add);
			}
			hexTypeLine.visible = false;
		}

		// Copy/Paste buttons
		var generalMoved:Bool = (FlxG.mouse.justMoved || analogMoved);
		var generalPressed:Bool = (FlxG.mouse.justPressed || controllerPressed);
		if(generalMoved)
		{
			copyButton.alpha = 0.6;
			pasteButton.alpha = 0.6;
		}

		if(pointerOverlaps(copyButton))
		{
			copyButton.alpha = 1;
			if(generalPressed)
			{
				Clipboard.text = getShaderColor().toHexString(false, false);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
				trace('copied: ' + Clipboard.text);
			}
			hexTypeNum = -1;
		}
		else if (pointerOverlaps(pasteButton))
		{
			pasteButton.alpha = 1;
			if(generalPressed)
			{
				var formattedText = Clipboard.text.trim().toUpperCase().replace('#', '').replace('0x', '');
				var newColor:Null<FlxColor> = FlxColor.fromString('#' + formattedText);
				//trace('#${Clipboard.text.trim().toUpperCase()}');
				if(newColor != null && formattedText.length == 6)
				{
					setShaderColor(newColor);
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
					_storedColor = getShaderColor();
					updateColors();
				}
				else //errored
					FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
			}
			hexTypeNum = -1;
		}

		// Click
		if(generalPressed)
		{
			hexTypeNum = -1;
			if (pointerOverlaps(modeNotes))
			{
				modeNotes.forEachAlive(function(note:FlxSprite) {
					if (curSelectedMode != note.ID && pointerOverlaps(note))
					{
						modeBG.visible = notesBG.visible = false;
						curSelectedMode = note.ID;
						onModeColumn = true;
						updateNotes();
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
					}
				});
			}
			else if (pointerOverlaps(myNotes))
			{
				myNotes.forEachAlive(function(note:Note) {
					if (curSelectedNote != note.ID && pointerOverlaps(note))
					{
						modeBG.visible = notesBG.visible = false;
						curSelectedNote = note.ID;
						onModeColumn = false;
						bigNote.rgbShader.parent = Note.globalRgbShaders[note.ID];
						bigNote.shader = Note.globalRgbShaders[note.ID].shader;
						updateNotes();
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
					}
				});
			}
			else if (pointerOverlaps(colorWheel)) {
				_storedColor = getShaderColor();
				holdingOnObj = colorWheel;
			}
			else if (pointerOverlaps(colorGradient)) {
				_storedColor = getShaderColor();
				holdingOnObj = colorGradient;
			}
			else if (pointerOverlaps(colorPalette)) {
				setShaderColor(colorPalette.pixels.getPixel32(
					Std.int((pointerX() - colorPalette.x) / colorPalette.scale.x), 
					Std.int((pointerY() - colorPalette.y) / colorPalette.scale.y)));
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
				updateColors();
			}
			else if (pointerOverlaps(skinNote))
			{
				onPixel = !onPixel;
				spawnNotes();
				updateNotes(true);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}
			else if(pointerY() >= hexTypeLine.y && pointerY() < hexTypeLine.y + hexTypeLine.height &&
					Math.abs(pointerX() - 1000) <= 84)
			{
				hexTypeNum = 0;
				for (letter in alphabetHex.letters)
				{
					if(letter.x - letter.offset.x + letter.width <= pointerX()) hexTypeNum++;
					else break;
				}
				if(hexTypeNum > 5) hexTypeNum = 5;
				hexTypeLine.visible = true;
				centerHexTypeLine();
			}
			else holdingOnObj = null;
		}
		// holding
		if(holdingOnObj != null)
		{
			if (FlxG.mouse.justReleased || (controls.controllerMode && controls.justReleased('accept')))
			{
				holdingOnObj = null;
				_storedColor = getShaderColor();
				updateColors();
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}
			else if (generalMoved || generalPressed)
			{
				if (holdingOnObj == colorGradient)
				{
					var newBrightness = 1 - FlxMath.bound((pointerY() - colorGradient.y) / colorGradient.height, 0, 1);
					_storedColor.alpha = 1;
					if(_storedColor.brightness == 0) //prevent bug
						setShaderColor(FlxColor.fromRGBFloat(newBrightness, newBrightness, newBrightness));
					else
						setShaderColor(FlxColor.fromHSB(_storedColor.hue, _storedColor.saturation, newBrightness));
					updateColors(_storedColor);
				}
				else if (holdingOnObj == colorWheel)
				{
					var center:FlxPoint = new FlxPoint(colorWheel.x + colorWheel.width/2, colorWheel.y + colorWheel.height/2);
					var mouse:FlxPoint = pointerFlxPoint();
					var hue:Float = FlxMath.wrap(FlxMath.wrap(Std.int(mouse.degreesTo(center)), 0, 360) - 90, 0, 360);
					var sat:Float = FlxMath.bound(mouse.dist(center) / colorWheel.width*2, 0, 1);
					//trace('$hue, $sat');
					if(sat != 0) setShaderColor(FlxColor.fromHSB(hue, sat, _storedColor.brightness));
					else setShaderColor(FlxColor.fromRGBFloat(_storedColor.brightness, _storedColor.brightness, _storedColor.brightness));
					updateColors();
				}
			} 
		}
		else if(controls.RESET && hexTypeNum < 0)
		{
			var paletteSlot:Int = getColorSlotForSelection(curSelectedNote);
			if(FlxG.keys.pressed.SHIFT || FlxG.gamepads.anyPressed(LEFT_SHOULDER))
			{
				var noteColors:Array<FlxColor> = ensureEditorColorSlot(curSelectedNote);
				// Find the note with matching ID
				var selectedNoteSprite:Note = null;
				for (note in myNotes.members)
				{
					if (note != null && note.ID == curSelectedNote)
					{
						selectedNoteSprite = note;
						break;
					}
				}
				if (selectedNoteSprite != null)
				{
					for (i in 0...3)
					{
						var strumRGB:RGBShaderReference = selectedNoteSprite.rgbShader;
						var color:FlxColor = !onPixel ? ClientPrefs.defaultData.arrowRGB[paletteSlot][i] :
														ClientPrefs.defaultData.arrowRGBPixel[paletteSlot][i];
						switch(i)
						{
							case 0:
								getShader().r = strumRGB.r = color;
							case 1:
								getShader().g = strumRGB.g = color;
							case 2:
								getShader().b = strumRGB.b = color;
						}
						if (noteColors != null)
							noteColors[i] = color;
					}
					syncEditorColorToPalette(curSelectedNote);
				}
				setShaderColor(!onPixel ? ClientPrefs.defaultData.arrowRGB[paletteSlot][curSelectedMode] : ClientPrefs.defaultData.arrowRGBPixel[paletteSlot][curSelectedMode]);
				FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
			}
			updateColors();
		}
	}

	function pointerOverlaps(obj:Dynamic)
	{
		if (!controls.controllerMode) return FlxG.mouse.overlaps(obj);
		return FlxG.overlap(controllerPointer, obj);
	}

	function pointerX():Float
	{
		if (!controls.controllerMode) return FlxG.mouse.x;
		return controllerPointer.x;
	}
	function pointerY():Float
	{
		if (!controls.controllerMode) return FlxG.mouse.y;
		return controllerPointer.y;
	}
	function pointerFlxPoint():FlxPoint
	{
		if (!controls.controllerMode) return FlxG.mouse.getScreenPosition();
		return controllerPointer.getScreenPosition();
	}

	function centerHexTypeLine()
	{
		//trace(hexTypeNum);
		if(hexTypeNum > 0)
		{
			var letter = alphabetHex.letters[hexTypeNum-1];
			hexTypeLine.x = letter.x - letter.offset.x + letter.width;
		}
		else
		{
			var letter = alphabetHex.letters[0];
			hexTypeLine.x = letter.x - letter.offset.x;
		}
		hexTypeLine.x += hexTypeLine.width;
		hexTypeVisibleTimer = 0;
	}

	function changeSelectionMode(change:Int = 0) {
		curSelectedMode += change;
		if (curSelectedMode < 0)
			curSelectedMode = 2;
		if (curSelectedMode >= 3)
			curSelectedMode = 0;

		modeBG.visible = true;
		notesBG.visible = false;
		updateNotes();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
	function changeSelectionNote(change:Int = 0) {
		var currentDisplayIndex:Int = 0;
		for (i in 0...rgbEditorDisplayOrder.length)
		{
			if (rgbEditorDisplayOrder[i] == curSelectedNote)
			{
				currentDisplayIndex = i;
				break;
			}
		}

		currentDisplayIndex += change;
		if (currentDisplayIndex < 0)
			currentDisplayIndex = rgbEditorDisplayOrder.length - 1;
		if (currentDisplayIndex >= rgbEditorDisplayOrder.length)
			currentDisplayIndex = 0;

		curSelectedNote = rgbEditorDisplayOrder[currentDisplayIndex];
		modeBG.visible = false;
		notesBG.visible = true;
		if(Note.globalRgbShaders != null && curSelectedNote < Note.globalRgbShaders.length && Note.globalRgbShaders[curSelectedNote] != null)
		{
			bigNote.rgbShader.parent = Note.globalRgbShaders[curSelectedNote];
			bigNote.shader = Note.globalRgbShaders[curSelectedNote].shader;
		}
		updateNotes();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	// alphabets
	function makeColorAlphabet(x:Float = 0, y:Float = 0):Alphabet
	{
		var text:Alphabet = new Alphabet(x, y, '', true);
		text.alignment = CENTERED;
		text.setScale(0.6);
		add(text);
		return text;
	}

	// notes sprites functions
	var skinNote:FlxSprite;
	var modeNotes:FlxTypedGroup<FlxSprite>;
	var myNotes:FlxTypedGroup<Note>;
	var bigNote:Note;
	public function spawnNotes()
	{
		try {
		dataArray = buildEditorDataArray();
		if (dataArray != null && dataArray.length < 6)
		{
			while (dataArray.length < 6)
				dataArray.push([0xFFFFFFFF, 0xFFFFFFFF, 0xFF000000]);
		}
		PlayState.stageUI = onPixel ? "pixel" : "normal";

		// clear groups
		modeNotes.forEachAlive(function(note:FlxSprite) {
			note.kill();
			note.destroy();
		});
		myNotes.forEachAlive(function(note:Note) {
			note.kill();
			note.destroy();
		});
		modeNotes.clear();
		myNotes.clear();

		if(skinNote != null)
		{
			remove(skinNote);
			skinNote.destroy();
		}
		if(bigNote != null)
		{
			remove(bigNote);
			bigNote.destroy();
		}

		// respawn stuff
		var res:Int = onPixel ? 17 : 160;
		skinNote = new FlxSprite(48, 24).loadGraphic(Paths.image('noteColorMenu/' + (onPixel ? 'notePixel' : 'note')), true, res, res);
		skinNote.antialiasing = onPixel ? false : ClientPrefs.data.antialiasing;
		skinNote.setGraphicSize(68);
		skinNote.updateHitbox();
		skinNote.animation.add('anim', [0], 24, true);
		skinNote.animation.play('anim', true);
		add(skinNote);

		var res:Int = onPixel ? 17 : 160;
		for (i in 0...3)
		{
			var modeRes:Int = onPixel ? 17 : 160;
			var newNote:FlxSprite = new FlxSprite(230 + (100 * i), 100).loadGraphic(Paths.image('noteColorMenu/' + (onPixel ? 'notePixel' : 'note')), true, modeRes, modeRes);
			newNote.antialiasing = ClientPrefs.data.antialiasing;
			newNote.setGraphicSize(85);
			newNote.updateHitbox();
			newNote.animation.add('anim', [i], 24, true);
			newNote.animation.play('anim', true);
			newNote.ID = i;
			if(onPixel) newNote.antialiasing = false;
			modeNotes.add(newNote);
		}

		Note.forceEditorSixKeyPalette = true;
		Note.globalRgbShaders = [];
		for (displayIndex in 0...rgbEditorDisplayOrder.length)
		{
			var logicalNote:Int = rgbEditorDisplayOrder[displayIndex];
			Note.initializeGlobalRGBShader(logicalNote);
			var displaySlot:Int = logicalNote;
			
			var newNote:Note = new Note(0, displaySlot, null, false, true);
			newNote.setPosition(75 + (600 / rgbEditorDisplayOrder.length * displayIndex), 200);
			newNote.antialiasing = onPixel ? false : ClientPrefs.data.antialiasing;
			if (onPixel)
			{
				newNote.reloadNote('noteSkins/NOTE_assets');
			}
			else
			{
				newNote.reloadNote();
			}
			applyPreviewNoteAnimations(newNote, displaySlot, onPixel);
			newNote.setGraphicSize(onPixel ? Std.int(newNote.width * 8.7) : 102);
			newNote.updateHitbox();
			newNote.centerOffsets();
			newNote.centerOrigin();
			newNote.ID = logicalNote;
			myNotes.add(newNote);
		}

		bigNote = new Note(0, 0, null, false, true);
		bigNote.setPosition(250, 325);
		bigNote.setGraphicSize(250);
		bigNote.updateHitbox();
		for (i in 0...6)
		{
			var previewAnim:String = 'note$i';
			if (!onPixel)
			{
				var previewPrefix:String = switch (i)
				{
					case 0: 'purple0';
					case 1: 'green0';
					case 2: 'red0';
					case 3: 'purple0';
					case 4: 'blue0';
					case 5: 'red0';
					default: 'purple0';
				};
				bigNote.animation.addByPrefix(previewAnim, previewPrefix, 24, true);
			}
			else
			{
				var frameData:Array<Int> = switch (i)
				{
					case 0: [4];
					case 1: [6];
					case 2: [7];
					case 3: [4];
					case 4: [5];
					case 5: [7];
					default: [4];
				};
				bigNote.animation.add(previewAnim, frameData, 24, true);
			}
		}
		insert(members.indexOf(myNotes) + 1, bigNote);
		curSelectedNote = rgbEditorDisplayOrder[0];
		// Now that curSelectedNote is set, update the bigNote shader references
		if(Note.globalRgbShaders != null && curSelectedNote < Note.globalRgbShaders.length && Note.globalRgbShaders[curSelectedNote] != null)
		{
			bigNote.rgbShader.parent = Note.globalRgbShaders[curSelectedNote];
			bigNote.shader = Note.globalRgbShaders[curSelectedNote].shader;
		}
		_storedColor = getShaderColor();
		PlayState.stageUI = "normal";
		} catch(e:Dynamic) {
			trace('ERROR in spawnNotes: $e');
			trace(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
		}
	}

	function applyPreviewNoteAnimations(note:Note, noteData:Int, isPixel:Bool)
	{
		if (note == null || note.animation == null)
			return;

		if (isPixel)
		{
			var frameData:Int = switch (Math.abs(noteData) % 6)
			{
				case 0: 4; // Left
				case 1: 6; // Up
				case 2: 7; // Right
				case 3: 4; // Back
				case 4: 5; // Down
				case 5: 7; // Forward
				default: 4;
			};
			note.animation.add('static', [frameData], 24, true);
			note.animation.add('confirm', [frameData], 24, false);
		}
		else
		{
			var visualColorKey:String = Note.getVisualColorKeyForLane(noteData, false);
			var confirmPrefix:String = 'left confirm';
			switch (Math.abs(noteData) % 4)
			{
				case 1: confirmPrefix = 'up confirm';
				case 2: confirmPrefix = 'right confirm';
				case 3: confirmPrefix = 'down confirm';
			}
			note.animation.addByPrefix('static', visualColorKey + '0', 24, true);
			note.animation.addByPrefix('confirm', confirmPrefix, 24, false);
		}

		note.animation.play('static', true);
		refreshPreviewNoteAnchor(note);
	}

	function refreshPreviewNoteAnchor(note:Note)
	{
		if (note == null)
			return;
		note.centerOffsets();
		note.centerOrigin();
		note.updateHitbox();
	}

	function updateNotes(?instant:Bool = false)
	{
		for (note in modeNotes)
			if(note != null) note.alpha = (curSelectedMode == note.ID) ? 1 : 0.6;

		for (note in myNotes)
		{
			if(note == null || note.animation == null) continue;
			
			var isSelected:Bool = (curSelectedNote == note.ID);
			var isHovered:Bool = pointerOverlaps(note);
			var shouldConfirm:Bool = isHovered;
			note.alpha = shouldConfirm || isSelected ? 1 : 0.6;
			if (shouldConfirm)
			{
				note.animation.play('confirm', true);
			}
			else
			{
				note.animation.play('static', true);
			}
			refreshPreviewNoteAnchor(note);
			if(instant && note.animation.curAnim != null) note.animation.curAnim.finish();
		}
		if(bigNote != null && bigNote.animation != null)
			bigNote.animation.play('note$curSelectedNote', true);
		updateColors();
	}

	function updateColors(specific:Null<FlxColor> = null)
	{
		var color:FlxColor = getShaderColor();
		var wheelColor:FlxColor = specific == null ? getShaderColor() : specific;
		alphabetR.text = Std.string(color.red);
		alphabetG.text = Std.string(color.green);
		alphabetB.text = Std.string(color.blue);
		alphabetHex.text = color.toHexString(false, false);
		for (letter in alphabetHex.letters) letter.color = color;

		colorWheel.color = FlxColor.fromHSB(0, 0, color.brightness);
		colorWheelSelector.setPosition(colorWheel.x + colorWheel.width/2, colorWheel.y + colorWheel.height/2);
		if(wheelColor.brightness != 0)
		{
			var hueWrap:Float = wheelColor.hue * Math.PI / 180;
			colorWheelSelector.x += Math.sin(hueWrap) * colorWheel.width/2 * wheelColor.saturation;
			colorWheelSelector.y -= Math.cos(hueWrap) * colorWheel.height/2 * wheelColor.saturation;
		}
		colorGradientSelector.y = colorGradient.y + colorGradient.height * (1 - color.brightness);

		// Find the note with matching ID
		var selectedNoteSprite:Note = null;
		for (note in myNotes.members)
		{
			if (note != null && note.ID == curSelectedNote)
			{
				selectedNoteSprite = note;
				break;
			}
		}

		if (selectedNoteSprite == null)
			return; // Safety check
		
		var strumRGB:RGBShaderReference = selectedNoteSprite.rgbShader;
		switch(curSelectedMode)
		{
			case 0:
				getShader().r = strumRGB.r = color;
			case 1:
				getShader().g = strumRGB.g = color;
			case 2:
				getShader().b = strumRGB.b = color;
		}
	}

	function getEditorPaletteArray():Array<Array<FlxColor>>
	{
		return !onPixel ? ClientPrefs.data.arrowRGB : ClientPrefs.data.arrowRGBPixel;
	}

	function shouldUseSixKeyEditorPalette():Bool
	{
		return true;
	}

	function getColorSlotForSelection(noteIndex:Int):Int
	{
		switch (noteIndex)
		{
			case 0: return Note.getPaletteIndexForColorName('purple');
			case 1: return Note.getPaletteIndexForColorName('green');
			case 2: return Note.getPaletteIndexForColorName('red');
			case 3: return Note.getPaletteIndexForColorName('yellow');
			case 4: return Note.getPaletteIndexForColorName('blue');
			case 5: return Note.getPaletteIndexForColorName('navy');
			default: return Note.getPaletteIndexForColorName('purple');
		}
	}

	function buildEditorDataArray():Array<Array<FlxColor>>
	{
		var paletteArray:Array<Array<FlxColor>> = getEditorPaletteArray();
		var laneColors:Array<Array<FlxColor>> = [];
		var laneCount:Int = shouldUseSixKeyEditorPalette() ? 6 : 4;
		for (laneIndex in 0...laneCount)
		{
			var paletteSlot:Int = getColorSlotForSelection(laneIndex);
			var sourceEntry:Array<FlxColor> = null;
			if (paletteArray != null && paletteSlot >= 0 && paletteSlot < paletteArray.length)
				sourceEntry = paletteArray[paletteSlot];
			if (sourceEntry == null)
				sourceEntry = [0xFFFFFFFF, 0xFFFFFFFF, 0xFF000000];
			laneColors.push([sourceEntry[0], sourceEntry[1], sourceEntry[2]]);
		}
		return laneColors;
	}

	function ensureEditorColorSlot(noteIndex:Int):Array<FlxColor>
	{
		if (dataArray == null) dataArray = buildEditorDataArray();
		if (dataArray == null) return null;
		while (dataArray.length <= noteIndex)
			dataArray.push([0xFFFFFFFF, 0xFFFFFFFF, 0xFF000000]);
		if (dataArray[noteIndex] == null)
			dataArray[noteIndex] = [0xFFFFFFFF, 0xFFFFFFFF, 0xFF000000];
		while (dataArray[noteIndex].length < 3)
			dataArray[noteIndex].push(0xFF000000);
		return dataArray[noteIndex];
	}

	function syncEditorColorToPalette(noteIndex:Int)
	{
		var laneColors:Array<FlxColor> = ensureEditorColorSlot(noteIndex);
		if (laneColors == null) return;
		var paletteSlot:Int = getColorSlotForSelection(noteIndex);
		var paletteArray:Array<Array<FlxColor>> = !onPixel ? ClientPrefs.data.arrowRGB : ClientPrefs.data.arrowRGBPixel;
		if (paletteArray == null) return;
		while (paletteArray.length <= paletteSlot)
			paletteArray.push([0xFFFFFFFF, 0xFFFFFFFF, 0xFF000000]);
		if (paletteArray[paletteSlot] == null)
			paletteArray[paletteSlot] = [0xFFFFFFFF, 0xFFFFFFFF, 0xFF000000];
		while (paletteArray[paletteSlot].length < 3)
			paletteArray[paletteSlot].push(0xFF000000);
		paletteArray[paletteSlot][0] = laneColors[0];
		paletteArray[paletteSlot][1] = laneColors[1];
		paletteArray[paletteSlot][2] = laneColors[2];
	}

	function setShaderColor(value:FlxColor)
	{
		var noteColors:Array<FlxColor> = ensureEditorColorSlot(curSelectedNote);
		if (noteColors == null) return;
		noteColors[curSelectedMode] = value;
		syncEditorColorToPalette(curSelectedNote);
	}
	function getShaderColor()
	{
		var noteColors:Array<FlxColor> = ensureEditorColorSlot(curSelectedNote);
		if (noteColors == null) return FlxColor.WHITE;
		return noteColors[curSelectedMode];
	}
	function getShader() return Note.globalRgbShaders[curSelectedNote];

	override function destroy()
	{
		Note.forceEditorSixKeyPalette = false;
		Note.globalRgbShaders = [];
		super.destroy();
	}
}
