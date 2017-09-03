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

mongoCollectionName = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_CollectionGetName", 
	{
		Integer			(* collection handle *)
	}, 
	"UTF8String"		(* name *)						
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
	{pipeline},
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

