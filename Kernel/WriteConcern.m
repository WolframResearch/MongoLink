(*******************************************************************************

Write Concern object.

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]

PackageScope["MongoWriteConcern"]

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
PackageExport["MongoWriteConcernObject"]

(* This is a utility function defined in GeneralUtilities, which makes a nicely
formatted display box *)
DefineCustomBoxes[MongoWriteConcernObject, 
	e:MongoWriteConcernObject[id_] :> Block[{},
	BoxForm`ArrangeSummaryBox[
		MongoWriteConcernObject, e, None, 
		{
			BoxForm`SummaryItem[{"ID: ", ManagedLibraryExpressionID[id]}]
		},
		{},
		StandardForm
	]
]];

(*----------------------------------------------------------------------------*)
PackageExport["MongoWriteConcernCreate"]

SetUsage[MongoWriteConcernCreate,
"MongoWriteConcernCreate[] creates an immutable WriteConcernObject[$$] with the default settings.
MongoWriteConcernCreate[w$] where w$ is an integer >= 0. Used with replication, write \
operations will block until they have been replicated to the specified number or \
tagged set of servers. w$ always includes the replica set primary (e.g. \
w$ = 3 means write to the primary and wait until replicated to two secondaries). \
w$ = 0 disables acknowledgement of write operations and can not be used with \
other write concern options.

The following options are available:
| 'Journal' | True | block until write operations have been committed to the journal. \
Cannot be used in combination with fsync. Prior to MongoDB 2.6 this option was ignored \
if the server was running without journaling. Starting with MongoDB 2.6 write \
operations will fail with an exception if this option is used when the server \
is running without journaling. |
| 'Timeout' | None | Used in conjunction with w$. Specify a value in milliseconds \
to control how long to wait for write propagation to complete. If replication \
does not complete in the given timeframe, a timeout exception is raised.|
"
]

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

MongoWriteConcernCreate[concern_Integer:1, opts:OptionsPattern[]] := Catch @ Module[
	{handle, journal, timeout}
	,
	(** Options Parsing **)
	{journal, timeout} = OptionValue[{"Journal", "Timeout"}];
	If[!BooleanQ[journal],
		Message[MongoWriteConcernCreate::journal, journal];
		Throw[$Failed]
	];
	If[Not @ ((timeout === None) || (IntegerQ[timeout] && Positive[timeout])),
		Message[MongoWriteConcernCreate::timeout, timeout];
		Throw[$Failed]
	];
	If[!IntegerQ[concern] || (concern < 0),
		Message[MongoWriteConcernCreate::concern, concern];
		Throw[$Failed]
	];

	handle = CreateManagedLibraryExpression["MongoWriteConcern", MongoWriteConcern];
	safeLibraryInvoke[writeConcernNew, ManagedLibraryExpressionID[handle]];
	safeLibraryInvoke[WriteConcernSet, ManagedLibraryExpressionID[handle], concern];
	safeLibraryInvoke[WriteConcernSetJournal, ManagedLibraryExpressionID[handle], Boole[journal]];

	If[timeout =!= None,
		safeLibraryInvoke[WriteConcernSetWtimeout, ManagedLibraryExpressionID[handle], timeout]
	];
	(* Return handle to write concern *)
	MongoWriteConcernObject[handle]
]
