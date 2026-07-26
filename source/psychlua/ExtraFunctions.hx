package psychlua;

import flixel.util.FlxSave;
import flixel.FlxCamera;
import states.PlayState;
import openfl.utils.Assets;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.geom.Rectangle;
import openfl.geom.Matrix;
import flixel.graphics.FlxGraphic;

//
// Things to trivialize some dumb stuff like splitting strings on older Lua
//

class ExtraFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua:State = funk.lua;
		
		// Keyboard & Gamepads
		Lua_helper.add_callback(lua, "keyboardJustPressed", function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
		Lua_helper.add_callback(lua, "keyboardPressed", function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
		Lua_helper.add_callback(lua, "keyboardReleased", function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));

		Lua_helper.add_callback(lua, "anyGamepadJustPressed", function(name:String) return FlxG.gamepads.anyJustPressed(name));
		Lua_helper.add_callback(lua, "anyGamepadPressed", function(name:String) FlxG.gamepads.anyPressed(name));
		Lua_helper.add_callback(lua, "anyGamepadReleased", function(name:String) return FlxG.gamepads.anyJustReleased(name));

		Lua_helper.add_callback(lua, "gamepadAnalogX", function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return 0.0;

			return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		Lua_helper.add_callback(lua, "gamepadAnalogY", function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return 0.0;

			return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		Lua_helper.add_callback(lua, "gamepadJustPressed", function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.justPressed, name) == true;
		});
		Lua_helper.add_callback(lua, "gamepadPressed", function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.pressed, name) == true;
		});
		Lua_helper.add_callback(lua, "gamepadReleased", function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.justReleased, name) == true;
		});

		Lua_helper.add_callback(lua, "keyJustPressed", function(name:String = '') {
			name = name.toLowerCase().trim();
			switch(name) {
				case 'left': return PlayState.instance.controls.NOTE_LEFT_P;
				case 'down': return PlayState.instance.controls.NOTE_DOWN_P;
				case 'up': return PlayState.instance.controls.NOTE_UP_P;
				case 'right': return PlayState.instance.controls.NOTE_RIGHT_P;
				default: return PlayState.instance.controls.justPressed(name);
			}
			return false;
		});
		Lua_helper.add_callback(lua, "keyPressed", function(name:String = '') {
			name = name.toLowerCase().trim();
			switch(name) {
				case 'left': return PlayState.instance.controls.NOTE_LEFT;
				case 'down': return PlayState.instance.controls.NOTE_DOWN;
				case 'up': return PlayState.instance.controls.NOTE_UP;
				case 'right': return PlayState.instance.controls.NOTE_RIGHT;
				default: return PlayState.instance.controls.pressed(name);
			}
			return false;
		});
		Lua_helper.add_callback(lua, "keyReleased", function(name:String = '') {
			name = name.toLowerCase().trim();
			switch(name) {
				case 'left': return PlayState.instance.controls.NOTE_LEFT_R;
				case 'down': return PlayState.instance.controls.NOTE_DOWN_R;
				case 'up': return PlayState.instance.controls.NOTE_UP_R;
				case 'right': return PlayState.instance.controls.NOTE_RIGHT_R;
				default: return PlayState.instance.controls.justReleased(name);
			}
			return false;
		});

		// Save data management
		Lua_helper.add_callback(lua, "initSaveData", function(name:String, ?folder:String = 'psychenginemods') {
			var variables = MusicBeatState.getVariables();
			if(!variables.exists('save_$name'))
			{
				var save:FlxSave = new FlxSave();
				// folder goes unused for flixel 5 users. @BeastlyGhost
				save.bind(name, CoolUtil.getSavePath() + '/' + folder);
				variables.set('save_$name', save);
				return;
			}
			FunkinLua.luaTrace('initSaveData: Save file already initialized: ' + name);
		});
		Lua_helper.add_callback(lua, "flushSaveData", function(name:String) {
			var variables = MusicBeatState.getVariables();
			if(variables.exists('save_$name'))
			{
				variables.get('save_$name').flush();
				return;
			}
			FunkinLua.luaTrace('flushSaveData: Save file not initialized: ' + name, false, false, FlxColor.RED);
		});
		Lua_helper.add_callback(lua, "getDataFromSave", function(name:String, field:String, ?defaultValue:Dynamic = null) {
			var variables = MusicBeatState.getVariables();
			if(variables.exists('save_$name'))
			{
				var saveData = variables.get('save_$name').data;
				if(Reflect.hasField(saveData, field))
					return Reflect.field(saveData, field);
				else
					return defaultValue;
			}
			FunkinLua.luaTrace('getDataFromSave: Save file not initialized: ' + name, false, false, FlxColor.RED);
			return defaultValue;
		});
		Lua_helper.add_callback(lua, "setDataFromSave", function(name:String, field:String, value:Dynamic) {
			var variables = MusicBeatState.getVariables();
			if(variables.exists('save_$name'))
			{
				Reflect.setField(variables.get('save_$name').data, field, value);
				return;
			}
			FunkinLua.luaTrace('setDataFromSave: Save file not initialized: ' + name, false, false, FlxColor.RED);
		});
		Lua_helper.add_callback(lua, "eraseSaveData", function(name:String)
		{
			var variables = MusicBeatState.getVariables();
			if (variables.exists('save_$name'))
			{
				variables.get('save_$name').erase();
				return;
			}
			FunkinLua.luaTrace('eraseSaveData: Save file not initialized: ' + name, false, false, FlxColor.RED);
		});

		// File management
		Lua_helper.add_callback(lua, "checkFileExists", function(filename:String, ?absolute:Bool = false) {
			#if MODS_ALLOWED
			if(absolute) return FileSystem.exists(filename);

			return FileSystem.exists(Paths.getPath(filename, TEXT));

			#else
			if(absolute) return Assets.exists(filename, TEXT);

			return Assets.exists(Paths.getPath(filename, TEXT));
			#end
		});
		Lua_helper.add_callback(lua, "saveFile", function(path:String, content:String, ?absolute:Bool = false)
		{
			try {
				#if MODS_ALLOWED
				if(!absolute)
					File.saveContent(Paths.mods(path), content);
				else
				#end
					File.saveContent(path, content);

				return true;
			} catch (e:Dynamic) {
				FunkinLua.luaTrace("saveFile: Error trying to save " + path + ": " + e, false, false, FlxColor.RED);
			}
			return false;
		});
		Lua_helper.add_callback(lua, "deleteFile", function(path:String, ?ignoreModFolders:Bool = false, ?absolute:Bool = false)
		{
			try {
				var lePath:String = path;
				if(!absolute) lePath = Paths.getPath(path, TEXT, !ignoreModFolders);
				if(FileSystem.exists(lePath))
				{
					FileSystem.deleteFile(lePath);
					return true;
				}
			} catch (e:Dynamic) {
				FunkinLua.luaTrace("deleteFile: Error trying to delete " + path + ": " + e, false, false, FlxColor.RED);
			}
			return false;
		});
		Lua_helper.add_callback(lua, "getTextFromFile", function(path:String, ?ignoreModFolders:Bool = false) {
			return Paths.getTextFromFile(path, ignoreModFolders);
		});
		Lua_helper.add_callback(lua, "directoryFileList", function(folder:String) {
			var list:Array<String> = [];
			#if sys
			if(FileSystem.exists(folder)) {
				for (folder in FileSystem.readDirectory(folder)) {
					if (!list.contains(folder)) {
						list.push(folder);
					}
				}
			}
			#end
			return list;
		});

		// Capture the final camera display (including flashSprite) into a Lua sprite's graphic.
		Lua_helper.add_callback(lua, "captureCameraSnapshot", function(tag:String, ?camera:String = 'game') {
			var cam:FlxCamera = null;
			switch(camera) {
				case 'game': cam = PlayState.instance.camGame;
				case 'hud': cam = PlayState.instance.camHUD;
				case 'other': cam = PlayState.instance.camOther;
				default: cam = PlayState.instance.camGame;
			}

			var gameSizeX:Int = Std.int(FlxG.scaleMode.gameSize.x);
			var gameSizeY:Int = Std.int(FlxG.scaleMode.gameSize.y);
			var renderWidth:Int = gameSizeX;
			var renderHeight:Int = gameSizeY;
			var stageWidth:Int = 0;
			var stageHeight:Int = 0;
			if (FlxG.stage != null) {
				stageWidth = Std.int(FlxG.stage.stageWidth);
				stageHeight = Std.int(FlxG.stage.stageHeight);
			}
			var displayWidth:Int = if (stageWidth > 0) stageWidth else renderWidth;
			var displayHeight:Int = if (stageHeight > 0) stageHeight else renderHeight;
			var snapCanvas:BitmapData = new BitmapData(renderWidth, renderHeight, true, 0);
			var captured:Bool = false;

			// Prefer direct framebuffer capture from the Stage3D output and resample to game size.
			try {
				if (FlxG.stage != null && FlxG.stage.context3D != null && stageWidth > 0 && stageHeight > 0) {
					if (stageWidth == renderWidth && stageHeight == renderHeight) {
						FlxG.stage.context3D.drawToBitmapData(snapCanvas, null, null);
					} else {
						// Capture the whole stage, but only copy the camera viewport (centered) into the
						// game-size snapCanvas so letterbox/pillarbox areas are excluded.
						var stageCapture:BitmapData = new BitmapData(stageWidth, stageHeight, true, 0);
						FlxG.stage.context3D.drawToBitmapData(stageCapture, null, null);
						var scale:Float = Math.min(stageWidth / renderWidth, stageHeight / renderHeight);
						var scaledGameW:Float = renderWidth * scale;
						var scaledGameH:Float = renderHeight * scale;
						var offsetX:Float = (stageWidth - scaledGameW) / 2;
						var offsetY:Float = (stageHeight - scaledGameH) / 2;
						var stageMatrix = new Matrix();
						// translate so the camera area becomes origin, then scale down to render size
						stageMatrix.translate(-offsetX, -offsetY);
						stageMatrix.scale(1.0 / scale, 1.0 / scale);
						snapCanvas.draw(stageCapture, stageMatrix);
						stageCapture.dispose();
					}
					captured = true;
				}
			} catch (e:Dynamic) {}

			// If direct GPU capture isn't viable, fall back to the old working game draw path.
			if (!captured) {
				try {
					snapCanvas.draw(FlxG.game);
					captured = true;
				} catch (e:Dynamic) {}
			}

			if (!captured) {
				try {
					if (cam != null && cam.flashSprite != null) {
						var fs:DisplayObject = cast(cam.flashSprite, DisplayObject);
						var bounds = fs.getBounds(fs);
						var m = new Matrix();
						m.tx = -bounds.x;
						m.ty = -bounds.y;
						snapCanvas.draw(fs, m);
						captured = true;
					}
				} catch (e:Dynamic) {}
			}

			if (!captured) {
				snapCanvas.draw(FlxG.game);
			}

			var cacheKey = "lua_camera_snapshot_" + Std.string(FlxG.random.int(0, 999999));
			FlxG.bitmap.removeByKey(cacheKey);
			FunkinLua.luaTrace("captureCameraSnapshot: capture=" + Std.string(renderWidth) + "," + Std.string(renderHeight) + " snapCanvas=" + Std.string(snapCanvas.width) + "," + Std.string(snapCanvas.height), true);
			// Try to force texture creation / GPU upload like Paths.cacheBitmap does
			try {
				// Use only public BitmapData APIs to force texture creation / GPU upload
				snapCanvas.lock();
				// ensure a texture is created for the current context
				snapCanvas.getTexture(FlxG.stage.context3D);
				snapCanvas.getSurface();
				snapCanvas.disposeImage();
			} catch (e:Dynamic) {}

			var wrappedGfx = FlxGraphic.fromBitmapData(snapCanvas, true, cacheKey, true);
			if (wrappedGfx != null) {
				wrappedGfx.persist = true;
				wrappedGfx.destroyOnNoUse = false;
			}
			var spr = PlayState.instance.getLuaObject(tag);
			if (spr == null) {
				return false;
			}
			var prevVisible:Bool = true;
			try {
				prevVisible = spr.visible;
				spr.visible = false;
			} catch (e:Dynamic) {}
			spr.loadGraphic(wrappedGfx);
			// Force the sprite to fill the visible stage.
			try {
				// Make the snapshot sprite fill the logical game camera area
				// so it stretches to the camera's left/right/top/bottom edges.
				spr.setGraphicSize(Std.int(FlxG.width), Std.int(FlxG.height));
				// Anchor at the top-left of the logical camera and disable parallax.
				spr.x = 0;
				spr.y = 0;
				spr.scrollFactor.set(0, 0);
				spr.updateHitbox();
			} catch (e:Dynamic) {}
			try {
				spr.visible = prevVisible;
			} catch (e:Dynamic) {}
			return true;
		});

		// String tools
		Lua_helper.add_callback(lua, "stringStartsWith", function(str:String, start:String) {
			return str.startsWith(start);
		});
		Lua_helper.add_callback(lua, "stringEndsWith", function(str:String, end:String) {
			return str.endsWith(end);
		});
		Lua_helper.add_callback(lua, "stringSplit", function(str:String, split:String) {
			return str.split(split);
		});
		Lua_helper.add_callback(lua, "stringTrim", function(str:String) {
			return str.trim();
		});

		// Randomization
		Lua_helper.add_callback(lua, "getRandomInt", function(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = '') {
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Int> = [];
			for (i in 0...excludeArray.length)
			{
				if (exclude == '') break;
				toExclude.push(Std.parseInt(excludeArray[i].trim()));
			}
			return FlxG.random.int(min, max, toExclude);
		});
		Lua_helper.add_callback(lua, "getRandomFloat", function(min:Float, max:Float = 1, exclude:String = '') {
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Float> = [];
			for (i in 0...excludeArray.length)
			{
				if (exclude == '') break;
				toExclude.push(Std.parseFloat(excludeArray[i].trim()));
			}
			return FlxG.random.float(min, max, toExclude);
		});
		Lua_helper.add_callback(lua, "getRandomBool", function(chance:Float = 50) {
			return FlxG.random.bool(chance);
		});
	}
}
