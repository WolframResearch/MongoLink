(*******************************************************************************
Collection level-functions

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]

PackageScope["collectionMLE"] (* collection ManagedLibraryExpression *)

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
		Integer			(* output cursor handle *)
	}, 
	"Void"				
]

mongoCollectionInsert = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_mongoc_collection_insert", 
	{
		Integer,		(* collection handle *)
		Integer,		(* wc handle *)	
		True|False,		(* ordered *)
		{Integer, 1, "Constant"}	(* bson doc list handles *)
	}, 
	True|False				
]

mongoCollectionName = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_CollectionGetName", 
	{
		Integer			(* collection handle *)
	}, 
	"UTF8String"		(* name *)						
]	

mongoCollectionUpdate = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_MongoCollectionUpdate", 
	{
		Integer,		(* collection handle *)
		Integer,		(* write concern handle *)
		Integer,		(* selector bson handle *)
		Integer,		(* update bson handle *)
		Integer,		(* opts bson handle *)
		Integer,		(* reply bson handle *)
		True|False		(* many or one *)
	}, 
	True|False			(* aknowledged *)			
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
		Integer,		(* collection handle *)
		Integer,		(* pipeline bson *)
		Integer			(* cursor *)
	
	}, 
	"Void"				
]

mongoCollectionStats = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_MongoCollectionStats", 
	{
		Integer,		(* collection handle *)
		Integer,		(* opts bson *)
		Integer			(* reply bson *)
	
	}, 
	"Void"				
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollection"]

(* This is a utility function defined in GeneralUtilities, which makes a nicely
formatted display box *)
DefineCustomBoxes[MongoCollection, 
	e:MongoCollection[collMLE_, dbasename_, collname_, client_] :> Block[{},
	BoxForm`ArrangeSummaryBox[
		MongoCollection, e, None,
		{
			BoxForm`SummaryItem[{"ID: ", getMLEID[collMLE]}],
			BoxForm`SummaryItem[{"Name: ", collname}],
			BoxForm`SummaryItem[{"Database: ", dbasename}]
		},
		{},
		StandardForm
	]
]];

(* internal MongoCollection object accessors  *)
getClient[MongoCollection[__, client_]] := client
getMLE[MongoCollection[collMLE_, __]] := collMLE;

getMLEID[MongoCollection[collMLE_, __]] := ManagedLibraryExpressionID[collMLE];

