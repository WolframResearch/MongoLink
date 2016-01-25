(*******************************************************************************

Database level functions

*******************************************************************************)

Package["MongoLink`"]

(*** Package Exports ***)
PackageExport["MongoDatabase"]

PackageExport["DatabaseConnect"]
PackageExport["DatabaseCollectionNames"]

(******************************************************************************)

(****** Load Library Functions ******)

databaseHandleCreate = LibraryFunctionLoad[$MongoLinkLib, "WL_DatabaseHandleCreate", 
	{
		Integer,					(* client handle *)
		Integer,					(* database handle *)
		"UTF8String"				(* database name *)

	}, 
	"Void"						
]	

getCollectionNames = LibraryFunctionLoad[$MongoLinkLib, "WL_GetCollectionNames", 
	Automatic, LinkObject					
]	

(******************************************************************************)

DatabaseConnect[client_MongoClient, databaseName_String] := Module[
	{databaseHandle, result},
	databaseHandle = CreateManagedLibraryExpression["MongoDatabase", MongoDatabase];
	result = databaseHandleCreate[
		ManagedLibraryExpressionID@client, 
		ManagedLibraryExpressionID@databaseHandle,
		databaseName
	];
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[DatabaseConnect]; 
		Return@$Failed
	];
	databaseHandle
]

(******************************************************************************)

DatabaseCollectionNames[database_MongoDatabase] := Module[
	{result},
	result = getCollectionNames[
		ManagedLibraryExpressionID@database
	];
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[DatabaseCollectionNames]; 
		Return@$Failed
	];
	result
]