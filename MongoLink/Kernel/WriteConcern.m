(*******************************************************************************

Write Concern object.

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]

PackageScope["writeConcernMLE"] (* write concern ManagedLibraryExpression *)

(*----------------------------------------------------------------------------*)
(****** Load Library Functions ******)

writeConcernNew = LibraryFunctionLoad[$MongoLinkLib, "WL_WriteConcernNew", 
	{
		Integer		(* write concern handle key *)
	},
	"Void"
]	

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

(*----------------------------------------------------------------------------*)
PackageExport["MongoWriteConcern"]

(* This is a utility function defined in GeneralUtilities, which makes a nicely
formatted display box *)
DefineCustomBoxes[MongoWriteConcern, 
	e:MongoWriteConcern[wcMLE_] :> Block[{},
	BoxForm`ArrangeSummaryBox[
		MongoWriteConcern, e, None, 
		{
			BoxForm`SummaryItem[{"ID: ", getMLEID[wcMLE]}]
		},
		{},
		StandardForm
	]
]];

getMLE[MongoWriteConcern[wcMLE_]] := wcMLE;
getMLEID[MongoWriteConcern[wcMLE_]] := ManagedLibraryExpressionID[wcMLE];

(*----------------------------------------------------------------------------*)
PackageExport["MongoWriteConcernCreate"]

MongoWriteConcernCreate::journal = 
	"The Option \"Journal\" must have value True or False, but value `` was given.";
MongoWriteConcernCreate::timeout = 
	"The Option \"Timeout\" must have value None or a non-negative integer, but value `` was given.";
MongoWriteConcernCreate::concern = 
	"The first argument must be a positive integer or 0, but `` was given.";

Options[MongoWriteConcernCreate] =
{
	"Journal" -> True,
	"Timeout" -> None
};

MongoWriteConcernCreate[concern_Integer:1, opts:OptionsPattern[]] := 
CatchFailureAsMessage @ Module[
	{handle, journal, timeout}
	,
	(** Options Parsing **)
	{journal, timeout} = OptionValue[{"Journal", "Timeout"}];
	If[!BooleanQ[journal],
		ThrowFailure[MongoWriteConcernCreate::journal, journal];
	];
	If[Not @ ((timeout === None) || (IntegerQ[timeout] && Positive[timeout])),
		ThrowFailure[MongoWriteConcernCreate::timeout, timeout];
	];
	If[!IntegerQ[concern] || (concern < 0),
		ThrowFailure[MongoWriteConcernCreate::concern, concern];
	];

	handle = CreateManagedLibraryExpression["WriteConcern", writeConcernMLE];
	safeLibraryInvoke[writeConcernNew, getMLEID[handle]];
	safeLibraryInvoke[WriteConcernSet, getMLEID[handle], concern];
	safeLibraryInvoke[
		WriteConcernSetJournal, 
		getMLEID[handle], 
		Boole[journal]
	];

	If[timeout =!= None,
		safeLibraryInvoke[WriteConcernSetWtimeout, getMLEID[handle], timeout]
	];
	(* Return handle to write concern *)
	MongoWriteConcern[handle]
]
