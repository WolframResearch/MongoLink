(*******************************************************************************

Common: global variables plus common utility functions

*******************************************************************************)

Package["MongoLink`"]

(*** Package Exports ***)
PackageExport["$MongoLinkLib"]
PackageExport["LibraryFunctionFailureQ"]
PackageExport["MongoFailureMessage"]

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