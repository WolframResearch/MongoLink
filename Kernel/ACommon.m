(*******************************************************************************

Common: global variables plus common utility functions

*******************************************************************************)
random change

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

(*----------------------------------------------------------------------------*)

PackageScope["MongoGetLastError"]

MongoGetLastError = LibraryFunctionLoad[$MongoLinkLib, "WL_MongoGetLastError", 
	{
	}, 
	"UTF8String"						
	]	

(*----------------------------------------------------------------------------*)

PackageScope["MongoEnableLogging"]

MongoEnableLogging = LibraryFunctionLoad[$MongoLinkLib, "WL_EnableLogging", 
	{
	}, 
	"Void"						
	]

(*----------------------------------------------------------------------------*)
PackageScope["LibraryFunctionFailureQ"]

LibraryFunctionFailureQ[call_] :=
	If[Head[call] === LibraryFunctionError, True, False]

(*----------------------------------------------------------------------------*)
PackageScope["MongoFailureMessage"]

MongoFailureMessage[parentSymbol_] := Module[
	{lastError},
	lastError = MongoGetLastError[];
	lastError = If[TrueQ @ LibraryFunctionFailureQ[lastError], 
		"Unknown Error", 
		lastError
	];
	parentSymbol::mongoError = lastError;
	Message[parentSymbol::mongoError];
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

