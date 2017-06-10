BeginPackage["BuildMongoLink`"]

Get["GeneralUtilities`"];
Get["CCompilerDriver`"];

BuildMongoLink;


Begin["`Private`"]

$RootDir = DirectoryName@DirectoryName@$InputFileName;

(*************************************************************************)
SetUsage[BuildMongoLink,
"BuildMongoLink[mongoDir$, mongoLib$] builds MongoLink library. mongoDir$ is \
the directory of the Mongo C driver source code (this is needed for include files). \
mongoLib$ is the full path of the Mongo C Driver static library. Its assumed that the version \
of the driver mongoDir$ is the same as the static library mongoLib$.
"
]

Options[BuildMongoLink] = {
	"Debug" -> False
};

BuildMongoLink[mongoIncDir_, bsonIncDir_, mongoLibDir_List, opts:OptionsPattern[]] := Module[
	{
	 compileOpts, wlSrc, includeDir, lib, libResourceLib, libResourceDir
	}
	,
	Print@$RootDir;
	If[Not @ DirectoryQ[mongoIncDir],
		Print[mongoIncDir <> " is not a directory."];
		Return[$Failed];
	];
	If[Not @ DirectoryQ[bsonIncDir],
		Print[bsonIncDir <> " is not a directory."];
		Return[$Failed];
	];
	If[Not @ FileExistsQ[#],
		Print[# <> " is not a valid file."];
		Return[$Failed];
	]& /@ mongoLibDir;

	compileOpts = Switch[$OperatingSystem,
		"Windows", 
			"-std=c++11"
		,
		"MacOSX",
			"-std=c++11"
		,
		"Unix",
			"-std=c++11"
	];

	(* WL Source *)
	wlSrc = FileNames["*.cpp", {FileNameJoin[{$RootDir, "Libraries", "MongoLink"}]}];	
	includeDir = {mongoIncDir, bsonIncDir, FileNameJoin[{$RootDir, "Libraries"}]};
	
	(* Build *)
	lib = CreateLibrary[
		wlSrc, "MongoLink",
		"IncludeDirectories"-> includeDir,
		"Libraries" -> {"mongoc-1.0", "bson-1.0"},
		"LibraryDirectories" -> mongoLibDir,
		"CompileOptions"->compileOpts,
		"Language" -> "C++",
		"Debug" -> OptionValue["Debug"],
		"CleanIntermediate"-> True
	];
	
	(* copy build to paclet *)
	libResourceDir = FileNameJoin[{$RootDir , "LibraryResources", $SystemID}];
	libResourceLib = FileNameJoin[{libResourceDir, FileNameTake[lib]}];
	
	If[FileExistsQ[libResourceLib], 
		DeleteFile[libResourceLib]
	]; 
	If[Not @ FileExistsQ[libResourceDir], 
		CreateDirectory[libResourceDir]
	];
	CopyFile[lib, libResourceLib];
	
	(* test whether lib can be loaded *)
	LibraryLoad[libResourceLib];
	{lib, LibraryLink`$LibraryError}
]

(*************************************************************************)
End[ ]

EndPackage[ ]