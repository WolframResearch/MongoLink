(*******************************************************************************

Collection level functions

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]

(*** Package Exports ***)
PackageExport["MongoCollection"]

PackageExport["CollectionConnect"]
PackageExport["CollectionCount"]
PackageExport["CollectionFind"]
PackageExport["CollectionName"]
PackageExport["CollectionInsert"]

(******************************************************************************)

(****** Load Library Functions ******)

clientGetCollection = LibraryFunctionLoad[$MongoLinkLib, "WL_ClientGetCollection", 
	{
		Integer,					(* client handle *)
		Integer,					(* collection handle *)
		"UTF8String",				(* database name *)
		"UTF8String"				(* collection name *)

	}, 
	"Void"						
]

databaseGetCollection = LibraryFunctionLoad[$MongoLinkLib, "WL_DatabaseGetCollection", 
	{
		Integer,					(* database handle *)
		Integer,					(* collection handle *)
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

mongoCollectionCreateBulkOp = LibraryFunctionLoad[$MongoLinkLib, "WL_MongoCollectionCreateBulkOp", 
	{
		Integer,			(* collection handle *)
		Integer,			(* ordered *)
		Integer,			(* write concern *)
		Integer				(* output bulk op handle key *)
	}, 
	"Void"				
]	


(******************************************************************************)

CollectionConnect::noCollection = "No collection by that name exists."

CollectionConnect[database_MongoDatabase, collectionName_String] := Module[
	{collectionHandle, result},
	(* Check that collectionName is in database *)
	If[Not@MemberQ[DatabaseCollectionNames@database, collectionName], 
		Message[CollectionConnect::noCollection];
		Return@$Failed
	];
	
	collectionHandle = CreateManagedLibraryExpression["MongoCollection", MongoCollection];
	result = databaseGetCollection[
		ManagedLibraryExpressionID@database, 
		ManagedLibraryExpressionID@collectionHandle,
		collectionName
	];
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[CollectionConnect]; 
		Return@$Failed
	];
	collectionHandle
]

CollectionConnect[client_MongoClient, databaseName_String, collectionName_String] := Module[
	{collectionHandle, result},
	collectionHandle = CreateManagedLibraryExpression["MongoCollection", MongoCollection];
	result = clientGetCollection[
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

CollectionCount[connection_MongoCollection, query_] := Module[
	{bsonQuery, result},
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

CollectionCount[connection_MongoCollection] := 
	CollectionCount[connection, <||>]

(******************************************************************************)

Options[CollectionFind] =
{
	"Fields" -> <||>,
	"BatchSize" -> Automatic,
	"Skip" -> Automatic,
	"Limit" -> Automatic
};

CollectionFind[collection_MongoCollection, query_, opts:OptionsPattern[]] := Module[
	{queryBSON, fields, batchSize, skip, limit, result, iteratorHandle},
	
	iteratorHandle = CreateManagedLibraryExpression["MongoIterator", MongoIterator];
	
	(* Get default settings. Note Mongo uses 0 as defaults for BatchSize, skip + limit. We'll use their 
		defaults *)
	{fields, batchSize, skip, limit} = 
		OptionValue[{"Fields", "BatchSize", "Skip", "Limit"}]/. Automatic -> 0;
		
	(* Create BSON query + field docs *)
	queryBSON = BSONCreate@query;
	fields = BSONCreate@fields;
	If[FailureQ@query, Return@query];
	If[FailureQ@fields, Return@fields];

	result = mongoCollectionFind[
		ManagedLibraryExpressionID@collection, 
		skip, 
		limit, 
		batchSize,
		ManagedLibraryExpressionID@queryBSON,
		ManagedLibraryExpressionID@fields,
		ManagedLibraryExpressionID@iteratorHandle
	];
	
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[CollectionFind]; 
		Return@$Failed
	];
	(* Return iterator object *)
	NewIterator[
		MongoIterator, 
		{iter = iteratorHandle}, 
		Replace[
			MongoIteratorRead[iter], 
			$Failed :> IteratorExhausted
		]
	]
]

CollectionFind[collection_MongoCollection, opts:OptionsPattern[]] := 
	CollectionFind[collection, <||>, opts]


(******************************************************************************)

Options[CollectionInsert] =
{
	"WriteConcern" -> Automatic,
	"Journal" -> Automatic,
	"Timeout" -> Automatic,
	"Ordered" -> True
};

CollectionInsert[
	collection_MongoCollection, docs_, opts:OptionsPattern[]] := 
Module[
	{
		wc, journal, timeout, ordered, 
		writeConcern, result, bulkHandle
	}
	,
	{wc, journal, timeout, ordered} = 
		OptionValue[{"WriteConcern", "Journal", "Timeout", "Ordered"}];
		
	(* Write concern *)
	writeConcern = WriteConcernCreate[
		"WriteConcern" -> wc, 
		"Journal" -> journal, 
		"Timeout" -> timeout
	];
	If[writeConcern == $Failed, Return@$Failed];

	(* Create bulk op *)
	bulkHandle = CreateManagedLibraryExpression["MongoBulkOperation", MongoBulkOperation];
	result = mongoCollectionCreateBulkOp[
		ManagedLibraryExpressionID@collection,
		Boole@ordered,
		ManagedLibraryExpressionID@writeConcern,
		ManagedLibraryExpressionID@bulkHandle
	];

	(* Handle different types *)
	Which[
		(* Single document case *)
		AssociationQ@docs || StringQ@docs,
			result = BulkOperationInsert[bulkHandle, docs]
		,
		ListQ@docs || (Head@docs === Dataset),
			result = Scan[
				If[BulkOperationInsert[bulkHandle, #] === $Failed, Return@$Failed]&, 
				docs
			];
		,
		True,
			Message[CollectionInsert::unknownType];
			Return@$Failed
	];

	(* Check for errors *)
	If[FailureQ@result, Return@result];

	(* Execute *)
	result = BulkOperationExecute[bulkHandle];
	
	(* Check for errors *)
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[CollectionInsert]; 
		Return@$Failed
	];
	result
]

CollectionInsert::insertError = "Could ";
CollectionInsert::unknownType = "Unknown type for document.";