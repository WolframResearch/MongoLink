(* ::Package:: *)

(* User needs to set *)

$MongoLibDir = {"/usr/local"};
$MongoInc = {"/usr/local/include/libmongoc-1.0", "/usr/local/include/libbson-1.0"}

(* Automatic *)
Needs["CCompilerDriver`"];
$LibrariesDirectory = DirectoryName @ $InputFileName;
Print@$LibrariesDirectory;

Switch[$OperatingSystem,
	"Windows", 
		$CompileOptions = "-std=c++11";
		$MongoLib = {"mongoc-1.0.0", "bson-1.0.0"};
	,
	"MacOSX",
		$CompileOptions = "-std=c++11"; 
		$MongoLib = {"mongoc-1.0.0", "bson-1.0.0"};
	,
	"Unix",
		$CompileOptions = "-std=c++11 -Wl,-rpath=/usr/local/lib";
		$MongoLib = {"mongoc-1.0", "bson-1.0"};
	
];

(* WL Source *)
$CSourceDir  = FileNameJoin[{$LibrariesDirectory, "MongoLink"}];
$WLSource = FileNames["*.cpp", {FileNameJoin[{$LibrariesDirectory, "MongoLink"}]}];
$WLInclude = {$CSourceDir};

(* LibraryLinkTools Source *)
$LibLinkToolsInc = {FileNameJoin[{$LibrariesDirectory, "MongoLink", "librarylinktools"}]};

(* Build *)
$Include = Join[$WLInclude, $MongoInc, $LibLinkToolsInc];
$Libraries = Join[$MongoLib];
$LibraryDir = Join[$MongoLibDir];

$MongoLinkLib = CreateLibrary[
	$WLSource, "MongoLink",
	"IncludeDirectories"-> $Include,
	"Libraries" -> $Libraries,
	"CompileOptions"->$CompileOptions,
	"LibraryDirectories" -> $LibraryDir,
	"Language" -> "C++",
	"Debug" -> True,
	"CleanIntermediate"-> True
]
