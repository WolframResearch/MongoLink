(*******************************************************************************
Collection level-functions

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]

(*----------------------------------------------------------------------------*)
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
MongoCollectionName[MongoCollectionObject[__, collname_, _]] := collname;
MongoCollectionName[___] := $Failed

MongoCollectionObject /: RandomSample[coll_MongoCollectionObject, n_] := Module[
	{pipeline}
	,
	pipeline = {<|"$sample" -> <|"size" -> n|>|>};
	MongoCollectionAggregate[coll, pipeline]
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoGetCollection"]

MongoGetCollection[database_MongoDatabaseObject, collectionName_String] := 
CatchFailureAsMessage @ Module[
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

MongoGetCollection[client_MongoClientObject, 
	databaseName_String, collectionName_String] := CatchFailureAsMessage @ Module[
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

MongoCollectionName[MongoCollectionObject[handle_, ___]] := CatchFailureAsMessage @ 
	safeLibraryInvoke[mongoCollectionName, ManagedLibraryExpressionID[handle]];

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionCount"]

MongoCollectionCount[MongoCollectionObject[handle_, ___], query_Association] := 
CatchFailureAsMessage @ Module[
	{bsonQuery},
	bsonQuery = iBSONCreate[query];
	safeLibraryInvoke[mongoCollectionCount,
		ManagedLibraryExpressionID[handle], 
		ManagedLibraryExpressionID[First @ bsonQuery]
	]
]

MongoCollectionCount[collection_MongoCollectionObject] := 
	MongoCollectionCount[collection, <||>]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionFind"]

(* don't support all opts yet. See 
	http://mongoc.org/libmongoc/current/mongoc_collection_find_with_opts.html
	for full opts list
*)

Options[MongoCollectionFind] = {
	"Limit" -> None
};

MongoCollectionFind::invLimit = 
	"The Option \"Limit\" must have value None or a positive integer, but `` was given.";

MongoCollectionFind[collection_MongoCollectionObject, 
	query_, opts:OptionsPattern[]] := CatchFailureAsMessage @ Module[
	{
		queryBSON, optsBSON, iteratorHandle, optsAssoc
	},
	(** parse opts **)
	optsAssoc = <|
		"limit" -> Replace[OptionValue["Limit"], None -> 0]
	|>; 
	If[!IntegerQ[optsAssoc["limit"]] || Negative[optsAssoc["limit"]],
		Message[MongoCollectionFind::invLimit, optsAssoc["limit"]];
		Return[$Failed]
	];
	
	(* Create BSON query + field docs *)
	queryBSON = iBSONCreate[query];
	optsBSON = iBSONCreate[optsAssoc];

	iteratorHandle = CreateManagedLibraryExpression["MongoIterator", MongoIterator];
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
	"WriteConcern" -> Automatic,
	"Ordered" -> True
};

MongoCollectionInsert::ordered = 
	"The option \"Ordered\" was ``, but must be either True or False.";
MongoCollectionInsert::writeconcern = 
	"The option \"WriteConcern\" was ``, but must be a MongoWriteConcernObject or Automatic.";

MongoCollectionInsert[coll_MongoCollectionObject, doc_, opts:OptionsPattern[]] := 
CatchFailureAsMessage @ Module[
	{wc, ordered},
	(** parse options **)
	{wc, ordered} = OptionValue[{"WriteConcern", "Ordered"}];
	If[!BooleanQ[ordered],
		ThrowFailure[MongoCollectionInsert::ordered]
	];
	If[Not[(Head[wc] === MongoWriteConcernObject) || (wc === Automatic)],
		ThrowFailure[MongoCollectionInsert::invwriteconcern, wc];
	];
	(* use 0 to encode NULL on C side, which uses defaults *)
	wc = If[wc === Automatic, 0, ManagedLibraryExpressionID[First @ wc]];
	iMongoCollectionInsert[coll, doc, wc, ordered]
]

iMongoCollectionInsert[
	collection_MongoCollectionObject, docs:{__BSONObject}, wc_Integer, ordered_] := Module[
	{bulkHandle}
	,
	(* Create bulk op *)
	bulkHandle = CreateManagedLibraryExpression["MongoBulkOperation", MongoBulkOperation];
	safeLibraryInvoke[mongoCollectionCreateBulkOp,
		ManagedLibraryExpressionID[First @ collection],
		Boole[ordered],
		wc,
		ManagedLibraryExpressionID[bulkHandle]
	];
	Scan[
		bulkOperationInsert[bulkHandle, #]&,
		docs
	];
	(* Execute *)
	bulkOperationExecute[bulkHandle]
]

iMongoCollectionInsert[coll_MongoCollectionObject, doc_BSONObject, wc_, ordered_] := 
	iMongoCollectionInsert[coll, {doc}, wc, ordered]

iMongoCollectionInsert[coll_MongoCollectionObject, doc_Association|doc_String, wc_, ordered_] := 
	iMongoCollectionInsert[coll, {iBSONCreate[doc]}, wc, ordered]

iMongoCollectionInsert[coll_MongoCollectionObject, doc_List, wc_, ordered_] := 
	iMongoCollectionInsert[coll, iBSONCreate /@ doc, wc, ordered]

iMongoCollectionInsert::invtype =
	"Document to be inserted must be an Association, String or BSONObject, or a list of these.";
iMongoCollectionInsert[coll_MongoCollectionObject, doc_, wc_, ordered_] := 
	ThrowFailure[iMongoCollectionInsert::invtype];

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionUpdate"]

Options[MongoCollectionUpdate] = {
	"WriteConcern" -> Automatic,
	"Upsert" -> False,
	"MultiDocumentUpdate" -> False
};

MongoCollectionUpdate::invwriteconcern = 
	"The Option \"WriteConcern\" must be a MongoWriteConcernObject or Automatic, but `` was given.";
MongoCollectionUpdate::invupsert = 
	"The Option \"Upsert\" must be either True or False, but `` was given."
MongoCollectionUpdate::invmulti = 
	"The Option \"MultiDocumentUpdate\" must be either True or False, but `` was given."

MongoCollectionUpdate[MongoCollectionObject[handle_, ___], 
	selector_, updaterDoc_, OptionsPattern[]] := CatchFailureAsMessage @ Module[
	{queryBSON, updaterDocBSON, wc, upsert, multiDocumentUpdate},
	(** parse options **)
	{wc, upsert, multiDocumentUpdate}  = 
		OptionValue[{"WriteConcern", "Upsert", "MultiDocumentUpdate"}];	

	If[Not[(Head[wc] === MongoWriteConcernObject) || (wc === Automatic)],
		ThrowFailure[MongoCollectionUpdate::invwriteconcern, wc];
	];
	(* use 0 to encode NULL on C side, which uses defaults *)
	wc = If[wc === Automatic, 0, ManagedLibraryExpressionID[First @ wc]];
	
	If[!BooleanQ[upsert],
		ThrowFailure[MongoCollectionUpdate::invupsert, upsert];
	];
	If[!BooleanQ[multiDocumentUpdate],
		ThrowFailure[MongoCollectionUpdate::invmulti, multiDocumentUpdate];
	];
	(* Create BSON query + update docs *)
	queryBSON = iBSONCreate[selector];
	updaterDocBSON = iBSONCreate[updaterDoc];
	(* Execute *)
	safeLibraryInvoke[mongoCollectionUpdate,
		ManagedLibraryExpressionID[handle],
		ManagedLibraryExpressionID[First @ queryBSON],
		ManagedLibraryExpressionID[First @ updaterDocBSON],
		wc,
		Boole[upsert],
		Boole[multiDocumentUpdate]
	]
]	

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionRemove"]

Options[MongoCollectionRemove] =
{
	"WriteConcern" -> Automatic,
	"MultiDocumentUpdate" -> False
};

MongoCollectionRemove::invwriteconcern = 
	"The Option \"WriteConcern\" must be a MongoWriteConcernObject or Automatic, but `` was given.";
MongoCollectionRemove::invmulti = 
	"The Option \"MultiDocumentUpdate\" must be either True or False, but `` was given."

MongoCollectionRemove[MongoCollectionObject[handle_, ___], 
	selector_, OptionsPattern[]] := CatchFailureAsMessage @ Module[
	{queryBSON, multiDocumentUpdate, wc},
	(** parse options **)
	{wc, multiDocumentUpdate}  = 
		OptionValue[{"WriteConcern", "MultiDocumentUpdate"}];	
		
	If[Not[(Head[wc] === MongoWriteConcernObject) || (wc === Automatic)],
		ThrowFailure[MongoCollectionRemove::invwriteconcern, wc];
	];
	(* use 0 to encode NULL on C side, which uses defaults *)
	wc = If[wc === Automatic, 0, ManagedLibraryExpressionID[First @ wc]];
	If[!BooleanQ[multiDocumentUpdate],
		ThrowFailure[MongoCollectionRemove::invmulti, multiDocumentUpdate];
	];
	
	(* Create BSON query *)
	queryBSON = iBSONCreate[selector];
	multiDocumentUpdate = OptionValue["MultiDocumentUpdate"];
	(* Execute *)
	safeLibraryInvoke[mongoCollectionRemove,
		ManagedLibraryExpressionID[handle],
		Boole[multiDocumentUpdate],
		ManagedLibraryExpressionID[First @ queryBSON],
		wc
	]
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionAggregate"]

MongoCollectionAggregate[collection_MongoCollectionObject, pipeline_] := Module[
	{iteratorHandle, pipelineBSON},
	iteratorHandle = CreateManagedLibraryExpression["MongoIterator", MongoIterator];
	pipelineBSON = iBSONCreate[<|"pipeline" -> pipeline|>];

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

MongoReferenceGet[database_MongoDatabaseObject, mong_MongoDBReference] := 
CatchFailureAsMessage @ Module[
	{coll, docIter},
	coll = MongoGetCollection[database, First@mong];
	docIter = MongoCollectionFind[coll, <|"_id" -> <|"$oid" -> Last[mong]|>|>];
	If[FailureQ[docIter], Return[$Failed]];
	Read[docIter]
]

