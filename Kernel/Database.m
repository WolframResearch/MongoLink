(*******************************************************************************

Database level functions

*******************************************************************************)

Package["MongoLink`"]
$MongoLinkLib = FindLibrary["MongoLink"];

(*** Package Exports ***)
PackageExport["MongoDatabase"]

PackageExport["DatabaseName"]
PackageExport["DatabaseConnect"]
PackageExport["DatabaseCollectionNames"]
PackageExport["DatabaseCreateCollection"]

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

mongoDatabaseName = LibraryFunctionLoad[$MongoLinkLib, "WL_DatabaseGetName", 
	{
		Integer			(* collection handle *)
	}, 
	"UTF8String"		(* name *)						
]	

databaseCreateCollection = LibraryFunctionLoad[$MongoLinkLib, "WL_DatabaseCreateCollection", 
	{
		Integer,			(* database handle *)
		"UTF8String",		(* collection handle *)
		Integer,			(* bson handle *)
		Integer				(* collection handle *)
	}, 
	"Void"					
]	

(******************************************************************************)

DatabaseName[database_MongoDatabase] := Module[
	{result},
	result = mongoDatabaseName[ManagedLibraryExpressionID@database];
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[CollectionConnect]; 
		Return@$Failed
	];
	result
]

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

(******************************************************************************)

Options[DatabaseCreateCollection] =
{
	"Options" -> <||>
};

DatabaseCreateCollection[database_MongoDatabase, collectionName_, opts:OptionsPattern[]] := Module[
	{result, options, collection},
	
	options = BSONCreate@OptionValue@"Options";
	collection = CreateManagedLibraryExpression["MongoCollection", MongoCollection];
	result = databaseCreateCollection[
		ManagedLibraryExpressionID@database,
		collectionName,
		ManagedLibraryExpressionID@options,
		ManagedLibraryExpressionID@collection
	];
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[DatabaseCreateCollection]; 
		Return@$Failed
	];
	collection
]

