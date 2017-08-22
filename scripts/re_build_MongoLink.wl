Needs["CCompilerDriver`"];

$MongoLink = FileNameJoin[{DirectoryName[$InputFileName], "..", "Libraries", "MongoLink"}];

$MathLink = FileNameJoin[{AntProperty["checkout_directory"], "MathLink", "CompilerAdditions"}];
$MongoC = FileNameJoin[{AntProperty["checkout_directory"], "MongoC"}];
$RuntimeLibrary = FileNameJoin[{AntProperty["checkout_directory"], "RuntimeLibrary", AntProperty["system_id"]}];

$Libraries = Switch[$OperatingSystem,
    "MacOSX",	{ "mongoc-1.0.0", "bson-1.0.0" },
    "Unix",		{ "mongoc-1.0",   "bson-1.0"   },
    "Windows",	{ "mongoc-1.0",   "bson-1.0" }
    ];

(* C++ 11 features will require stdc++_nonshared *)
If[$OperatingSystem === "Unix" && $ProcessorType =!= "ARM",
 	AppendTo[$Libraries, "stdc++_nonshared"]
 	];

$MongoLinkLib = CreateLibrary[

	FileNames["*.cpp", {$MongoLink}],
	"MongoLink",

	"CleanIntermediate" -> True,

	"CompileOptions" ->
		Switch[$OperatingSystem,
			"MacOSX",	"-std=c++11",
			"Unix",		"-std=c++11",
			"Windows",	"/EHsc"
		],

	"CompilerInstallation" ->
		Switch[$OperatingSystem,
			"MacOSX",	Automatic,
			_,			Environment["COMPILER_INSTALLATION"]
		],

	"IncludeDirectories"-> {
		$MongoLink,
		FileNameJoin[{$MongoC, "include", "libmongoc-1.0"}],
		FileNameJoin[{$MongoC, "include", "libbson-1.0"}]
		},

	"Language" -> "C++",

	"Libraries" -> $Libraries,

	"LibraryDirectories" -> {
		FileNameJoin[{$MongoC, "lib"}]
		},

	"LinkerOptions" ->
        Switch[$OperatingSystem,
            "MacOSX",   {"-install_name", "@rpath/MongoLink.dylib", "-rpath", "@loader_path/"},
            "Unix",     {"--enable-new-dtags", "-rpath='$ORIGIN'"},
            _,          {}
		],

	"ShellCommandFunction" -> Global`AntLog,
	"ShellOutputFunction" -> Global`AntLog,

	"SystemIncludeDirectories" -> {
		FileNameJoin[{$MathLink}],
		$RuntimeLibrary
		},

	"SystemLibraryDirectories" -> Switch[$OperatingSystem,
		"MacOSX",
			{
			"-F" <> $MathLink,
			$RuntimeLibrary
			},
		_,
			{
			$MathLink,
			$RuntimeLibrary
			}
		],

	"TargetDirectory" -> FileNameJoin[{AntProperty["files_directory"], AntProperty["component"], "LibraryResources", AntProperty["system_id"]}],
	"TargetSystemID" -> AntProperty["system_id"],

	"WorkingDirectory" -> AntProperty["scratch_directory"]
	];

If[FailureQ[$MongoLinkLib], AntFail["Library was not generated."]];
