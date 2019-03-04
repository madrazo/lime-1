package;

import hxp.Haxelib;
import hxp.HXML;
import hxp.Log;
import hxp.Path;
import hxp.NDLL;
import hxp.System;
import lime.tools.Architecture;
import lime.tools.Asset;
import lime.tools.AssetHelper;
import lime.tools.AssetType;
import lime.tools.CPPHelper;
import lime.tools.CSHelper;
import lime.tools.DeploymentHelper;
import lime.tools.GUID;
import lime.tools.HTML5Helper;
import lime.tools.HXProject;
import lime.tools.Icon;
import lime.tools.IconHelper;
import lime.tools.JavaHelper;
import lime.tools.ModuleHelper;
import lime.tools.NekoHelper;
import lime.tools.NodeJSHelper;
import lime.tools.Platform;
import lime.tools.PlatformTarget;
import lime.tools.ProjectHelper;
import sys.io.File;
import sys.FileSystem;

class WindowsPlatform extends PlatformTarget
{
	private var applicationDirectory:String;
	private var executablePath:String;
	private var is64:Bool;
	private var targetType:String;
	private var outputFile:String;

	public function new(command:String, _project:HXProject, targetFlags:Map<String, String>)
	{
		super(command, _project, targetFlags);

		if (project.targetFlags.exists("uwp") || project.targetFlags.exists("winjs"))
		{
			targetType = "winjs";
		}
		else if (project.targetFlags.exists("neko") || project.target != cast System.hostPlatform)
		{
			targetType = "neko";
		}
		else if (project.targetFlags.exists("hl"))
		{
			targetType = "hl";
		}
		else if (project.targetFlags.exists("nodejs"))
		{
			targetType = "nodejs";
		}
		else if (project.targetFlags.exists("cs"))
		{
			targetType = "cs";
		}
		else if (project.targetFlags.exists("java"))
		{
			targetType = "java";
		}
		else if (project.targetFlags.exists("winrt"))
		{
			targetType = "winrt";
		}
		else
		{
			targetType = "cpp";
		}

		for (architecture in project.architectures)
		{
			if ((targetType == "cpp" || targetType == "winrt") && architecture == Architecture.X64)
			{
				is64 = true;
			}
		}

		targetDirectory = Path.combine(project.app.path, project.config.getString("windows.output-directory", targetType == "cpp" ? "windows" : targetType));
		targetDirectory = StringTools.replace(targetDirectory, "arch64", is64 ? "64" : "");

		if (targetType == "winjs")
		{
			outputFile = targetDirectory + "/source/js/" + project.app.file + ".js";
		}
		else
		{
			applicationDirectory = targetDirectory + "/bin/";
			executablePath = applicationDirectory + project.app.file + ".exe";
		}
	}

