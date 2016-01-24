(*******************************************************************************

Connection: connection API to create handles to client, database + collection

*******************************************************************************)

Package["MongoLink`"]

(*** Package Exports ***)
PackageExport["MongoClient"]
PackageExport["MongoDatabase"]
PackageExport["MongoCollection"]

PackageExport["ClientConnect"]
PackageExport["DatabaseConnect"]
PackageExport["CollectionConnect"]

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

CollectionConnect[client_MongoClient, databaseName_String, collectionName_String] := Module[
	{collectionHandle, result},
	collectionHandle = CreateManagedLibraryExpression["MongoCollection", MongoCollection];
	result = collectionHandleCreate[
		ManagedLibraryExpressionID@client, 
		ManagedLibraryExpressionID@collectionHandle,
		databaseName, 
		collectionName
	];
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[CollectionConnect]; 
		Return@$Failed
	];
	collectionHandle
]