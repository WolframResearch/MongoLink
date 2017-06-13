(*******************************************************************************

Client level functions

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]

(*----------------------------------------------------------------------------*)
(****** Load Library Functions ******)

clientHandleCreate = LibraryFunctionLoad[$MongoLinkLib, "WL_ClientHandleCreate", 
	{
		Integer,					(* client handle *)
		"UTF8String"				(* connection info *)
	}, 
	"Void"						
]

getDatabaseNames = LibraryFunctionLoad[$MongoLinkLib, "WL_GetDatabaseNames", 
	Automatic, LinkObject					
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoClientObject"]

(* This is a utility function defined in GeneralUtilities, which makes a nicely
formatted display box *)
DefineCustomBoxes[MongoClientObject, 
	e:MongoClientObject[id_] :> Block[{},
	BoxForm`ArrangeSummaryBox[
		MongoClientObject, e, None, 
		{BoxForm`SummaryItem[{"ID: ", ManagedLibraryExpressionID[id]}]},
		{},
		StandardForm
	]
]];

MongoClientObject[id_][database_String] := DatabaseConnect[id, database]

(*----------------------------------------------------------------------------*)
PackageExport["ClientConnect"]

ClientConnect::usage = 
"ClientConnect[] connects to the default URI, mongodb://localhost:27017, and \
returns a ClientConnectionObject[...].
ClientConnect[uri_] connects using the specified URI uri_.
"

ClientConnect[uri_String] := Module[
	{clientHandle, result},
	clientHandle = CreateManagedLibraryExpression["MongoClient", MongoClient];
	result = clientHandleCreate[ManagedLibraryExpressionID[clientHandle], uri];
	If[LibraryFunctionFailureQ[result], 
		MongoFailureMessage[ClientConnect]; 
		Return[$Failed]
	];
	MongoClientObject[clientHandle]
]

ClientConnect[] := ClientConnect["mongodb://localhost:27017"]

(*----------------------------------------------------------------------------*)
PackageExport["ClientDatabaseNames"]

SetUsage[ClientDatabaseNames,
"ClientDatabaseNames[MongoClientObject[$$]] returns a list of databases on the \
connected server. 
"
]

ClientDatabaseNames[MongoClientObject[database_MongoClient]] := Module[
	{result},
	result = getDatabaseNames[ManagedLibraryExpressionID[database]];
	If[LibraryFunctionFailureQ[result], 
		MongoFailureMessage[ClientDatabaseNames]; 
		Return[$Failed]
	];
	result
]