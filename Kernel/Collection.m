(*******************************************************************************

Collection level functions

*******************************************************************************)

Package["MongoLink`"]
$MongoLinkLib = FindLibrary["MongoLink"];


(*** Package Exports ***)
PackageExport["MongoCollection"]

PackageExport["CollectionConnect"]
PackageExport["CollectionCount"]
PackageExport["CollectionFind"]
PackageExport["CollectionName"]

(******************************************************************************)

(****** Load Library Functions ******)

collectionHandleCreate = LibraryFunctionLoad[$MongoLinkLib, "WL_CollectionHandleCreate", 
	{
		Integer,					(* client handle *)
		Integer,					(* collection handle *)
		"UTF8String",				(* database name *)
		"UTF8String"				(* collection name *)

	}, 
	"Void"						
]

mongoCollectionCount = LibraryFunctionLoad[$MongoLinkLib, "WL_MongoCollectionCount", 
	{
		Integer,			(* connection handle *)
		Integer				(* bson handle *)
	}, 
	Integer					(* count *)						
]	

mongoCollectionFind = LibraryFunctionLoad[$MongoLinkLib, "WL_MongoCollectionFind", 
	{
		Integer,			(* connection handle *)
		Integer,				(* skip *)
		Integer,				(* limit *)
		Integer,				(* batch_size *)
		Integer,				(* query bson handle *)
		Integer,				(* fields bson handle *)		
		Integer					(* output iterator handle *)
	}, 
	"Void"				
]	

mongoCollectionName = LibraryFunctionLoad[$MongoLinkLib, "WL_CollectionGetName", 
	{
		Integer			(* collection handle *)
	}, 
	"UTF8String"		(* name *)						
]	

(******************************************************************************)

CollectionName[collection_MongoCollection] := Module[
	{result},
	result = mongoCollectionName[ManagedLibraryExpressionID@collection];
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[CollectionConnect]; 
		Return@$Failed
	];
	result
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

(******************************************************************************)

Options[CollectionCount] =
{
	"Query" -> <||>
};

CollectionCount[connection_MongoCollection, opts:OptionsPattern[]] := Module[
	{query, bsonQuery, result},
	query  = OptionValue@"Query";
	bsonQuery = BSONCreate@query;
	
	result = mongoCollectionCount[
		ManagedLibraryExpressionID@connection, 
		ManagedLibraryExpressionID@bsonQuery
	];
	
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[ConnectionCount]; 
		Return@$Failed
	];
	result
]

(******************************************************************************)

Options[CollectionFind] =
{
	"Query" -> <||>,
	"Fields" -> <||>,
	"BatchSize" -> Automatic,
	"Skip" -> Automatic,
	"Limit" -> Automatic
};

CollectionFind[collection_MongoCollection, opts:OptionsPattern[]] := Module[
	{query, fields, batchSize, skip, limit, result, iteratorHandle},
	
	iteratorHandle = CreateManagedLibraryExpression["MongoIterator", MongoIterator];
	
	(* Get default settings. Note Mongo uses 0 as defaults for BatchSize, skip + limit. We'll use their 
		defaults *)
	{query, fields, batchSize, skip, limit} = 
		OptionValue[{"Query", "Fields", "BatchSize", "Skip", "Limit"}]/. Automatic -> 0;
	
	(* Create BSON query + field docs *)
	query = BSONCreate@query;
	fields = BSONCreate@fields;
	If[(query === $Failed) || (fields === $Failed), Return@$Failed];
	
	result = mongoCollectionFind[
		ManagedLibraryExpressionID@collection, 
		skip, 
		limit, 
		batchSize,
		ManagedLibraryExpressionID@query,
		ManagedLibraryExpressionID@fields,
		ManagedLibraryExpressionID@iteratorHandle
	];
	
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[CollectionFind]; 
		Return@$Failed
	];
	(* Return iterator object *)
	iteratorHandle	
]


(*	If[Head[iteratorHandle] =!= MongoIterator, Return[$Failed]];
	NewIterator[
		MongoIterator, 
		{iter = iteratorHandle}, 
		Replace[iter[], $Failed :> IteratorExhausted]*)

