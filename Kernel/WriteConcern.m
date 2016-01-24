(*******************************************************************************

Write Concern object.
Note: we guarantee that we will always use MongoDB's defaults for this

*******************************************************************************)

Package["MongoLink`"]

(*** Package Exports ***)

PackageExport["WriteConcernCreate"]
PackageExport["MongoWriteConcern"]
PackageExport["WriteConcernGetInfo"]

(******************************************************************************)

(****** Load Library Functions ******)


WriteConcernSet = LibraryFunctionLoad[$MongoLinkLib, "WL_WriteConcernSet", 
	{
		Integer,		(* write concern handle key *)
		Integer			(* parameter *)
	}, 
	"Void"						
]	

WriteConcernSetWtimeout = LibraryFunctionLoad[$MongoLinkLib, "WL_WriteConcernSetWtimeout", 
	{
		Integer,		(* write concern handle key *)
		Integer			(* timeout time in milliseconds *)
	}, 
	"Void"						
]	

WriteConcernSetJournal = LibraryFunctionLoad[$MongoLinkLib, "WL_WriteConcernSetJournal", 
	{
		Integer,		(* write concern handle key *)
		Integer			(* boole *)
	}, 
	"Void"						
]	

WriteConcernGetInfo = LibraryFunctionLoad[$MongoLinkLib, "WL_WriteConcernGetInfo", 
	Automatic, 
	LinkObject						
]

(******************************************************************************)

Options[WriteConcernCreate] =
{
	"AcknowledgementLevel" -> Automatic,
	"Journal" -> Automatic,
	"Timeout" -> Automatic
};

WriteConcernCreate[opts:OptionsPattern[]] := Module[
	{handle, al, journal, timeout}
	,
	handle = CreateManagedLibraryExpression["MongoWriteConcern", MongoWriteConcern];
	{al, journal, timeout} = OptionValue[{"AcknowledgementLevel", "Journal", "Timeout"}];
(*	If[!MatchQ[opts, {_Integer, _String, _...}],*)
	
	(* Check if we need to change the mongoDB defaults *)
	If[al =!= Automatic ,
		WriteConcernSet[ManagedLibraryExpressionID@handle, al]
	];
	
	If[journal =!= Automatic,
		WriteConcernSetJournal[ManagedLibraryExpressionID@handle, Boole@journal]
	];
	
	If[timeout =!= Automatic,
		WriteConcernSetWtimeout[ManagedLibraryExpressionID@handle, timeout]
	];
	(* Return handle to write concern *)
	handle
]


(******************************************************************************)

WriteConcernInfo[writeConcernObject_MongoWriteConcern] := Module[
	{handle, al, journal, timeout}
	,
	handle = CreateManagedLibraryExpression["MongoWriteConcern", MongoWriteConcern];
	{al, journal, timeout} = OptionValue[{"AcknowledgementLevel", "Journal", "Timeout"}];
(*	If[!MatchQ[opts, {_Integer, _String, _...}],*)
	
	(* Check if we need to change the mongoDB defaults *)
	If[al =!= Automatic ,
		WriteConcernSet[ManagedLibraryExpressionID@handle, al]
	];
	
	If[journal =!= Automatic,
		WriteConcernSetJournal[ManagedLibraryExpressionID@handle, Boole@journal]
	];
	
	If[timeout =!= Automatic,
		WriteConcernSetWtimeout[ManagedLibraryExpressionID@handle, timeout]
	];
	(* Return handle to write concern *)
	handle
]
