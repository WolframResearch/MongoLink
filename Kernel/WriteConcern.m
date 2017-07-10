(*******************************************************************************

Write Concern object.
Note: we guarantee that we will always use MongoDB's defaults for this

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]

(*----------------------------------------------------------------------------*)
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

(*----------------------------------------------------------------------------*)
PackageScope["WriteConcernCreate"]

SetUsage[WriteConcernCreate,
"WriteConcernCreate[] creates an immutable WriteConcernObject[$$] with the default settings.
WriteConcernCreate[w$] where w$ is an integer >= 0. Used with replication, write \
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

Options[WriteConcernCreate] =
{
	"Journal" -> True,
	"Timeout" -> None
};

WriteConcernCreate[concern_Integer:1, opts:OptionsPattern[]] := Module[
	{handle, journal, timeout}
	,
	handle = CreateManagedLibraryExpression["MongoWriteConcern", MongoWriteConcern];
	{journal, timeout} = OptionValue[{"Journal", "Timeout"}];
	
	safeLibraryInvoke[WriteConcernSet, ManagedLibraryExpressionID[handle], concern];
	safeLibraryInvoke[WriteConcernSetJournal, ManagedLibraryExpressionID[handle], Boole[journal]];

	If[timeout =!= None,
		safeLibraryInvoke[WriteConcernSetWtimeout, ManagedLibraryExpressionID[handle], timeout]
	];
	(* Return handle to write concern *)
	handle
]

(*----------------------------------------------------------------------------*)
PackageScope["WriteConcernGetInfo"]

WriteConcernInfo[MongoWriteConcernObject[writeConcernObject_]] := Module[
	{handle, al, journal, timeout}
	,
	handle = CreateManagedLibraryExpression["MongoWriteConcern", MongoWriteConcern];
	{al, journal, timeout} = OptionValue[{"AcknowledgementLevel", "Journal", "Timeout"}];
(*	If[!MatchQ[opts, {_Integer, _String, _...}],*)
	
	(* Check if we need to change the mongoDB defaults *)
	If[al =!= Automatic ,
		safeLibraryInvoke[WriteConcernSet, ManagedLibraryExpressionID[handle], al]
	];
	
	If[journal =!= Automatic,
		safeLibraryInvoke[WriteConcernSetJournal, ManagedLibraryExpressionID[handle], Boole[journal]]
	];
	
	If[timeout =!= Automatic,
		safeLibraryInvoke[WriteConcernSetWtimeout, ManagedLibraryExpressionID[handle], timeout]
	];
	(* Return handle to write concern *)
	handle
]
