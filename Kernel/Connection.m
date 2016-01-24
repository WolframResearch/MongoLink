(*******************************************************************************

Connection: connection API to create handles to client, database + collection

*******************************************************************************)

Package["MongoLink`"]

(*** Package Exports ***)
PackageExport["MongoClient"]
PackageExport["MongoDatabase"]
PackageExport["MongoCollection"]

PackageExport["GetClient"]
PackageExport["GetDatabase"]
PackageExport["GetCollection"]

(******************************************************************************)

(****** Load Library Functions ******)


clientHandleCreate = LibraryFunctionLoad[$MongoLinkLib, "WL_ClientHandleCreate", 
	{
		Integer,					(* client handle *)
		"UTF8String"				(* connection info *)
	}, 
	"Void"						
]	

databaseHandleCreate = LibraryFunctionLoad[$MongoLinkLib, "WL_DatabaseHandleCreate", 
	{
		Integer,					(* client handle *)
		Integer,					(* database handle *)
		"UTF8String"				(* database name *)

	}, 
	"Void"						
]	

collectionHandleCreate = LibraryFunctionLoad[$MongoLinkLib, "WL_CollectionHandleCreate", 
	{
		Integer,					(* client handle *)
		Integer,					(* collection handle *)
		"UTF8String",				(* database name *)
		"UTF8String"				(* collection name *)

	}, 
	"Void"						
]

(******************************************************************************)

GetClient[uri_String] := Module[
	{clientHandle, result},
	clientHandle = CreateManagedLibraryExpression["MongoClient", MongoClient];
	result = clientHandleCreate[ManagedLibraryExpressionID@clientHandle, uri];
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[GetClient]; 
		Return@$Failed
	];
	clientHandle
]

GetClient[] := GetClient["mongodb://localhost:27017"]

(******************************************************************************)

GetDatabase[client_MongoClient, databaseName_String] := Module[
	{databaseHandle, result},
	databaseHandle = CreateManagedLibraryExpression["MongoDatabase", MongoDatabase];
	result = databaseHandleCreate[
		ManagedLibraryExpressionID@client, 
		ManagedLibraryExpressionID@databaseHandle,
		databaseName
	];
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[GetDatabase]; 
		Return@$Failed
	];
	databaseHandle
]


(******************************************************************************)

GetCollection[client_MongoClient, databaseName_String, collectionName_String] := Module[
	{collectionHandle, result},
	collectionHandle = CreateManagedLibraryExpression["MongoCollection", MongoCollection];
	result = collectionHandleCreate[
		ManagedLibraryExpressionID@client, 
		ManagedLibraryExpressionID@collectionHandle,
		databaseName, 
		collectionName
	];
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[GetCollection]; 
		Return@$Failed
	];
	collectionHandle
]