(* Overload RandomSample for collections *)
MongoCollection /: RandomSample[coll_MongoCollection, n_] := Module[
	{pipeline}
	,
	pipeline = {<|"$sample" -> <|"size" -> n|>|>};
	MongoCollectionAggregate[coll, pipeline]
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionName"]

MongoCollectionName[MongoCollection[__, collname_, _]] := collname;
MongoCollectionName[___] := $Failed

(*----------------------------------------------------------------------------*)
PackageExport["MongoGetCollection"]

(* MongoGetCollection can either operate on Client or Database objects, so 
	its name is not MongoDatabaseGetCollection etc.
*)

MongoGetCollection[db_MongoDatabase, collectionName_String] := 
CatchFailureAsMessage @ Module[
	{collHandle, result},
	(* Check that collectionName is in database *)
	collHandle = CreateManagedLibraryExpression["Collection", collectionMLE];
	result = safeLibraryInvoke[databaseGetCollection,
		getMLEID[db], 
		getMLEID[collHandle],
		collectionName
	];
	System`Private`SetNoEntry @ MongoCollection[
		collHandle, 
		MongoDatabaseName[db], 
		collectionName, 
		getClient[db]
	]
]

MongoGetCollection[client_MongoClient, 
	databaseName_String, collectionName_String] := CatchFailureAsMessage @ Module[
	{collHandle, result},
	collHandle = CreateManagedLibraryExpression["Collection", collectionMLE];
	result = safeLibraryInvoke[clientGetCollection,
		getMLEID[client], 
		getMLEID[collHandle],
		databaseName, 
		collectionName
	];
	System`Private`SetNoEntry @ MongoCollection[
		collHandle, 
		databaseName, 
		collectionName, 
		client
	]
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionName"]

MongoCollectionName[coll_MongoCollection] := CatchFailureAsMessage @ 
	safeLibraryInvoke[mongoCollectionName, getMLEID[coll]];

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionCount"]

MongoCollectionCount[coll_MongoCollection, query_Association] := 
CatchFailureAsMessage @ Module[
	{bsonQuery},
	bsonQuery = iToBSON[query];
	safeLibraryInvoke[mongoCollectionCount,
		getMLEID[coll], 
		getMLEID[bsonQuery]
	]
]

MongoCollectionCount[coll_MongoCollection] := 
	MongoCollectionCount[coll, <||>]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionFind"]

(* don't support all opts yet. See 
	http://mongoc.org/libmongoc/current/mongoc_collection_find_with_opts.html
	for full opts list
*)

Options[MongoCollectionFind] = {
	"Limit" -> None,
	BatchSize -> Automatic
};

MongoCollectionFind::invLimit = 
	"The Option \"Limit\" must have value None or a non-negative integer, but `` was given.";
MongoCollectionFind::invBatchSize = 
	"The Option BatchSize must have value Automatic or a non-negative integer, but `` was given.";

MongoCollectionFind[coll_MongoCollection, 
	query_Association, projection_Association, opts:OptionsPattern[]] := 
CatchFailureAsMessage @ Module[
	{
		queryBSON, optsBSON, cursorHandle, optsAssoc,
		batchSize = OptionValue[BatchSize]
	},
	(** parse opts **)
	optsAssoc = <|
		"limit" -> Replace[OptionValue["Limit"], None -> 0],
		"projection" -> projection
	|>;
	If[!IntegerQ[optsAssoc["limit"]] || Negative[optsAssoc["limit"]],
		ThrowFailure[MongoCollectionFind::invLimit, optsAssoc["limit"]]
	];

	If[batchSize =!= Automatic, 
		optsAssoc["batchSize"] = batchSize;
		If[!IntegerQ[batchSize] || Negative[batchSize],
			ThrowFailure[MongoCollectionFind::invBatchSize, batchSize]
		]
	];

	(* Create BSON query + field docs *)
	queryBSON = iToBSON[query];
	optsBSON = iToBSON[optsAssoc];

	cursorHandle = CreateManagedLibraryExpression["Cursor", cursorMLE];
	safeLibraryInvoke[mongoCollectionFind,
		getMLEID[coll],
		getMLEID[queryBSON],
		getMLEID[optsBSON],
		getMLEID[cursorHandle]
	];
	System`Private`SetNoEntry @ 
		MongoCursor[cursorHandle, getClient[coll]] 
]

MongoCollectionFind[coll_MongoCollection, opts:OptionsPattern[]] := 
	MongoCollectionFind[coll, <||>, <||>, opts]

MongoCollectionFind[coll_MongoCollection, query_, opts:OptionsPattern[]] := 
	MongoCollectionFind[coll, query, <||>, opts]

(*----------------------------------------------------------------------------*)
(* Insertion: Note that the Mongo spec supports three different insert ops:
	insert, insertOne, insertMany. PyMongo deprecated insert, and recommends 
	only insertOne and insertMany. We will follow the API of insertMany,
	and call it MongoCollectionInsert.
*)

PackageExport["MongoCollectionInsert"]

General::mongoordered = 
	"The option \"Ordered\" was ``, but must be either True or False.";
General::mongowriteconcern = 
	"The option \"WriteConcern\" was ``, but must be a MongoWriteConcern or Automatic.";

Options[MongoCollectionInsert] = {
	"WriteConcern" -> Automatic,
	"Ordered" -> True
};

MongoCollectionInsert[coll_MongoCollection, doc_, opts:OptionsPattern[]] := 
CatchFailureAsMessage @ Module[
	{wc, ordered},
	(** parse options **)
	{wc, ordered} = OptionValue[{"WriteConcern", "Ordered"}];
	If[!BooleanQ[ordered],
		ThrowFailure[MongoCollectionInsert::ordered]
	];
	If[Not[(Head[wc] === MongoWriteConcern) || (wc === Automatic)],
		ThrowFailure[MongoCollectionInsert::invwriteconcern, wc];
	];
	(* if wc is Automatic, to encode NULL on C side, which uses defaults *)
	wc = Replace[wc, Automatic :> CreateManagedLibraryExpression["WriteConcern", writeConcernMLE]];
	iMongoCollectionInsert[coll, doc, wc, ordered]
]

iMongoCollectionInsert[
	collection_MongoCollection, docs:{__BSONObject}, wc_, ordered_] := Module[
	{res, keyNames},
	res = safeLibraryInvoke[mongoCollectionInsert,
		getMLEID[collection],
		getMLEID[wc],
		ordered,
		getMLEID /@ docs
	];
	(* mongoCollectionInsert inserts a _id value if no _id exists in doc. 
		Need to return a list of _id names to be consistent with
		https://docs.mongodb.com/manual/reference/method/db.collection.insertMany/
	*)
	keyNames = bsonLookup[#, "_id"]& /@ docs;
	Dataset @ <|"Acknowledged" -> res, "InsertedIDs" -> keyNames, "InsertedCount" -> Length[keyNames]|>
]

iMongoCollectionInsert[coll_MongoCollection, doc_BSONObject, wc_, ordered_] := 
	iMongoCollectionInsert[coll, {doc}, wc, ordered]

iMongoCollectionInsert[coll_MongoCollection, doc_Association|doc_String, wc_, ordered_] := 
	iMongoCollectionInsert[coll, {iToBSON[doc]}, wc, ordered]

iMongoCollectionInsert[coll_MongoCollection, doc_List, wc_, ordered_] := 
	iMongoCollectionInsert[coll, iToBSON /@ doc, wc, ordered]

iMongoCollectionInsert::invtype =
	"Document to be inserted must be an Association, String or BSONObject, or a list of these.";
iMongoCollectionInsert[coll_MongoCollection, doc_, wc_, ordered_] := 
	ThrowFailure[iMongoCollectionInsert::invtype];

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionUpdate"]

Options[MongoCollectionUpdate] = {
	"WriteConcern" -> Automatic,
	"Upsert" -> False,
	"MultiDocumentUpdate" -> False
};

MongoCollectionUpdate::invwriteconcern = 
	"The Option \"WriteConcern\" must be a MongoWriteConcern or Automatic, but `` was given.";
MongoCollectionUpdate::invupsert = 
	"The Option \"Upsert\" must be either True or False, but `` was given."
MongoCollectionUpdate::invmulti = 
	"The Option \"MultiDocumentUpdate\" must be either True or False, but `` was given."

MongoCollectionUpdate[MongoCollection[handle_, ___], 
	selector_, updaterDoc_, OptionsPattern[]] := CatchFailureAsMessage @ Module[
	{queryBSON, updaterDocBSON, wc, upsert, multiDocumentUpdate},
	(** parse options **)
	{wc, upsert, multiDocumentUpdate}  = 
		OptionValue[{"WriteConcern", "Upsert", "MultiDocumentUpdate"}];	

	If[Not[(Head[wc] === MongoWriteConcern) || (wc === Automatic)],
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
	queryBSON = iToBSON[selector];
	updaterDocBSON = iToBSON[updaterDoc];
	(* Execute *)
	safeLibraryInvoke[mongoCollectionUpdate,
		getMLEID[handle],
		getMLEID[queryBSON],
		getMLEID[updaterDocBSON],
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
	"The Option \"WriteConcern\" must be a MongoWriteConcern or Automatic, but `` was given.";
MongoCollectionRemove::invmulti = 
	"The Option \"MultiDocumentUpdate\" must be either True or False, but `` was given."

MongoCollectionRemove[MongoCollection[handle_, ___], 
	selector_, OptionsPattern[]] := CatchFailureAsMessage @ Module[
	{queryBSON, multiDocumentUpdate, wc},
	(** parse options **)
	{wc, multiDocumentUpdate}  = 
		OptionValue[{"WriteConcern", "MultiDocumentUpdate"}];	
		
	If[Not[(Head[wc] === MongoWriteConcern) || (wc === Automatic)],
		ThrowFailure[MongoCollectionRemove::invwriteconcern, wc];
	];
	(* use 0 to encode NULL on C side, which uses defaults *)
	wc = If[wc === Automatic, 0, ManagedLibraryExpressionID[First @ wc]];
	If[!BooleanQ[multiDocumentUpdate],
		ThrowFailure[MongoCollectionRemove::invmulti, multiDocumentUpdate];
	];
	(* Create BSON query *)
	queryBSON = iToBSON[selector];
	multiDocumentUpdate = OptionValue["MultiDocumentUpdate"];
	(* Execute *)
	safeLibraryInvoke[mongoCollectionRemove,
		getMLEID[handle],
		Boole[multiDocumentUpdate],
		getMLEID[queryBSON],
		wc
	]
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionAggregate"]

MongoCollectionAggregate[coll_MongoCollection, pipeline_] := Module[
	{cursorHandle, pipelineBSON},
	cursorHandle = CreateManagedLibraryExpression["Cursor", cursorMLE];
	pipelineBSON = iToBSON[<|"pipeline" -> pipeline|>];

	safeLibraryInvoke[mongoCollectionAggregate,
		getMLEID[coll], 
		getMLEID[pipelineBSON], 
		getMLEID[cursorHandle]
	];

	System`Private`SetNoEntry @ MongoCursor[
		cursorHandle, getClient[coll]
	]
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionStats"]

MongoCollectionStats[coll_MongoCollection] := CatchFailureAsMessage @ Module[
	{optsBSON, replyBSON},
	(* don't support opts yet *)
	optsBSON = ToBSON[<||>];
	replyBSON = CreateManagedLibraryExpression["BSON", bsonMLE];
	safeLibraryInvoke[mongoCollectionStats,
		getMLEID[coll],
		getMLEID[optsBSON], 
		getMLEID[replyBSON]
	];
	Dataset @ BSONToAssociation[BSONObject[replyBSON]]
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoReferenceGet"]

MongoReferenceGet[database_MongoDatabase, mong_MongoDBReference] := 
CatchFailureAsMessage @ Module[
	{coll, docIter},
	coll = MongoGetCollection[database, First[mong]];
	docIter = MongoCollectionFind[coll, <|"_id" -> <|"$oid" -> Last[mong]|>|>];
	If[FailureQ[docIter], Return[$Failed]];
	Read[docIter]
]

