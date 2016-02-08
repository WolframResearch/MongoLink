(*******************************************************************************

Common: global variables plus common utility functions

*******************************************************************************)

Package["MongoLink`"]

(*** Package Exports ***)
PackageExport["$MongoLinkLib"]
PackageExport["LibraryFunctionFailureQ"]
PackageExport["MongoFailureMessage"]
PackageExport["MongoGetLastError"]

(******************************************************************************)

(****** Global Variables ******)
$MongoLinkLib = FindLibrary["MongoLink"];


(******************************************************************************)
(****** Load Library Functions ******)

MongoGetLastError = LibraryFunctionLoad[$MongoLinkLib, "WL_MongoGetLastError", 
	{
	}, 
	"UTF8String"						
	]	

(******************************************************************************)
(****** Load Library Functions ******)

MongoEnableLogging = LibraryFunctionLoad[$MongoLinkLib, "WL_EnableLogging", 
	{
	}, 
	"Void"						
	]	
	
(******************************************************************************)

LibraryFunctionFailureQ[call_] :=
	If[Head@call === LibraryFunctionError, True, False]

(******************************************************************************)

MongoFailureMessage[parentSymbol_] := Module[
	{lastError},
	lastError = MongoGetLastError[];
	lastError = If[TrueQ@LibraryFunctionFailureQ@lastError, "Unknown Error", lastError];
	parentSymbol::mongoError = lastError;
	Message[parentSymbol::mongoError];
]

(******************************************************************************)

(* Mongo Unix time is accurate to the millisecond *)
FromMillisecondUnixTime[time_Integer] := Module[
	{dateList}
	,
	dateList = DateList@FromUnixTime[time / 1000.];
	DateObject[dateList, DateFormat -> {"DateTime", ":", "Millisecond"}]
]

ToMillisecondUnixTime[date_DateObject] := 1000 * (UnixTime@date + FractionalPart@date["Second"])