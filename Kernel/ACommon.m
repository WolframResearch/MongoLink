(*******************************************************************************

Common: global variables plus common utility functions

*******************************************************************************)

Package["MongoLink`"]

(****** Global Variables ******)
$LibraryResources = FileNameJoin[{ParentDirectory[DirectoryName @ $InputFileName], "LibraryResources", $SystemID}];

PackageScope["$MongoLinkLib"]

$MongoLinkLib = Switch[$OperatingSystem,
	"MacOSX", 
		FileNameJoin[{$LibraryResources, "MongoLink.dylib"}],
	"Windows",
		FileNameJoin[{$LibraryResources, "MongoLink.dll"}],
	"Unix",
		FileNameJoin[{$LibraryResources, "MongoLink.so"}]
]

(***** Initialize Library *****)

MongoInitialize = LibraryFunctionLoad[$MongoLinkLib, "WL_MongoInitialize", 
	{
	}, 
	"Void"						
	]	

(* this needs to be called precisely once in a session *)
If[!ValueQ[$MongoInitialized], $MongoInitialized = False];
If[!TrueQ[$MongoInitialized], MongoInitialize[]; $MongoInitialized = True];

(*----------------------------------------------------------------------------*)

PackageScope["MongoGetLastError"]

MongoGetLastError = LibraryFunctionLoad[$MongoLinkLib, "WL_MongoGetLastError", 
	{
	},
	"UTF8String"				
	]	

(*----------------------------------------------------------------------------*)
PackageScope["LibraryFunctionFailureQ"]

LibraryFunctionFailureQ[call_] :=
	If[Head[call] === LibraryFunctionError, True, False]


(*----------------------------------------------------------------------------*)
General::mongolibuneval = "Library function `` with args `` did not evaluate.";

PackageScope["safeLibraryInvoke"]

safeLibraryInvoke[func_, args___] :=
    Replace[
        func[args], 
        {
            _LibraryFunctionError :> MongoPanic[],
            _LibraryFunction[___] :> 
            	(Message[General::mongolibuneval, func[[2]], {args}];
            	Throw[$Failed])	
        }
    ];

MongoPanic[] := Module[
	{lastError},
	lastError = MongoGetLastError[];
	lastError = If[TrueQ @ LibraryFunctionFailureQ[lastError], 
		"Unknown Error", 
		lastError
	];
	General::mongoError = lastError;
	Message[General::mongoError];
	Throw[$Failed]
]

(*----------------------------------------------------------------------------*)
(* Mongo Unix time is accurate to the millisecond *)

PackageScope["FromMillisecondUnixTime"]

FromMillisecondUnixTime[time_Integer] := Module[
	{dateList}
	,
	dateList = DateList @ FromUnixTime[time / 1000.];
	DateObject[dateList, DateFormat -> {"DateTime", ":", "Millisecond"}]
]

PackageScope["ToMillisecondUnixTime"]

ToMillisecondUnixTime[date_DateObject] := 1000 * (UnixTime[date] + FractionalPart[date["Second"]])

(******************************************************************************)
PackageScope["fileConform"]

(* this takes a file *)
fileConform[file_String] := Module[
	{parentSymbol::invfile = "The file `` doesn't exist."},
	If[!FileExistsQ[file],
		Message[parentSymbol::invfile, file];
		Throw[$Failed]
	];
	file
]

fileConform[parentSymbol_, File[file_]] := fileConform[parentSymbol, file]
fileConform[_, None] := "";

fileConform[parent_, obj_] := Module[
	{
		parent::invfile = "Object `` is not a String, File[...] or None."
	},
	Message[parent::invfile, obj];
	Throw[$Failed]
]
