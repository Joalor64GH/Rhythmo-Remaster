package;

import ForeverDependencies;
import Overlay;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxColor;
import haxe.CallStack.StackItem;
import haxe.CallStack;
import haxe.io.Path;
import lime.app.Application;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.UncaughtErrorEvent;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

using StringTools;

class Main extends Sprite
{
	// class action variables
	public static var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	public static var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).

	public static var mainClassState:Class<FlxState> = Init; // Determine the main class state of the game
	public static var framerate:Int = 120; // How many frames per second the game should run at.

	public static var gameVersion:String = '1.0.0';

	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var infoCounter:Overlay;

	public static var gameWeeks:Array<Dynamic> = [
		[
			['Tutorial'],
			['gf'],
			[FlxColor.fromRGB(129, 100, 223)],
			'Funky Beginnings'
		],
	];

	// most of these variables are just from the base game!
	// be sure to mess around with these if you'd like.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	// calls a function to set the game up
	public function new()
	{
		super();

		/**
			ok so, haxe html5 CANNOT do 120 fps. it just cannot.
			so here i just set the framerate to 60 if its complied in html5.
			reason why we dont just keep it because the game will act as if its 120 fps, and cause
			note studders and shit its weird.
		**/

		#if desktop
		openfl.Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, (e:UncaughtErrorEvent) -> 
		{
			var errMsg:String = "";
			var path:String;
			var callStack:Array<StackItem> = CallStack.exceptionStack(true);
			var dateNow:String = Date.now().toString();

			dateNow = dateNow.replace(" ", "_");
			dateNow = dateNow.replace(":", "'");

			path = "./crash/" + "game_" + dateNow + ".txt";

			for (stackItem in callStack)
			{
				switch (stackItem)
				{
					case FilePos(s, file, line, column):
						errMsg += file + " (line " + line + ")\n";
					default:
						Sys.println(stackItem);
				}
			}

			errMsg += "\nUncaught Error: " + e.error + "\nPlease report this error to the GitHub page: https://github.com/Joalor64GH/Rhythmo\n\n> Crash Handler written by: sqirra-rng";

			if (!FileSystem.exists("./crash/"))
				FileSystem.createDirectory("./crash/");

			File.saveContent(path, errMsg + "\n");

			Sys.println(errMsg);
			Sys.println("Crash dump saved in " + Path.normalize(path));

			lime.app.Application.current.window.alert(errMsg, "Error!");
			Sys.exit(1);
		});
		#end

		#if (html5 || neko)
		framerate = 60;
		#end

		FlxTransitionableState.skipNextTransIn = true;

		ScriptHandler.initialize();

		var gameCreate:FlxGame;
		gameCreate = new FlxGame(gameWidth, gameHeight, mainClassState, framerate, framerate, skipSplash);
		addChild(gameCreate);

		infoCounter = new Overlay(0, 0);
		addChild(infoCounter);
	}

	public static function framerateAdjust(input:Float)
	{
		return input * (60 / FlxG.drawFramerate);
	}

	public static var lastState:FlxState;

	public static function switchState(curState:FlxState, target:FlxState)
	{
		// Custom made Trans in
		mainClassState = Type.getClass(target);
		if (!FlxTransitionableState.skipNextTransIn)
		{
			curState.openSubState(new ForeverTransition(0.35, false));
			ForeverTransition.finishCallback = function()
			{
				FlxG.switchState(target);
			};
			return trace('changed state');
		}
		FlxTransitionableState.skipNextTransIn = false;
		FlxG.switchState(target);
	}

	public static function updateFramerate(newFramerate:Int)
	{
		// flixel will literally throw errors at me if I dont separate the orders
		if (newFramerate > FlxG.updateFramerate)
		{
			FlxG.updateFramerate = newFramerate;
			FlxG.drawFramerate = newFramerate;
		}
		else
		{
			FlxG.drawFramerate = newFramerate;
			FlxG.updateFramerate = newFramerate;
		}
	}
}