	public override function build():Void
	{
		var hxml = targetDirectory + "/haxe/" + buildType + ".hxml";

		System.mkdir(targetDirectory);

		var icons = project.icons;

		if (icons.length == 0)
		{
			icons = [new Icon(System.findTemplate(project.templatePaths, "default/icon.svg"))];
		}

		if (targetType == "winjs")
		{
			ModuleHelper.buildModules(project, targetDirectory, targetDirectory);

			if (project.app.main != null)
			{
				System.runCommand("", "haxe", [hxml]);

				var msBuildPath = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\MSBuild\\15.0\\Bin\\MSBuild.exe";
				var args = [
					Path.tryFullPath(targetDirectory + "/source/" + project.app.file + ".jsproj"),
					"/p:Configuration=Release"
				];

				System.runCommand("", msBuildPath, args);
				if (noOutput) return;

				if (project.targetFlags.exists("webgl"))
				{
					System.copyFile(targetDirectory + "/source/ApplicationMain.js", outputFile);
				}

				if (project.modules.iterator().hasNext())
				{
					ModuleHelper.patchFile(outputFile);
				}

				if (project.targetFlags.exists("minify") || buildType == "final")
				{
					HTML5Helper.minify(project, targetDirectory + outputFile);
				}
			}
		}
		else
		{
			for (dependency in project.dependencies)
			{
				if (StringTools.endsWith(dependency.path, ".dll"))
				{
					var fileName = Path.withoutDirectory(dependency.path);
					System.copyIfNewer(dependency.path, applicationDirectory + "/" + fileName);
				}
			}

			if (targetType == "winrt")
			{
				if(!project.targetFlags.exists ("static"))
				{
					for (ndll in project.ndlls)
					{
						ProjectHelper.copyLibrary(project, ndll, "WinRT" + (is64 ? "64" : ""), "",
						(ndll.haxelib != null && (ndll.haxelib.name == "hxcpp" || ndll.haxelib.name == "hxlibc")) ? ".dll" : ".ndll", applicationDirectory,
						project.debug, null);
					}
				}
			}
			else if (!project.targetFlags.exists("static") || targetType != "cpp")
			{
				var targetSuffix = (targetType == "hl") ? ".hdll" : null;

				for (ndll in project.ndlls)
				{
					ProjectHelper.copyLibrary(project, ndll, "Windows" + (is64 ? "64" : ""), "",
						(ndll.haxelib != null && (ndll.haxelib.name == "hxcpp" || ndll.haxelib.name == "hxlibc")) ? ".dll" : ".ndll", applicationDirectory,
						project.debug, targetSuffix);
				}
			}

			// IconHelper.createIcon (project.icons, 32, 32, Path.combine (applicationDirectory, "icon.png"));

			if (targetType == "neko")
			{
				System.runCommand("", "haxe", [hxml]);

				if (noOutput) return;

				var iconPath = Path.combine(applicationDirectory, "icon.ico");

				if (!IconHelper.createWindowsIcon(icons, iconPath))
				{
					iconPath = null;
				}

				NekoHelper.createWindowsExecutable(project.templatePaths, targetDirectory + "/obj/ApplicationMain.n", executablePath, iconPath);
				NekoHelper.copyLibraries(project.templatePaths, "windows" + (is64 ? "64" : ""), applicationDirectory);
			}
			else if (targetType == "hl")
			{
				System.runCommand("", "haxe", [hxml]);

				if (noOutput) return;

				System.copyFile(targetDirectory + "/obj/ApplicationMain.hl", Path.combine(applicationDirectory, project.app.file + ".hl"));
			}
			else if (targetType == "nodejs")
			{
				System.runCommand("", "haxe", [hxml]);

				if (noOutput) return;

				// NekoHelper.createExecutable (project.templatePaths, "windows" + (is64 ? "64" : ""), targetDirectory + "/obj/ApplicationMain.n", executablePath);
				// NekoHelper.copyLibraries (project.templatePaths, "windows" + (is64 ? "64" : ""), applicationDirectory);
			}
			else if (targetType == "cs")
			{
				System.runCommand("", "haxe", [hxml]);

				if (noOutput) return;

				CSHelper.copySourceFiles(project.templatePaths, targetDirectory + "/obj/src");
				var txtPath = targetDirectory + "/obj/hxcs_build.txt";
				CSHelper.addSourceFiles(txtPath, CSHelper.ndllSourceFiles);
				CSHelper.addGUID(txtPath, GUID.uuid());
				CSHelper.compile(project, targetDirectory + "/obj", applicationDirectory + project.app.file, "x86", "desktop");
			}
			else if (targetType == "java")
			{
				var libPath = Path.combine(Haxelib.getPath(new Haxelib("lime")), "templates/java/lib/");

				System.runCommand("", "haxe", [hxml, "-java-lib", libPath + "disruptor.jar", "-java-lib", libPath + "lwjgl.jar"]);
				// System.runCommand ("", "haxe", [ hxml ]);

				if (noOutput) return;

				var haxeVersion = project.environment.get("haxe_ver");
				var haxeVersionString = "3404";

				if (haxeVersion.length > 4)
				{
					haxeVersionString = haxeVersion.charAt(0) + haxeVersion.charAt(2) + (haxeVersion.length == 5 ? "0" + haxeVersion.charAt(4) : haxeVersion
						.charAt(4) + haxeVersion.charAt(5));
				}

				System.runCommand(targetDirectory + "/obj", "haxelib", ["run", "hxjava", "hxjava_build.txt", "--haxe-version", haxeVersionString]);
				System.recursiveCopy(targetDirectory + "/obj/lib", Path.combine(applicationDirectory, "lib"));
				System.copyFile(targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-Debug" : "") + ".jar",
					Path.combine(applicationDirectory, project.app.file + ".jar"));
				JavaHelper.copyLibraries(project.templatePaths, "Windows" + (is64 ? "64" : ""), applicationDirectory);
			}
			else if (targetType == "winrt")
			{
				var haxeArgs = [hxml];
				var flags = [];

				haxeArgs.push("-D");
				haxeArgs.push("winrt");
				flags.push("-Dwinrt");

				// TODO: ARM support

				if (is64)
				{
					haxeArgs.push("-D");
					haxeArgs.push("HXCPP_M64");
					flags.push("-DHXCPP_M64");
				}
				else
				{
					flags.push("-DHXCPP_M32");
				}

				if (!project.environment.exists("SHOW_CONSOLE"))
				{
					haxeArgs.push("-D");
					haxeArgs.push("no_console");
					flags.push("-Dno_console");
				}

				if (!project.targetFlags.exists("static"))
				{
					System.runCommand("", "haxe", haxeArgs);

					if (noOutput) return;

					CPPHelper.compile(project, targetDirectory + "/obj", flags);

					System.copyFile(targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-debug" : "") + ".exe", executablePath);
				}
				else
				{
					System.runCommand("", "haxe", haxeArgs.concat(["-D", "static_link"]));

					if (noOutput) return;

					CPPHelper.compile(project, targetDirectory + "/obj", flags.concat(["-Dstatic_link"]));
					CPPHelper.compile(project, targetDirectory + "/obj", flags, "BuildMain.xml");

					System.copyFile(targetDirectory + "/obj/Main" + (project.debug ? "-debug" : "") + ".exe", executablePath);
				}

				//TODO createWinrtIcons
				//var iconPath = Path.combine(applicationDirectory, "icon.ico");

				//if (IconHelper.createWindowsIcon(icons, iconPath) && System.hostPlatform == WINDOWS)
				//{
				//	var templates = [Haxelib.getPath(new Haxelib(#if lime "lime" #else "hxp" #end)) + "/templates"].concat(project.templatePaths);
				//	System.runCommand("", System.findTemplate(templates, "bin/ReplaceVistaIcon.exe"), [executablePath, iconPath, "1"], true, true);
				//}
			}
			else
			{
				var haxeArgs = [hxml];
				var flags = [];

				if (is64)
				{
					haxeArgs.push("-D");
					haxeArgs.push("HXCPP_M64");
					flags.push("-DHXCPP_M64");
				}
				else
				{
					flags.push("-DHXCPP_M32");
				}

				if (!project.environment.exists("SHOW_CONSOLE"))
				{
					haxeArgs.push("-D");
					haxeArgs.push("no_console");
					flags.push("-Dno_console");
				}

				if (!project.targetFlags.exists("static"))
				{
					System.runCommand("", "haxe", haxeArgs);

					if (noOutput) return;

					CPPHelper.compile(project, targetDirectory + "/obj", flags);

					System.copyFile(targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-debug" : "") + ".exe", executablePath);
				}
				else
				{
					System.runCommand("", "haxe", haxeArgs.concat(["-D", "static_link"]));

					if (noOutput) return;

					CPPHelper.compile(project, targetDirectory + "/obj", flags.concat(["-Dstatic_link"]));
					CPPHelper.compile(project, targetDirectory + "/obj", flags, "BuildMain.xml");

					System.copyFile(targetDirectory + "/obj/Main" + (project.debug ? "-debug" : "") + ".exe", executablePath);
				}

				var iconPath = Path.combine(applicationDirectory, "icon.ico");

				if (IconHelper.createWindowsIcon(icons, iconPath) && System.hostPlatform == WINDOWS)
				{
					var templates = [Haxelib.getPath(new Haxelib(#if lime "lime" #else "hxp" #end)) + "/templates"].concat(project.templatePaths);
					System.runCommand("", System.findTemplate(templates, "bin/ReplaceVistaIcon.exe"), [executablePath, iconPath, "1"], true, true);
				}
			}
		}
	}

	public override function clean():Void
	{
		if (FileSystem.exists(targetDirectory))
		{
			System.removeDirectory(targetDirectory);
		}
	}

	public override function deploy():Void
	{
		DeploymentHelper.deploy(project, targetFlags, targetDirectory, "Windows" + (is64 ? "64" : ""));
	}

	public override function display():Void
	{
		Sys.println(getDisplayHXML());
	}

	private function generateContext():Dynamic
	{
		var context = project.templateContext;

		if (targetType == "winjs")
		{
			context.WIN_FLASHBACKGROUND = project.window.background != null ? StringTools.hex(project.window.background, 6) : "";
			context.OUTPUT_FILE = outputFile;

			if (project.targetFlags.exists("webgl"))
			{
				context.CPP_DIR = targetDirectory;
			}

			var guid = GUID.seededUuid(project.meta.packageName);
			context.APP_GUID = guid;

			var guidNoBrackets = guid.split("{").join("").split("}").join("");
			context.APP_GUID_NOBRACKETS = guidNoBrackets;

			if (context.APP_DESCRIPTION == null || context.APP_DESCRIPTION == "")
			{
				context.APP_DESCRIPTION = project.meta.title;
			}
		}
		else if (targetType == "winrt")
		{			
			context.CPP_DIR = targetDirectory + "/obj";
			context.BUILD_DIR = project.app.path + "/winrt" + (is64 ? "64" : "");
			context.DC = "::";
		} 
		else
		{
			context.NEKO_FILE = targetDirectory + "/obj/ApplicationMain.n";
			context.NODE_FILE = targetDirectory + "/bin/ApplicationMain.js";
			context.HL_FILE = targetDirectory + "/obj/ApplicationMain.hl";
			context.CPP_DIR = targetDirectory + "/obj";
			context.BUILD_DIR = project.app.path + "/windows" + (is64 ? "64" : "");
		}

		return context;
	}

	private function getDisplayHXML():String
	{
		var path = targetDirectory + "/haxe/" + buildType + ".hxml";

		if (FileSystem.exists(path))
		{
			return File.getContent(path);
		}
		else
		{
			var context = project.templateContext;
			var hxml = HXML.fromString(context.HAXE_FLAGS);
			hxml.addClassName(context.APP_MAIN);
			switch (targetType)
			{
				case "hl": hxml.hl = "_.hl";
				case "neko": hxml.neko = "_.n";
				case "java": hxml.java = "_";
				case "nodejs", "winjs": hxml.js = "_.js";
				default: hxml.cpp = "_";
			}
			hxml.noOutput = true;
			return hxml;
		}
	}

	public override function rebuild():Void
	{
		if (targetType != "winjs")
		{
			// if (project.environment.exists ("VS110COMNTOOLS") && project.environment.exists ("VS100COMNTOOLS")) {

			// project.environment.set ("HXCPP_MSVC", project.environment.get ("VS100COMNTOOLS"));
			// Sys.putEnv ("HXCPP_MSVC", project.environment.get ("VS100COMNTOOLS"));

			// }

			var commands = [];

			if (!targetFlags.exists("64") && (command == "rebuild"
				|| System.hostArchitecture == X86
				|| (targetType != "cpp" && targetType != "winrt")))
			{
				if (targetFlags.exists("winrt"))
				{
					commands.push(["-Dwinrt", "-DHXCPP_M32"]);
				}
				else
				{
					commands.push(["-Dwindows", "-DHXCPP_M32"]);
				}
			}

			// TODO: Compiling with -Dfulldebug overwrites the same "-debug.pdb"
			// as previous Windows builds. For now, force -64 to be done last
			// so that it can be debugged in a default "rebuild"

			if (!targetFlags.exists("32")
				&& System.hostArchitecture == X64
				&& (command != "rebuild" || targetType == "cpp" || targetType == "winrt"))
			{
				if (targetFlags.exists("winrt"))
				{
					commands.push(["-Dwinrt", "-DHXCPP_M64"]);
				}
				else
				{
					commands.push(["-Dwindows", "-DHXCPP_M64"]);
				}
			}

			CPPHelper.rebuild(project, commands);
		}
	}

	public override function run():Void
	{
		var arguments = additionalArguments.copy();

		if (Log.verbose)
		{
			arguments.push("-verbose");
		}

		if (targetType == "hl")
		{
			System.runCommand(applicationDirectory, "hl", [project.app.file + ".hl"].concat(arguments));
		}
		else if (targetType == "nodejs")
		{
			NodeJSHelper.run(project, targetDirectory + "/bin/ApplicationMain.js", arguments);
		}
		else if (targetType == "winjs")
		{
			/*

				The 'test' target is problematic for UWP applications.  UWP applications are bundled in appx packages and
				require app certs to properly install.

				There are two options to trigger an appx install from the command line.

				A. Use the WinAppDeployCmd.exe utility to deploy to local and remote devices

				B. Execute the Add-AppDevPackage.ps1 powershell script that is an
					artifact of the UWP msbuild

				A: WinAppDeployCmd.exe
				https://docs.microsoft.com/en-us/windows/uwp/packaging/install-universal-windows-apps-with-the-winappdeploycmd-tool
				https://msdn.microsoft.com/en-us/windows/desktop/mt627714
				Windows 10 SDK: https://developer.microsoft.com/windows/downloads/windows-10-sdk

				I've never actually got this to work, but I feel like I was close.  The WinAppDeployCmd.exe is a part of the
				Windows 10 SDK and not a part of the Visual Studio 2017 community edition.  It will appear magically if you
				check enough boxes when installing various project templates for Visual Studio.  It appeared for me, and I
				have no clue how it got there.

				A developer must take a few steps in order for this command to work.
				1. Install Visual Studio 2017 Community Edition
				2. Install the Windows 10 SDK
				3. Modify Windows 10 Settings to enable side loading and device discovery
				3. Enabling device discovery generates a pin number that is displayed to the user
				4. Open the "Developer Command Promp for VS 2017" from the Start menu
				5. run:
					> WinAppDeployCmd devices
				6. Make sure your device shows up in the list (if it does not appear try step 3 again, toggling things on/off)
				7. run: (replase file, ip and pin with your values)
					> WinAppDeployCmd install -file "uwp-project_1.0.0.0_AnyCPU.appx" -ip 192.168.27.167 -pin 326185

				B: Add-AppDevPackage.ps1 + PowerShell_Set_Unrestricted.reg
				The UWP build generates a powershell script by default. This script is usually executed by the user
				by right clicking the file and choosing "run with powershell". Executing this script directly from the cmd
				prompt results in a security error: "Add-AppDevPackage.ps1 cannot be loaded because running scripts is
				disabled on this system."

				We must edit the registry if we want to run this script directly from a shell.
				See lime/templates/windows/template/PowerShell_Set_Unrestricted.reg

				1. run:
					> regedit /s PowerShell_Set_Unrestricted.reg
				2. run:
					 			> powershell "& ""./Add-AppDevPackage.ps1"""

					 		note: the nonsensical double quotes are required.

			 */

			// Using option B because obtaining the device pin programatically does not seem possible.
			// System.runCommand ("", "regedit", [ '/s', '"' + targetDirectory + '/bin/PowerShell_Set_Unrestricted.reg"' ]);
			// var test = '"& ""' + targetDirectory + '/bin/PowerShell_Set_Unrestricted.reg"""';
			// Sys.command ('powershell & ""' + targetDirectory + '/bin/source/AppPackages/' + project.app.file + '_1.0.0.0_AnyCPU_Test/Add-AppDevPackage.ps1""');
			var version = project.meta.version + "." + project.meta.buildNumber;
			System.openFile(targetDirectory + "/source/AppPackages/" + project.app.file + "_" + version + "_AnyCPU_Test",
				project.app.file + "_" + version + "_AnyCPU.appx");

			// source/AppPackages/uwp-project_1.0.0.0_AnyCPU_Test/Add-AppDevPackage.ps1

			// HTML5Helper.launch (project, targetDirectory + "/bin");
		}
		else if (targetType == "java")
		{
			System.runCommand(applicationDirectory, "java", ["-jar", project.app.file + ".jar"].concat(arguments));
		}
		else if (targetType == "winrt")
		{
			winrtRun(arguments);
		}
		else if (project.target == cast System.hostPlatform)
		{
			arguments = arguments.concat(["-livereload"]);
			System.runCommand(applicationDirectory, Path.withoutDirectory(executablePath), arguments);
		}
	}

	public override function update():Void
	{
		AssetHelper.processLibraries(project, targetDirectory);

		if (targetType == "winjs")
		{
			updateUWP();
			return;
		}

		// project = project.clone ();

		if (project.targetFlags.exists("xml"))
		{
			project.haxeflags.push("-xml " + targetDirectory + "/types.xml");
		}

		for (asset in project.assets)
		{
			if (asset.embed && asset.sourcePath == "")
			{
				var path = Path.combine(targetDirectory + "/obj/tmp", asset.targetPath);
				System.mkdir(Path.directory(path));
				AssetHelper.copyAsset(asset, path);
				asset.sourcePath = path;
			}
		}

		var context = generateContext();
		context.OUTPUT_DIR = targetDirectory;

		if ((targetType == "cpp" || targetType == "winrt") && project.targetFlags.exists("static"))
		{
			var programFiles = project.environment.get("ProgramFiles(x86)");
			var hasVSCommunity = (programFiles != null && FileSystem.exists(Path.combine(programFiles, "Microsoft Visual Studio/Installer/vswhere.exe")));
			var hxcppMSVC = project.environment.get("HXCPP_MSVC");
			var vs140 = project.environment.get("VS140COMNTOOLS");

			var msvc19 = true;

			if ((!hasVSCommunity && vs140 == null) || (hxcppMSVC != null && hxcppMSVC != vs140))
			{
				msvc19 = false;
			}

			var suffix = (msvc19 ? "-19.lib" : ".lib");

			for (i in 0...project.ndlls.length)
			{
				var ndll = project.ndlls[i];

				if (ndll.path == null || ndll.path == "")
				{
					context.ndlls[i].path = NDLL.getLibraryPath(ndll, "Windows" + (is64 ? "64" : ""), "lib", suffix, project.debug);
				}
			}
		}

		System.mkdir(targetDirectory);
		System.mkdir(targetDirectory + "/obj");
		System.mkdir(targetDirectory + "/haxe");
		System.mkdir(applicationDirectory);

		// SWFHelper.generateSWFClasses (project, targetDirectory + "/haxe");

		ProjectHelper.recursiveSmartCopyTemplate(project, "haxe", targetDirectory + "/haxe", context);
		ProjectHelper.recursiveSmartCopyTemplate(project, targetType + "/hxml", targetDirectory + "/haxe", context);

		if (targetType == "winrt" && project.targetFlags.exists ("static"))
		{
			ProjectHelper.recursiveSmartCopyTemplate (project, "winrt/assetspkg", targetDirectory + "/bin/assetspkg", context, false, true);
			ProjectHelper.recursiveSmartCopyTemplate (project, "winrt/appx", targetDirectory + "/bin", context, true, true);
			ProjectHelper.recursiveSmartCopyTemplate (project, "winrt/static", targetDirectory + "/obj", context, true, true);		
		}
		else if (targetType == "cpp" && project.targetFlags.exists("static"))
		{
			ProjectHelper.recursiveSmartCopyTemplate(project, "cpp/static", targetDirectory + "/obj", context);
		}

		/*if (IconHelper.createIcon (project.icons, 32, 32, Path.combine (applicationDirectory, "icon.png"))) {

			context.HAS_ICON = true;
			context.WIN_ICON = "icon.png";

		}*/

		for (asset in project.assets)
		{
			if (asset.embed != true)
			{
				var path = Path.combine(applicationDirectory, asset.targetPath);

				if (asset.type != AssetType.TEMPLATE)
				{
					System.mkdir(Path.directory(path));
					AssetHelper.copyAssetIfNewer(asset, path);
				}
				else
				{
					System.mkdir(Path.directory(path));
					AssetHelper.copyAsset(asset, path, context);
				}
			}
		}
	}

	private function updateUWP():Void
	{
		project = project.clone();

		var destination = targetDirectory + "/source/";
		System.mkdir(destination);

		var webfontDirectory = targetDirectory + "/obj/webfont";
		var useWebfonts = true;

		for (haxelib in project.haxelibs)
		{
			if (haxelib.name == "openfl-html5-dom" || haxelib.name == "openfl-bitfive")
			{
				useWebfonts = false;
			}
		}

		var fontPath;

		for (asset in project.assets)
		{
			if (asset.type == AssetType.FONT)
			{
				if (useWebfonts)
				{
					fontPath = Path.combine(webfontDirectory, Path.withoutDirectory(asset.targetPath));

					if (!FileSystem.exists(fontPath))
					{
						System.mkdir(webfontDirectory);
						System.copyFile(asset.sourcePath, fontPath);

						asset.sourcePath = fontPath;

						HTML5Helper.generateWebfonts(project, asset);
					}

					asset.sourcePath = fontPath;
					asset.targetPath = Path.withoutExtension(asset.targetPath);
				}
				else
				{
					// project.haxeflags.push (HTML5Helper.generateFontData (project, asset));
				}
			}
		}

		if (project.targetFlags.exists("xml"))
		{
			project.haxeflags.push("-xml " + targetDirectory + "/types.xml");
		}

		if (Log.verbose)
		{
			project.haxedefs.set("verbose", 1);
		}

		ModuleHelper.updateProject(project);

		var libraryNames = new Map<String, Bool>();

		for (asset in project.assets)
		{
			if (asset.library != null && !libraryNames.exists(asset.library))
			{
				libraryNames[asset.library] = true;
			}
		}

		// for (library in libraryNames.keys ()) {
		//
		// project.haxeflags.push ("-resource " + targetDirectory + "/obj/manifest/" + library + ".json@__ASSET_MANIFEST__" + library);
		//
		// }

		// project.haxeflags.push ("-resource " + targetDirectory + "/obj/manifest/default.json@__ASSET_MANIFEST__default");

		var context = generateContext();
		context.OUTPUT_DIR = targetDirectory;

		context.favicons = [];

		var icons = project.icons;

		if (icons.length == 0)
		{
			icons = [new Icon(System.findTemplate(project.templatePaths, "default/icon.svg"))];
		}

		// if (IconHelper.createWindowsIcon (icons, Path.combine (destination, "favicon.ico"))) {
		//
		// context.favicons.push ({ rel: "icon", type: "image/x-icon", href: "./favicon.ico" });
		//
		// }

		if (IconHelper.createIcon(icons, 192, 192, Path.combine(destination, "favicon.png")))
		{
			context.favicons.push({rel: "shortcut icon", type: "image/png", href: "./favicon.png"});
		}

		context.linkedLibraries = [];

		for (dependency in project.dependencies)
		{
			if (StringTools.endsWith(dependency.name, ".js"))
			{
				context.linkedLibraries.push(dependency.name);
			}
			else if (StringTools.endsWith(dependency.path, ".js") && FileSystem.exists(dependency.path))
			{
				var name = Path.withoutDirectory(dependency.path);

				context.linkedLibraries.push("./js/lib/" + name);
				System.copyIfNewer(dependency.path, Path.combine(destination, Path.combine("js/lib", name)));
			}
		}

		for (asset in project.assets)
		{
			var path = Path.combine(destination, asset.targetPath);

			if (asset.type != AssetType.TEMPLATE)
			{
				if (asset.type != AssetType.FONT)
				{
					System.mkdir(Path.directory(path));
					AssetHelper.copyAssetIfNewer(asset, path);
				}
				else if (useWebfonts)
				{
					System.mkdir(Path.directory(path));
					var ext = "." + Path.extension(asset.sourcePath);
					var source = Path.withoutExtension(asset.sourcePath);

					for (extension in [ext, ".eot", ".woff", ".svg"])
					{
						if (FileSystem.exists(source + extension))
						{
							System.copyIfNewer(source + extension, path + extension);
						}
						else
						{
							Log.warn("Could not find generated font file \"" + source + extension + "\"");
						}
					}
				}
			}
		}

		ProjectHelper.recursiveSmartCopyTemplate(project, "winjs/template", targetDirectory, context);

		var renamePaths = [
			"uwp-project.sln",
			"source/uwp-project.jsproj",
			"source/uwp-project_TemporaryKey.pfx"
		];
		var fullPath;

		for (path in renamePaths)
		{
			fullPath = targetDirectory + "/" + path;

			try
			{
				if (FileSystem.exists(fullPath))
				{
					File.copy(fullPath, targetDirectory + "/" + StringTools.replace(path, "uwp-project", project.app.file));
					FileSystem.deleteFile(fullPath);
				}
			}
			catch (e:Dynamic) {}
		}

		if (project.app.main != null)
		{
			ProjectHelper.recursiveSmartCopyTemplate(project, "haxe", targetDirectory + "/haxe", context);
			ProjectHelper.recursiveSmartCopyTemplate(project, "winjs/haxe", targetDirectory + "/haxe", context, true, false);
			ProjectHelper.recursiveSmartCopyTemplate(project, "winjs/hxml", targetDirectory + "/haxe", context);

			if (project.targetFlags.exists("webgl"))
			{
				ProjectHelper.recursiveSmartCopyTemplate(project, "webgl/hxml", targetDirectory + "/haxe", context, true, false);
			}
		}

		for (asset in project.assets)
		{
			var path = Path.combine(destination, asset.targetPath);

			if (asset.type == AssetType.TEMPLATE)
			{
				System.mkdir(Path.directory(path));
				AssetHelper.copyAsset(asset, path, context);
			}
		}
	}

	public override function watch():Void
	{
		var dirs = []; // WatchHelper.processHXML (getDisplayHXML (), project.app.path);
		var command = ProjectHelper.getCurrentCommand();
		System.watch(command, dirs);
	}

//	@ignore public override function install ():Void {}
	override public function install():Void
	{
		super.install();
		if (targetType == "winrt")
		{
			//if(project.winrtConfig.isAppx)
			//{
			//   TODO: pack in appx
			//}
			//else
			{
	        		uninstall();
	        		Log.info("run: Register app");
	        		var process = new sys.io.Process('powershell', ["-noprofile", "-command",'Add-AppxPackage -Path '+applicationDirectory + "/"+'AppxManifest.xml -Register']);
	        		if (process.exitCode() != 0) 
				{
					var message = process.stderr.readAll().toString();
	            			Log.error("Cannot register. " + message);
	        		}
	        		process.close();
			}
		}
	}

	@ignore public override function trace():Void {}

	//@ignore public override function uninstall ():Void {}
	override public function uninstall():Void
	{ 
		super.uninstall();
		if (targetType == "winrt")
		//if(project.winrtConfig.isAppx)
		//{
		//  TODO
		//}
		//else
		{
  			var appxName = project.meta.packageName;
  			Log.info("run: Remove previous registered app");
  			var process = new sys.io.Process('powershell', ["-noprofile", "-command",'Get-AppxPackage '+appxName+' | Remove-AppxPackage']);
  			if (process.exitCode() != 0)
			{
    				var message = process.stderr.readAll().toString();
    				Log.error("Cannot remove. " + message);
			}
			process.close();        
		}
	}


	public function winrtRun (arguments:Array<String>):Void
	{
	
		var dir = applicationDirectory;
		var haxeDir = targetDirectory + "/haxe"; 

		//if(project.winrtConfig.isAppx)
		//{
		//	Log.info("\n***Double click on "+project.app.file + ".Appx to install Appx");
		//}
		//else
		{
			var appxName = project.meta.packageName;
			var appxId = "App";
			var appxAUMID:String = null; 
			var appxInfoFile = haxeDir + "/appxinfo.txt";
			var kitsRoot10 = "C:\\Program Files (x86)\\Windows Kits\\10\\"; //%WindowsSdkDir%

			//get PackageFamilyappxName and set appxAUMID
			//	write app info in a file
			var cmd = 'Get-AppxPackage '+appxName+' | Out-File '+appxInfoFile+' -Encoding ASCII';
			trace("powershell " + cmd);
			var process3 = new sys.io.Process('powershell', [cmd]);
			if (process3.exitCode() != 0)
			{
				var message = process3.stderr.readAll().toString();
				Log.error("Cannot get PackageFamilyName. " + message);
			}
			process3.close();
			//	parse file
			if(sys.FileSystem.exists(appxInfoFile))
			{
				var fin = sys.io.File.read(appxInfoFile, false);
			  	try
			  	{
			  		while(true)
			  		{
				  		var str = fin.readLine();
				  		var split = str.split (":");
				  		var name = StringTools.trim(split[0]);
				  		if( name == "PackageFamilyName")
				  		{
				  			var appxPackageFamilyName = StringTools.trim(split[1]);
				  			if(appxPackageFamilyName!=null)
				  			{
								appxAUMID = appxPackageFamilyName+"!"+appxId;
								break;
				  			}
			  			}
		  			}
		  		}
		  		catch(e:haxe.io.Eof)
		  		{
			 		Log.error('Could not get PackageFamilyName from '+appxInfoFile);
		  		}
		  		fin.close();
			}

			Log.info("run: "+appxAUMID);
			Log.info(kitsRoot10+'App Certification Kit\\microsoft.windows.softwarelogo.appxlauncher.exe '+appxAUMID);
			var process4 = new sys.io.Process(kitsRoot10+'App Certification Kit\\microsoft.windows.softwarelogo.appxlauncher.exe', [appxAUMID]);
		}
	}
}
