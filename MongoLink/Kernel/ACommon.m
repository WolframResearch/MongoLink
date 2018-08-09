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
	If[FileExistsQ[file1], File[file1], $Failed]
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

(* For windows: we need to explicitly load dependencies, not rely on autoloading *)
If[$OperatingSystem === "Windows",
	LibraryLoad @ FileNameJoin[{$LibraryResources, "libbson-1.0.dll"}];
	LibraryLoad @ FileNameJoin[{$LibraryResources, "libmongoc-1.0.dll"}];
];

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

PackageScope["MongoEraseLastError"]

MongoEraseLastError = 
	LibraryFunctionLoad[$MongoLinkLib, "WL_MongoEraseLastError", {}, Null]

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
	MongoEraseLastError[];
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

ToMillisecondUnixTime[date_DateObject] := Module[
	{sec},
	sec = date["Second"];
	If[MissingQ[sec], sec = 0];
	1000 * (UnixTime[date] + FractionalPart[sec])
]

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

(*----------------------------------------------------------------------------*)
PackageScope["popAssociation"]

SetAttributes[popAssociation, HoldFirst]
popAssociation[assoc_, keys_] := Module[
	{out},
	out = Lookup[assoc, keys];
	KeyDropFrom[assoc, keys];
	out
]

popAssociation[assoc_, keys_, default_] := Module[
	{out},
	out = Lookup[assoc, keys, default];
	KeyDropFrom[assoc, keys];
	out
]


(*----------------------------------------------------------------------------*)
(* opts process: will eventually do something more complicated, like lower-case
first character to allow camel case opts
*)

PackageScope["processOpts"]

processOpts[opts_Association, defaults_Association, changeRules_List] := Module[
	{opts2},
	opts2 = replaceAssociationKeys[opts, changeRules];
	opts2 = KeyMap[Decapitalize, opts2];
	Join[defaults, opts2]
]

processOpts[opts_Association, defaults_Association] := 
	processOpts[opts, defaults, {}]

(* this can probably be done better *)
replaceAssociationKeys[assoc_, rules_] := Module[
	{old, new, look, keyPos},
	If[Length[rules] === 0, Return[assoc]];

	old = Keys[rules];
	new = Values[rules];
	look = Lookup[assoc, old];
	keyPos = Flatten @ Position[look, Except[_Missing], 1, Heads->False];
	KeyDrop[old] @ Join[assoc, AssociationThread[new[[keyPos]] -> look[[keyPos]]]]
]

PackageScope["optsToBSON"]
optsToBSON[opts_Association, defaults_Association, changeRules_List] := Module[
	{opts2},
	opts2 = processOpts[opts, defaults, changeRules];
	iToBSON[opts2]
]

optsToBSON[opts_Association, defaults_Association] :=
	optsToBSON[opts, defaults, {}]

optsToBSON[opts_Association] :=
	optsToBSON[opts, <||>, {}]

(*----------------------------------------------------------------------------*)
(* This function converts a number of WL inputs to a Mongo millisecond time format 
	Note: there cannot be a 0 time in mongo, so 0 is infinity
*)

PackageScope["timeToMilliseconds"]
timeToMilliseconds[x_Integer] := x
timeToMilliseconds[Infinity] := 0
timeToMilliseconds[x_Quantity] := QuantityMagnitude @ UnitConvert[x, "Milliseconds"]
timeToMilliseconds[x_] := x

