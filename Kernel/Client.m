(*******************************************************************************

Client level functions

*******************************************************************************)

Package["MongoLink`"]

(*** Package Exports ***)
PackageExport["MongoClient"]

PackageExport["ClientConnect"]
PackageExport["ClientDatabaseNames"]

(******************************************************************************)

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

(******************************************************************************)

ClientConnect[uri_String] := Module[
	{clientHandle, result},
	clientHandle = CreateManagedLibraryExpression["MongoClient", MongoClient];
	result = clientHandleCreate[ManagedLibraryExpressionID@clientHandle, uri];
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[ClientConnect]; 
		Return@$Failed
	];
	clientHandle
]

ClientConnect[] := ClientConnect["mongodb://localhost:27017"]

(******************************************************************************)

ClientDatabaseNames[database_MongoClient] := Module[
	{result},
	result = getDatabaseNames[
		ManagedLibraryExpressionID@database
	];
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[ClientDatabaseNames]; 
		Return@$Failed
	];
	result
]