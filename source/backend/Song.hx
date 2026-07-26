package backend;

import haxe.Json;
import lime.utils.Assets;

import objects.Note;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	var offset:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
	var format:String;

	var ?keys:Dynamic;
	@:optional var opponentKeys:Null<Int>;
	@:optional var playerKeys:Null<Int>;

	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;
	
	@:optional var disableNoteRGB:Bool;

	@:optional var arrowSkin:String;
	@:optional var splashSkin:String;
	@:optional var noOpponent:Bool;
}

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Float;
	var mustHitSection:Bool;
	@:optional var altAnim:Bool;
	@:optional var gfSection:Bool;
	@:optional var bpm:Float;
	@:optional var changeBPM:Bool;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var arrowSkin:String;
	public var splashSkin:String;
	public var gameOverChar:String;
	public var gameOverSound:String;
	public var gameOverLoop:String;
	public var gameOverEnd:String;
	public var disableNoteRGB:Bool = false;
	public var speed:Float = 1;
	public var stage:String;
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';
	public var format:String = 'psych_v1';

	public static function parseKeyCount(value:Dynamic, ?fallback:Int = 4):Int
	{
		if (value == null) return fallback;
		if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) return Std.int(value);

		var str:String = Std.string(value).trim();
		if (str.length < 1) return fallback;
		if (str.indexOf(';') != -1)
		{
			var parts:Array<String> = str.split(';');
			if (parts.length > 0)
			{
				var parsed:Null<Int> = Std.parseInt(parts[0].trim());
				if (parsed != null) return parsed;
			}
		}

		var parsed:Null<Int> = Std.parseInt(str);
		return parsed != null ? parsed : fallback;
	}

	public static function parseKeyCounts(value:Dynamic, ?fallback:Int = 4):Array<Int>
	{
		if (value == null) return [fallback, fallback];
		if (Std.isOfType(value, String))
		{
			var str:String = Std.string(value).trim();
			if (str.indexOf(';') != -1)
			{
				var parts:Array<String> = str.split(';');
				var opponentCount:Int = fallback;
				var playerCount:Int = fallback;
				if (parts.length > 0) opponentCount = parseKeyCount(parts[0], fallback);
				if (parts.length > 1) playerCount = parseKeyCount(parts[1], fallback);
				return [opponentCount, playerCount];
			}
		}

		var parsed:Int = parseKeyCount(value, fallback);
		return [parsed, parsed];
	}

	public static function getKeyCountForSide(song:SwagSong, side:Int):Int
	{
		if (song == null) return 4;
		var hasOpponentOverride:Bool = Reflect.hasField(song, 'opponentKeys') && Reflect.field(song, 'opponentKeys') != null;
		var hasPlayerOverride:Bool = Reflect.hasField(song, 'playerKeys') && Reflect.field(song, 'playerKeys') != null;
		var opponentCount:Int = hasOpponentOverride ? parseKeyCount(Reflect.field(song, 'opponentKeys'), 4) : 4;
		var playerCount:Int = hasPlayerOverride ? parseKeyCount(Reflect.field(song, 'playerKeys'), 4) : 4;
		if (!hasOpponentOverride || !hasPlayerOverride)
		{
			if (Reflect.hasField(song, 'keys') && Reflect.field(song, 'keys') != null)
			{
				var parsed:Array<Int> = parseKeyCounts(Reflect.field(song, 'keys'), 4);
				if (!hasOpponentOverride) opponentCount = parsed[0];
				if (!hasPlayerOverride) playerCount = parsed[1];
			}
		}
		return side == 0 ? opponentCount : playerCount;
	}

	public static function getKeyCountForOpponent(song:SwagSong):Int return getKeyCountForSide(song, 0);
	public static function getKeyCountForPlayer(song:SwagSong):Int return getKeyCountForSide(song, 1);
	public static function getTotalKeyCount(song:SwagSong):Int return getKeyCountForOpponent(song) + getKeyCountForPlayer(song);
	public static function is6KeyChart(song:SwagSong):Bool return getKeyCountForOpponent(song) == 6 || getKeyCountForPlayer(song) == 6;

	public static function isPlayerNoteData(song:SwagSong, noteData:Int):Bool
	{
		return noteData < getKeyCountForPlayer(song);
	}

	public static function getLocalLaneIndex(song:SwagSong, noteData:Int):Int
	{
		var playerCount:Int = getKeyCountForPlayer(song);
		var opponentCount:Int = getKeyCountForOpponent(song);
		if (noteData < playerCount) return Std.int(Math.abs(noteData) % Math.max(1, playerCount));
		return Std.int(Math.abs(noteData - playerCount) % Math.max(1, opponentCount));
	}

	public static function convert(songJson:Dynamic) // Convert old charts to psych_v1 format
	{
		if(songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			if(Reflect.hasField(songJson, 'player3')) Reflect.deleteField(songJson, 'player3');
		}

		if(songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while(i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if(note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}

		var sectionsData:Array<SwagSection> = songJson.notes;
		if(sectionsData == null) return;

		for (section in sectionsData)
		{
			var beats:Null<Float> = cast section.sectionBeats;
			if (beats == null || Math.isNaN(beats))
			{
				section.sectionBeats = 4;
				if(Reflect.hasField(section, 'lengthInSteps')) Reflect.deleteField(section, 'lengthInSteps');
			}

			for (note in section.sectionNotes)
			{
				var gottaHitNote:Bool = (note[1] < 4) ? section.mustHitSection : !section.mustHitSection;
				note[1] = (note[1] % 4) + (gottaHitNote ? 0 : 4);

				if(!Std.isOfType(note[3], String))
					note[3] = Note.defaultNoteTypes[note[3]]; //compatibility with Week 7 and 0.1-0.3 psych charts
			}
		}
	}

	public static var chartPath:String;
	public static var loadedSongName:String;
	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		if(folder == null) folder = jsonInput;
		PlayState.SONG = getChart(jsonInput, folder);
		loadedSongName = folder;
		chartPath = _lastPath;
		#if windows
		// prevent any saving errors by fixing the path on Windows (being the only OS to ever use backslashes instead of forward slashes for paths)
		chartPath = chartPath.replace('/', '\\');
		#end
		StageData.loadDirectory(PlayState.SONG);
		return PlayState.SONG;
	}

	static var _lastPath:String;
	public static function getChart(jsonInput:String, ?folder:String):SwagSong
	{
		if(folder == null) folder = jsonInput;
		var rawData:String = null;
		
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		_lastPath = Paths.json('$formattedFolder/$formattedSong');

		#if MODS_ALLOWED
		if(FileSystem.exists(_lastPath))
			rawData = File.getContent(_lastPath);
		else
		#end
			rawData = Assets.getText(_lastPath);

		return rawData != null ? parseJSON(rawData, jsonInput) : null;
	}

	public static function parseJSON(rawData:String, ?nameForError:String = null, ?convertTo:String = 'psych_v1'):SwagSong
	{
		var songJson:SwagSong = cast Json.parse(rawData);
		if(Reflect.hasField(songJson, 'song'))
		{
			var subSong:SwagSong = Reflect.field(songJson, 'song');
			if(subSong != null && Type.typeof(subSong) == TObject)
				songJson = subSong;
		}

		if(convertTo != null && convertTo.length > 0)
		{
			var fmt:String = songJson.format;
			if(fmt == null) fmt = songJson.format = 'unknown';

			switch(convertTo)
			{
				case 'psych_v1':
					if(!fmt.startsWith('psych_v1')) //Convert to Psych 1.0 format
					{
						trace('converting chart $nameForError with format $fmt to psych_v1 format...');
						songJson.format = 'psych_v1_convert';
						convert(songJson);
					}
			}
		}
		var opponentCount:Int = 4;
		var playerCount:Int = 4;
		if(Reflect.hasField(songJson, "opponentKeys") && Reflect.field(songJson, "opponentKeys") != null) opponentCount = parseKeyCount(Reflect.field(songJson, "opponentKeys"), 4);
		if(Reflect.hasField(songJson, "playerKeys") && Reflect.field(songJson, "playerKeys") != null) playerCount = parseKeyCount(Reflect.field(songJson, "playerKeys"), 4);
		if(Reflect.hasField(songJson, "keys") && Reflect.field(songJson, "keys") != null && Std.string(Reflect.field(songJson, "keys")).trim().length > 0)
		{
			var parsed:Array<Int> = parseKeyCounts(Reflect.field(songJson, "keys"), 4);
			if(!Reflect.hasField(songJson, "opponentKeys") || Reflect.field(songJson, "opponentKeys") == null) opponentCount = parsed[0];
			if(!Reflect.hasField(songJson, "playerKeys") || Reflect.field(songJson, "playerKeys") == null) playerCount = parsed[1];
		}
		if(!Reflect.hasField(songJson, "opponentKeys") || Reflect.field(songJson, "opponentKeys") == null) Reflect.setField(songJson, "opponentKeys", opponentCount);
		if(!Reflect.hasField(songJson, "playerKeys") || Reflect.field(songJson, "playerKeys") == null) Reflect.setField(songJson, "playerKeys", playerCount);
		if(!Reflect.hasField(songJson, "keys") || Reflect.field(songJson, "keys") == null || Std.string(Reflect.field(songJson, "keys")).trim().length < 1)
			Reflect.setField(songJson, "keys", '$opponentCount;$playerCount');
		if(!Reflect.hasField(songJson, "noOpponent")) songJson.noOpponent = false;
		return songJson;
	}
}
