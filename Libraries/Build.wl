BeginPackage["BuildMongoLink`"]

Get["GeneralUtilities`"];
Get["CCompilerDriver`"];

BuildMongoLink;

Begin["`Private`"]

$RootDir = DirectoryName@DirectoryName@$InputFileName;

(*************************************************************************)
SetUsage[BuildMongoLink,
"BuildMongoLink[includeDir$, libdir$] builds MongoLink library. mongoDir$ is \
the directory of the Mongo C driver source code (this is needed for include files). \
mongoLib$ is the full path of the Mongo C Driver static library. Its assumed that the version \
of the driver mongoDir$ is the same as the static library mongoLib$.
"
]

Options[BuildMongoLink] = {
	"Debug" -> False,
	"StaticLibrary" -> False
};

BuildMongoLink[includeDir_List, libDir_List, opts:OptionsPattern[]] := Catch @ Module[
	{
	 compileOpts, wlSrc, lib, libResourceLib, libResourceDir,
	 libNames, fullIncl
	}
	,
	If[(includeDir =!= Automatic) && (Not @ FileExistsQ[#]),
		Print[# <> " is not a valid file."];
		Throw[$Failed];
	]& /@ Join[includeDir, libDir];

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
	
	libNames = 	If[OptionValue["StaticLibrary"],
		{"mongoc-static-1.0", "bson-static-1.0", "ssl", "crypto"},
		{"mongoc-1.0", "bson-1.0"}
	];
	
	(* WL Source *)
	wlSrc = FileNames["*.cpp", {FileNameJoin[{$RootDir, "Libraries", "MongoLink"}]}];	
	fullIncl = Join[
		includeDir, 
		{FileNameJoin[{$RootDir, "Libraries", "MongoLink"}]}
	];

	(* Build *)
	lib = CreateLibrary[
		wlSrc, "MongoLink",
		"IncludeDirectories"-> fullIncl,
		"Libraries" -> libNames,
		"LibraryDirectories" -> libDir,
		"CompileOptions" -> compileOpts,
		"Language" -> "C++",
		"Debug" -> OptionValue["Debug"],
		"CleanIntermediate"-> True
	];
	
	(* Postprocessing: copy build to paclet *)
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