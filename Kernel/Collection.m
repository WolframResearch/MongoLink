(*******************************************************************************
Collection level-functions

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]

(******************************************************************************)
(****** Load Library Functions ******)

clientGetCollection = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_ClientGetCollection", 
	{
		Integer,		(* client handle *)
		Integer,		(* collection handle *)
		"UTF8String",	(* database name *)
		"UTF8String"	(* collection name *)

	},
	"Void"						
]

databaseGetCollection = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_DatabaseGetCollection", 
	{
		Integer,		(* database handle *)
		Integer,		(* collection handle *)
		"UTF8String"	(* collection name *)

	}, 
	"Void"						
]

mongoCollectionCount = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_MongoCollectionCount", 
	{
		Integer,		(* connection handle *)
		Integer			(* bson handle *)
	}, 
	Integer				(* count *)						
]	

mongoCollectionFind = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_MongoCollectionFind", 
	{
		Integer,		(* connection handle *)
		Integer,		(* query *)
		Integer,		(* opts *)		
		Integer			(* output iterator handle *)
	}, 
	"Void"				
]

mongoCollectionName = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_CollectionGetName", 
	{
		Integer			(* collection handle *)
	}, 
	"UTF8String"		(* name *)						
]	

mongoCollectionCreateBulkOp = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_MongoCollectionCreateBulkOp", 
	{
		Integer,		(* collection handle *)
		Integer,		(* ordered *)
		Integer,		(* write concern *)
		Integer			(* output bulk op handle key *)
	}, 
	"Void"				
]

mongoCollectionUpdate = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_MongoCollectionUpdate", 
	{
		Integer,		(* collection handle *)
		Integer,		(* selector bson handle *)
		Integer,		(* update bson handle *)
		Integer,		(* write concern handle *)
		Integer,		(* upsert *)
		Integer			(* Multi *)
	}, 
	"Void"				
]	

mongoCollectionRemove = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_MongoCollectionRemove", 
	{
		Integer,		(* collection handle *)
		Integer,		(* delete single *)
		Integer,		(* selector bson handle *)
		Integer			(* write concern handle *)
	}, 
	"Void"				
]	

mongoCollectionAggregate = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_MongoCollectionAggregation", 
	{
		Integer,		(* connection handle *)
		Integer,		(* pipeline bson *)
		Integer			(* iterator *)
	
	}, 
	"Void"				
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionObject"]

(* This is a utility function defined in GeneralUtilities, which makes a nicely
formatted display box *)
DefineCustomBoxes[MongoCollectionObject, 
	e:MongoCollectionObject[handle_, dbasename_, collname_, base_] :> Block[{},
	BoxForm`ArrangeSummaryBox[
		MongoCollectionObject, e, None, 
		{
			BoxForm`SummaryItem[{"ID: ", ManagedLibraryExpressionID[handle]}],
			BoxForm`SummaryItem[{"Name: ", collname}],
			BoxForm`SummaryItem[{"Database: ", dbasename}]
		},
		{},
		StandardForm
	]
]];

PackageExport["MongoCollectionName"]
MongoCollectionName[MongoCollectionObject[_, _, _, collname_, _]] := collname;
MongoCollectionName[___] := $Failed

