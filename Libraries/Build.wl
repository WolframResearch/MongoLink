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
	"CompileOptions" -> "",
	"ShellCommandFunction" -> None
};

BuildMongoLink[opts:OptionsPattern[]] := Catch @ Module[
	{
	 compileOpts, wlSrc, lib, libResourceLib, libResourceDir,
	 libNames, fullIncl, includeDir, libDir
	}
	,
	compileOpts = OptionValue["CompileOptions"];
	Switch[$OperatingSystem,
		"Windows", 
			includeDir = {"C:\\mongo-c-driver"};
			libDir = {"C:\\mongo-c-driver"}
		,
		"MacOSX",
			compileOpts = StringJoin[
				"-std=c++11 ", 
				"-Xlinker -install_name ",
				"-Xlinker @rpath/MongoLink.dylib ",
				"-Xlinker -rpath -Xlinker @loader_path/ ",
				compileOpts
			];
			includeDir = 
				{"/usr/local/include/libbson-1.0", "/usr/local/include/libmongoc-1.0"};
			libDir = {"/usr/local/lib"};
			libDir = {"/Users/sebastianb/Documents/workspace/MongoC/1.7.0/MacOSX-x86-64/libcxx-min10.9/lib/"}
		,
		"Unix",
			compileOpts = "-std=c++11"  <> compileOpts;
	];
	libNames = 	{"mongoc-1.0.0", "bson-1.0.0"};
	
	(* WL Source *)
	wlSrc = FileNames["*.cpp", {FileNameJoin[{$RootDir, "Libraries", "MongoLink"}]}];	
	fullIncl = Join[{FileNameJoin[{$RootDir, "Libraries", "MongoLink"}]}, includeDir];
	(* Build *)
	lib = CreateLibrary[
		wlSrc, "MongoLink",
		"IncludeDirectories"-> fullIncl,
		"Libraries" -> libNames,
		"LibraryDirectories" -> libDir,
		"CompileOptions" -> compileOpts,
		"Language" -> "C++",
		"Debug" -> OptionValue["Debug"],
		"CleanIntermediate"-> True,
		"ShellCommandFunction" -> OptionValue["ShellCommandFunction"]
	];
	
	(* Postprocessing: copy build to paclet *)
	libResourceDir = FileNameJoin[{$RootDir , "MongoLink", "LibraryResources", $SystemID}];
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