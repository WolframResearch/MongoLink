(*******************************************************************************

Common: global variables plus common utility functions

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]

(*----------------------------------------------------------------------------*)
(* declare some common symbols, overloaded for different objects *)
PackageScope["getMLE"]
getMLE[___] := Panic["Invalid argument to getMLE"]

PackageScope["getMLEID"]
getMLEID[x_ /; ManagedLibraryExpressionQ[x]] := ManagedLibraryExpressionID[x]
getMLEID[___] := Panic["Invalid argument to getMLEID"]

PackageScope["getClient"]
getClient[___] := Panic["Invalid argument to getClient"]

(*----------------------------------------------------------------------------*)
(****** Global Variables ******)

$MongoLinkBaseDir = FileNameTake[$InputFileName, {1, -3}];

PackageScope["$LibraryResources"]
$LibraryResources = FileNameJoin[{
	ParentDirectory[DirectoryName @ $InputFileName], 
	"LibraryResources", 
	$SystemID
}];

(* note: the build process puts the ca file into LibaryResources, but local paclet 
checkouts don't have this dir, and have the CA file in different place. Perhaps 
put in same place? *)
PackageExport["$MongoDefaultCAFile"]
$MongoDefaultCAFile := $MongoDefaultCAFile = Module[
	{file1, file2},
	file1 = FileNameJoin[{$MongoLinkBaseDir, "Kernel", "SSL", "client.pem"}];
	file2 = FileNameJoin[{$LibraryResources, "client.pem"}];
	If[FileExistsQ[file2], Return @ File[file2]];
	If[FileExistsQ[file1], File[file2], $Failed]
]

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

(* see http://mongoc.org/libmongoc/current/init-cleanup.html. We build with 
 --disable-automatic-init-and-cleanup, as its deprecated, so we need to initialize
 ourselves. *)
 
MongoInitialize = LibraryFunctionLoad[$MongoLinkLib, "WL_MongoInitialize", 
	{}, 
	"Void"						
	]	
	
(* this needs to be called precisely once in a session *)
If[!ValueQ[$MongoInitialized], $MongoInitialized = False];
If[!TrueQ[$MongoInitialized], MongoInitialize[]; $MongoInitialized = True];

(*----------------------------------------------------------------------------*)
PackageScope["MongoGetLastError"]

MongoGetLastError = LibraryFunctionLoad[$MongoLinkLib, "WL_MongoGetLastError", 
	{},
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
            _LibraryFunctionError :> MongoPanic[func],
            _LibraryFunction[___] :> ThrowFailure["mongolibuneval", func[[2]], {args}]
        }
    ];

General::mongoliberr = "C Function `` failed. Error from Mongo C Driver: \"``\"";

MongoPanic[f_] := Module[
	{lastError},
	lastError = MongoGetLastError[];
	If[TrueQ @ LibraryFunctionFailureQ[lastError], 
		lastError = "Unknown Error";
	];
	ThrowFailure["mongoliberr", f[[2]], lastError];
]

(*----------------------------------------------------------------------------*)
(* Mongo Unix time is accurate to the millisecond *)

PackageScope["FromMillisecondUnixTime"]

FromMillisecondUnixTime[time_] := Module[
	{dateList}
	,
	dateList = DateList @ FromUnixTime[time / 1000.];
	DateObject[dateList, DateFormat -> {"DateTime", ":", "Millisecond"}]
]

PackageScope["ToMillisecondUnixTime"]

ToMillisecondUnixTime[date_DateObject] := 1000 * (UnixTime[date] + FractionalPart[date["Second"]])

(*----------------------------------------------------------------------------*)
PackageScope["fileConform"]

General::mongonff = "The file `` doesn't exist.";
fileConform[file_String] := (
	If[!FileExistsQ[file],
		ThrowFailure["mongonff", file];
	];
	file
)

fileConform[File[file_]] := fileConform[file]
fileConform[None] := "";

General::mongoinvfile = "Object `` is not a String, File[...] or None."
fileConform[file_] := ThrowFailure["mongonff", file];
