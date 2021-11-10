package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flash.display.BitmapData;
import sys.io.File;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxPoint;
import sys.FileSystem;
import haxe.Json;
import parsers.*;

using StringTools;

typedef AnimShit = {
	var prefix:String;
	var name:String;
	var fps:Int;
	var looped:Bool;
	var offsets:Array<Float>;
	@:optional var indices:Array<Int>;
}

typedef CharJson = {
	var anims:Array<AnimShit>;
	var spritesheet:String;
	var singDur:Float; // dadVar
	var iconName:String;
	var healthColor:String;
	var charOffset:Array<Float>;
	var beatDancer:Bool; // dances every beat like gf and spooky kids
	var flipX:Bool;

	@:optional var camOffset:Array<Float>;
	@:optional var scale:Float;
	@:optional var antialiasing:Bool;
}

class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;
	public var offsetNames:Array<String>=[];
	public var isPlayer:Bool = false;
	public var curCharacter:String = 'bf';
	public var holding:Bool=false;
	public var disabledDance:Bool = false;
	public var iconColor:FlxColor = 0xFF50a5eb;
	public var iconName:String = '';
	public var holdTimer:Float = 0;
	public var posOffset = FlxPoint.get(0,0);
	public var camOffset = FlxPoint.get(150,-100);
	public var charData:CharJson;
	public var dadVar:Float = 4;

	public var beatDancer:Bool = false;


	public var iconNames:Map<String,String> = [
		"bf-car"=>"bf",
		"bf-christmas"=>"bf",
		"mom-car"=>"mom",
		"gf-pixel"=>"gf",
		"gf-car"=>"gf",
		"gf-christmas"=>"gf",
		"monster-christmas"=>"monster",
		"senpai-angry"=>"senpai"
	];

	public var iconColors:Map<String,FlxColor> = [ // uses icon names
		"bf"=>0xFF31B0D1,
		"bf-pixel"=>0xFF31B0D1,
		"gf"=>0xFFA5004D,
		"dad"=>0xFFAF66CE,
		"spooky"=>0xFFC5995A,
		"monster"=>0xFFF4FF6F,
		"pico"=>0xFFB7D855,
		"mom"=>0xFFD8558E,
		"parents-christmas"=>0xFFC45EAE,
		"senpai"=>0xFFFFAA6F,
		"spirit"=>0xFFFF3C6E

	];

	override public function destroy(){
    camOffset = FlxDestroyUtil.put(camOffset);
		posOffset = FlxDestroyUtil.put(posOffset);
    super.destroy();
  }

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false, ?hasTexture:Bool=true)
	{
		super(x, y);
		iconName=iconNames.exists(character)?iconNames.get(character):character;
		iconColor=iconColors.exists(iconName)?iconColors.get(iconName):0xFF50a5eb;
		animOffsets = new Map<String, Array<Dynamic>>();
		curCharacter = character;
		this.isPlayer = isPlayer;

		var tex:FlxAtlasFrames;
		antialiasing = true;

		if(hasTexture){

			switch (curCharacter)
			{
				// case 'whatever':
				// whatever hard-coded shit here

			default:
				var pathBase = 'assets/characters/data/';
				var charPath = pathBase + curCharacter + ".json";
				var playerPath = pathBase + curCharacter + "-player.json";
				if(isPlayer && FileSystem.exists(playerPath))charPath=playerPath;
				var shit:Null<Dynamic>=null;
				var fuckHaxeflixel:PsychParsers.PsychChar = null;

				if(FileSystem.exists(charPath)){
					shit = Json.parse(File.getContent(charPath));
				}else if(FileSystem.exists(pathBase + "dad.json")){
					shit = Json.parse(File.getContent(pathBase + "dad.json") );
				}

				if(Reflect.field(shit,"no_antialiasing")!=null){
					shit = PsychParsers.fromChar(fuckHaxeflixel);
				}
				charData=shit;

				if(charData!=null){
					var chars = "assets/characters/images/";

					var spritesheet = charData.spritesheet;
					var path = chars + spritesheet;

					if(FileSystem.exists(path + ".png")){
						var image = FlxG.bitmap.get(path);
						if(image==null){
							image = FlxG.bitmap.add(BitmapData.fromFile(path + ".png"),false,path);
						}
						if(FileSystem.exists(path + ".txt")){
							frames = FlxAtlasFrames.fromSpriteSheetPacker(image, File.getContent(path + ".txt") );
						}else if(FileSystem.exists(path + ".xml")){
							frames = FlxAtlasFrames.fromSparrow(image, File.getContent(path + ".xml") );
						}
					}


					var offsetPath = "assets/characters/images/"+curCharacter+"Offsets.txt";
					var defaultOffsets:Map<String,Array<Float>>=[];
					if(FileSystem.exists(offsetPath)){
						var offsets = CoolUtil.coolTextFile2(File.getContent(offsetPath));
						for(s in offsets){
							var stuff:Array<String> = s.split(" ");
							defaultOffsets.set(stuff[0],[Std.parseFloat(stuff[1]),Std.parseFloat(stuff[2])]);
						}
					}

					for(anim in charData.anims){
						var prefix = anim.prefix;
						var name = anim.name;
						var fps = anim.fps;
						var loop = anim.looped;
						var offset = anim.offsets;
						if(offset.length<2){
							if(defaultOffsets.get(name)!=null){
								offset=defaultOffsets.get(name);
							}else{
								offset=[0,0];
							}
						}
						if(anim.indices==null){
							animation.addByPrefix(name,prefix,fps,loop);
						}else{
							animation.addByIndices(name,prefix,anim.indices,"",fps,loop);
						}
						addOffset(name,offset[0],offset[1]);
					}

					posOffset.set(charData.charOffset[0],charData.charOffset[1]);

					if(charData.camOffset!=null){
						camOffset.set(charData.camOffset[0],charData.camOffset[1]);
					}

					if(charData.antialiasing!=null)
						antialiasing=charData.antialiasing;
					else
						antialiasing=true;


					dadVar = charData.singDur;
					flipX = charData.flipX;

					iconColor = FlxColor.fromString(charData.healthColor);
					iconName = charData.iconName;

					beatDancer = charData.beatDancer;

					if(charData.scale!=null && charData.scale!=1){
						setGraphicSize(Std.int(width*charData.scale));
						updateHitbox();
					}

					if(charPath!=playerPath && isPlayer){
						trace("bruh");
						flipX = !flipX;

						leftToRight();
					}
				}else{
					iconColor = 0xFFAF66CE;
					frames = Paths.characterSparrow('characters/DADDY_DEAREST');
					animation.addByPrefix('idle', 'Dad idle dance', 24);
					animation.addByPrefix('singUP', 'Dad Sing note UP', 24);
					animation.addByPrefix('singLEFT', 'dad sing note right', 24);
					animation.addByPrefix('singDOWN', 'Dad Sing Note DOWN', 24);
					animation.addByPrefix('singRIGHT', 'Dad Sing Note LEFT', 24);

					addOffset("idle",0,0);
					addOffset("singUP",-6,50);
					addOffset("singRIGHT",0,27);
					addOffset("singLEFT",-10,10);
					addOffset("singDOWN",0,-30);

					if(isPlayer){
						flipX = !flipX;

						leftToRight();
					}
				}

				if(animation.getByName("idle")!=null)
					playAnim("idle");
				else
					playAnim("danceRight");
			}


			dance();

		}
	}

	public function leftToRight(){
		if(animation.getByName('singRIGHT')!=null && animation.getByName('singLEFT')!=null){
			var oldRight = animation.getByName('singRIGHT').frames;
			animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
			animation.getByName('singLEFT').frames = oldRight;

			if (animation.getByName('singRIGHTmiss') != null)
			{
				var oldMiss = animation.getByName('singRIGHTmiss').frames;
				animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
				animation.getByName('singLEFTmiss').frames = oldMiss;
			}
		}
	}

	public function rightToLeft(){
		if(animation.getByName('singRIGHT')!=null && animation.getByName('singLEFT')!=null){
			var old = animation.getByName('singRIGHT').frames;
			animation.getByName('singLEFT').frames = animation.getByName('singRIGHT').frames;
			animation.getByName('singRIGHT').frames = old;

			if (animation.getByName('singRIGHTmiss') != null)
			{
				var oldMiss = animation.getByName('singLEFTmiss').frames;
				animation.getByName('singLEFTmiss').frames = animation.getByName('singRIGHTmiss').frames;
				animation.getByName('singRIGHTmiss').frames = oldMiss;
			}
		}
	}


	public function loadOffsets(){
		//var offsets = CoolUtil.coolTextFile(Paths.txtImages('characters/'+curCharacter+"Offsets"));
		var offsets:Array<String>;
		if(Cache.offsetData[curCharacter]!=null){
			offsets = CoolUtil.coolTextFile2(Cache.offsetData[curCharacter]);
		}else{
			var data = File.getContent("assets/shared/images/characters/"+curCharacter+"Offsets.txt");
			offsets = CoolUtil.coolTextFile2(data);
			Cache.offsetData[curCharacter] = data;
		}
		for(s in offsets){
			var stuff:Array<String> = s.split(" ");
			addOffset(stuff[0],Std.parseFloat(stuff[1]),Std.parseFloat(stuff[2]));
		}
	}

	public function loadAnimations(){
		trace("loading anims for " + curCharacter);
		try {
			//var anims = CoolUtil.coolTextFile(Paths.txtImages('characters/'+curCharacter+"Anims"));
			var anims:Array<String>;
			if(Cache.offsetData[curCharacter]!=null){
				anims = CoolUtil.coolTextFile2(Cache.animData[curCharacter]);
			}else{
				var data = File.getContent("assets/shared/images/characters/"+curCharacter+"Anims.txt");
				anims = CoolUtil.coolTextFile2(data);
				Cache.animData[curCharacter] = data;
			}
			for(s in anims){
				var stuff:Array<String> = s.split(" ");
				var type = stuff.splice(0,1)[0];
				var name = stuff.splice(0,1)[0];
				var fps = Std.parseInt(stuff.splice(0,1)[0]);
				trace(type,name,stuff.join(" "),fps);
				if(type.toLowerCase()=='prefix'){
					animation.addByPrefix(name, stuff.join(" "), fps, false);
				}else if(type.toLowerCase()=='indices'){
					var shit = stuff.join(" ");
					var indiceShit = shit.split("/")[1];
					var prefixShit = shit.split("/")[0];
					var newArray:Array<Int> = [];
					for(i in indiceShit.split(" ")){
						newArray.push(Std.parseInt(i));
					};
					animation.addByIndices(name, prefixShit, newArray, "", fps, false);
				}
			}
		} catch(e:Dynamic) {
			trace("FUCK" + e);
		}
	}

	override function update(elapsed:Float)
	{
		if (!isPlayer)
		{
			if(animation.curAnim!=null){
				if(animation.getByName('${animation.curAnim.name}Hold')!=null){
					animation.paused=false;
					if(animation.curAnim.name.startsWith("sing") && !animation.curAnim.name.endsWith("Hold") && animation.curAnim.finished){
						playAnim(animation.curAnim.name + "Hold",true);
					}
				}

				if (animation.curAnim.name.startsWith('sing'))
				{
					holdTimer += elapsed;
				}

				if (holdTimer >= Conductor.stepCrochet * dadVar * 0.001)
				{
					dance();

					holdTimer = 0;
				}
			}

			switch (curCharacter)
			{
				case 'gf':
					if (animation.curAnim.name == 'hairFall' && animation.curAnim.finished)
						playAnim('danceRight');
			}


		}
		super.update(elapsed);
		if(animation.curAnim!=null)
			if(holding)
				animation.curAnim.curFrame=0;
	}

	private var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (!debugMode && !disabledDance && animation.curAnim!=null)
		{
			holding=false;
			if(!beatDancer)
				playAnim("idle");
			else{
				if (!animation.curAnim.name.startsWith('hair'))
				{
					danced = !danced;

					if (danced)
						playAnim('danceRight');
					else
						playAnim('danceLeft');
				}
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		if(AnimName.endsWith("miss") && animation.getByName(AnimName)==null ){
			AnimName = AnimName.substring(0,AnimName.length-4);
		}
		if(animation.getByName(AnimName)!=null){
			//animation.getByName(AnimName).frameRate=animation.getByName(AnimName).frameRate;

			animation.play(AnimName, Force, Reversed, Frame);

			var daOffset = animOffsets.get(AnimName);
			if (animOffsets.exists(AnimName))
			{
				offset.set(daOffset[0], daOffset[1]);
			}
			else
				offset.set(0, 0);

			if (curCharacter == 'gf')
			{
				if (AnimName == 'singLEFT')
				{
					danced = true;
				}
				else if (AnimName == 'singRIGHT')
				{
					danced = false;
				}

				if (AnimName == 'singUP' || AnimName == 'singDOWN')
				{
					danced = !danced;
				}
			}
		}
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		offsetNames.push(name);
		animOffsets[name] = [x, y];
	}
}