MongoCollectionObject /: RandomSample[coll_MongoCollectionObject, n_] := Module[
	{pipeline}
	,
	pipeline = {<|"$sample" -> <|"size" -> n|>|>};
	MongoCollectionAggregate[coll, pipeline]
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoGetCollection"]

MongoGetCollection[database_MongoDatabaseObject, collectionName_String] := Catch @ Module[
	{collectionHandle, result},
	(* Check that collectionName is in database *)
 
	collectionHandle = CreateManagedLibraryExpression["MongoCollection", MongoCollection];
	result = safeLibraryInvoke[databaseGetCollection,
		ManagedLibraryExpressionID @ MongoDatabaseHandle[database], 
		ManagedLibraryExpressionID[collectionHandle],
		collectionName
	];
	MongoCollectionObject[collectionHandle, MongoDatabaseName[database], collectionName, database]
]

MongoGetCollection[client_MongoClientObject, databaseName_String, collectionName_String] := Catch @ Module[
	{collectionHandle, result},
	collectionHandle = CreateManagedLibraryExpression["MongoCollection", MongoCollection];
	result = safeLibraryInvoke[clientGetCollection,
		ManagedLibraryExpressionID[client], 
		ManagedLibraryExpressionID[collectionHandle],
		databaseName, 
		collectionName
	];
	MongoCollectionObject[collectionHandle, databaseName, collectionName, client]
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionName"]

MongoCollectionName[MongoCollectionObject[handle_, ___]] := Catch @ 
	safeLibraryInvoke[mongoCollectionName, ManagedLibraryExpressionID[handle]];

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionCount"]

MongoCollectionCount[MongoCollectionObject[handle_, ___], query_Association] := Catch @ Module[
	{bsonQuery},
	bsonQuery = BSONCreate[query];
	If[FailureQ[bsonQuery], Return[$Failed]];
	safeLibraryInvoke[mongoCollectionCount,
		ManagedLibraryExpressionID[handle], 
		ManagedLibraryExpressionID[First @ bsonQuery]
	]
]

MongoCollectionCount[collection_MongoCollectionObject] := 
	MongoCollectionCount[collection, <||>]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionFind"]

Options[MongoCollectionFind] = {
};

MongoCollectionFind[collection_MongoCollectionObject, query_, opts:OptionsPattern[]] := Catch @ Module[
	{queryBSON, optsBSON, iteratorHandle, optsAssoc},
	
	iteratorHandle = CreateManagedLibraryExpression["MongoIterator", MongoIterator];
	(* Get default settings. Note Mongo uses 0 as defaults for BatchSize, skip + limit. We'll use their 
		defaults *)
		
	(* Create BSON query + field docs *)
	queryBSON = BSONCreate[query];
	optsAssoc = <||>; (* add this in future! *)
	optsBSON = BSONCreate[optsAssoc];
	
	If[FailureQ[query], Return[query]];
	If[FailureQ[optsBSON], Return[optsBSON]];

	safeLibraryInvoke[mongoCollectionFind,
		ManagedLibraryExpressionID[First @ collection], 
		ManagedLibraryExpressionID[First @ queryBSON],
		ManagedLibraryExpressionID[First @ optsBSON],
		ManagedLibraryExpressionID[iteratorHandle]
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

MongoCollectionFind[collection_MongoCollectionObject, opts:OptionsPattern[]] := 
	MongoCollectionFind[collection, <||>, opts]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionInsert"]

Options[MongoCollectionInsert] = {
	"WriteConcern" -> 1,
	"Journal" -> True,
	"Timeout" -> None,
	"Ordered" -> True
};

MongoCollectionInsert[
	collection_MongoCollectionObject, docs_List, opts:OptionsPattern[]] := Catch @ Module[
	{
		wc, journal, timeout, ordered, 
		writeConcern, bulkHandle
	}
	,
	{wc, journal, timeout, ordered} = 
		OptionValue[{"WriteConcern", "Journal", "Timeout", "Ordered"}];
	(* Write concern *)
	writeConcern = WriteConcernCreate[wc,
		"Journal" -> journal, 
		"Timeout" -> timeout
	];
	
	(* Create bulk op *)
	bulkHandle = CreateManagedLibraryExpression["MongoBulkOperation", MongoBulkOperation];
	safeLibraryInvoke[mongoCollectionCreateBulkOp,
		ManagedLibraryExpressionID[First @ collection],
		Boole[ordered],
		ManagedLibraryExpressionID[writeConcern],
		ManagedLibraryExpressionID[bulkHandle]
	];
	(* Handle different types *)
	Which[
		(* Single document case *)
		AssociationQ[docs] || StringQ[docs],
			BulkOperationInsert[bulkHandle, docs]
		,
		ListQ[docs] || (Head[docs] === Dataset),
			Scan[
				BulkOperationInsert[bulkHandle, #]&,
				docs
			];
		,
		True,
			Message[CollectionInsert::unknownType];
			Return[$Failed]
	];

	(* Execute *)
	BulkOperationExecute[bulkHandle]
]

MongoCollectionInsert[coll_MongoCollectionObject, docs_Dataset, opts:OptionsPattern[]] := 
	MongoCollectionInsert[coll, Normal[docs], opts]

CollectionInsert::unknownType = "Unknown type for document.";

(*----------------------------------------------------------------------------*)

PackageExport["MongoCollectionUpdate"]

SetUsage[MongoCollectionUpdate, "
MongoCollectionUpdate[MongoCollection[$$], query$, update$] update a single document in the \
collection MongoCollection[$$] which satisfies the query$ association. The update$ document \
will replace the contents of the matched document (exept for _id field). To update only \
individual fields, use the $set operator. If no document satisfies query$, nothing is done, unless \
the Option \"Upsert\" is set to True. To update all documents satisfying the query$, set the option \
\"MultiDocumentUpdate\" to True."
]

Options[MongoCollectionUpdate] = {
	"WriteConcern" -> Automatic,
	"Journal" -> Automatic,
	"Timeout" -> Automatic,
	"Upsert" -> False,
	"MultiDocumentUpdate" -> False
};

MongoCollectionUpdate[collection_MongoCollection, selector_, updaterDoc_, OptionsPattern[]] := Scope[
	UnpackOptions[writeConcern, journal, timeout, upsert, multiDocumentUpdate];
		
	(* Write concern *)
	writeConcern = MongoWriteConcernCreate[
		"WriteConcern" -> writeConcern, 
		"Journal" -> journal, 
		"Timeout" -> timeout
	];
	If[FailureQ@writeConcern, Return@writeConcern];

	(* Create BSON query + update docs *)
	queryBSON = BSONCreate@selector;
	updaterDocBSON = BSONCreate@updaterDoc;
	(*If[FailureQ@query, Return@queryBSON];*)
	If[FailureQ@updaterDocumentBSON, Return@updaterDocumentBSON];


	(* Execute *)
	result = mongoCollectionUpdate[
		ManagedLibraryExpressionID@collection,
		ManagedLibraryExpressionID@queryBSON,
		ManagedLibraryExpressionID@updaterDocBSON,
		ManagedLibraryExpressionID@writeConcern,
		Boole@upsert,
		Boole@multiDocumentUpdate
	];
	
	(* Check for errors *)
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[MongoCollectionUpdate]; 
		Return@$Failed
	];
	result
]
	
(*----------------------------------------------------------------------------*)

PackageExport["CollectionRemove"]

SetUsage[CollectionRemove, "
CollectionRemove[MongoCollection[$$], query$] removes a single document from MongoCollection[$$] \
that satisfies the query $query. To remove all documents, set the Option \"MultiDocumentUpdate\" to \ 
True."
]


Options[CollectionRemove] =
{
	"WriteConcern" -> Automatic,
	"Journal" -> Automatic,
	"Timeout" -> Automatic,
	"MultiDocumentUpdate" -> False
};

CollectionRemove[collection_MongoCollection, selector_, OptionsPattern[]] := Scope[
	UnpackOptions[writeConcern, journal, timeout, multiDocumentUpdate];
		
	(* Write concern *)
	writeConcern = MongoWriteConcernCreate[
		"WriteConcern" -> writeConcern, 
		"Journal" -> journal, 
		"Timeout" -> timeout
	];
	If[FailureQ@writeConcern, Return@writeConcern];

	(* Create BSON query *)
	queryBSON = BSONCreate@selector;
	If[FailureQ@query, Return@queryBSON];
	
	(* Execute *)
	result = mongoCollectionRemove[
		ManagedLibraryExpressionID@collection,
		Boole@multiDocumentUpdate,
		ManagedLibraryExpressionID@queryBSON,
		ManagedLibraryExpressionID@writeConcern
	];
	(* Check for errors *)
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[CollectionRemove]; 
		Return@$Failed
	];
	result
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionAggregate"]

MongoCollectionAggregate[collection_MongoCollectionObject, pipeline_] := Module[
	{iteratorHandle, pipelineBSON},
	iteratorHandle = CreateManagedLibraryExpression["MongoIterator", MongoIterator];
	pipelineBSON = BSONCreate[<|"pipeline" -> pipeline|>];
	If[FailureQ[pipelineBSON], Return[pipelineBSON]];

	safeLibraryInvoke[mongoCollectionAggregate,
		ManagedLibraryExpressionID[First @ collection], 
		ManagedLibraryExpressionID[First @ pipelineBSON], 
		ManagedLibraryExpressionID[iteratorHandle]
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

(*----------------------------------------------------------------------------*)
PackageExport["MongoReferenceGet"]

SetUsage[MongoReferenceGet, "
MongoReferenceGet[MongoDatabase[$$], MongoReference[$$]] returns the corresponding document \
referenced by MongoReference[$$].
"
]

MongoReferenceGet[database_MongoDatabase, mong_MongoReference] := Scope[
	coll = MongoGetCollection[database, First@mong];
	docIter = CollectionFind[coll, <|"_id" -> Last@mong|>];
	If[FailureQ@doc, Return@$Failed];
	Read@docIter
]

