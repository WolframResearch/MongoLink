(*******************************************************************************

Database level functions

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]

PackageScope["bulkopMLE"] (* bulkop ManagedLibraryExpression *)

(*----------------------------------------------------------------------------*)
(****** Load Library Functions ******)

createBulkOpFromCollection = LibraryFunctionLoad[$MongoLinkLib, "WL_CreateBulkOpFromCollection", 
	{
		Integer,					(* bulkop handle *)
		Integer,					(* collection handle *)
		Integer,					(* write concern handle *)
		True|False					(* ordered *)

	}, 
	True|False						(* authenticated *)					
]	

bulkOpExecuteLL = LibraryFunctionLoad[$MongoLinkLib, "WL_BulkOpExecute", 
	{
		Integer,					(* bulkop handle *)
		Integer						(* reply bson handle *)

	}, 
	"Void"						
]	

bulkOpUpdate = LibraryFunctionLoad[$MongoLinkLib, "WL_mongoc_bulk_operation_update", 
	{
		Integer,					(* bulkop handle *)
		Integer,					(* selector bson handle *)
		Integer,					(* doc bson handle *)
		Integer,					(* opts bson handle *)
		True|False					(* many or one *)
	}, 
	"Void"						
]	

bulkOpInsert = LibraryFunctionLoad[$MongoLinkLib, "WL_mongoc_bulk_operation_insert", 
	{
		Integer,					(* bulkop handle *)
		Integer,					(* opts bson handle *)
		{Integer, 1, "Constant"}	(* doc bson handles *)
	}, 
	"Void"
]

bulkOpRemove = LibraryFunctionLoad[$MongoLinkLib, "WL_mongoc_bulk_operation_remove", 
	{
		Integer,					(* bulkop handle *)
		Integer,					(* selector bson handle *)
		Integer,					(* opts bson handle *)
		True|False					(* many or one *)
	}, 
	"Void"						
]

bulkOpReplaceOne = LibraryFunctionLoad[$MongoLinkLib, "WL_mongoc_bulk_operation_replace_one", 
	{
		Integer,					(* bulkop handle *)
		Integer,					(* selector bson handle *)
		Integer,					(* doc bson handle *)
		Integer						(* opts bson handle *)
	}, 
	"Void"						
]

(*----------------------------------------------------------------------------*)
General::mongoinvordered = 
	"The option \"Ordered\" was ``, but must be either True or False.";
General::mongoinvwriteconcern = 
	"The option \"WriteConcern\" was ``, but must be a MongoWriteConcern or Automatic.";
General::mongoinvupsert = 
	"The option \"Upsert\" was ``, but must be either True or False.";

(*----------------------------------------------------------------------------*)
createBulkOperation[coll_MongoCollection, wc_, ordered_] := Module[
	{wcNew, bulkOp, res},
	If[!BooleanQ[ordered],
		ThrowFailure["mongoinvordered", ordered]
	];
	If[Not[(Head[wc] === MongoWriteConcern) || (wc === Automatic)],
		ThrowFailure["mongoinvwriteconcern", wc];
	];
	wcNew = Replace[wc, 
		Automatic :> CreateManagedLibraryExpression["WriteConcern", writeConcernMLE]];
	
	bulkOp = CreateManagedLibraryExpression["BulkOp", bulkopMLE];
	res = safeLibraryInvoke[createBulkOpFromCollection,
		getMLEID[bulkOp],
		getMLEID[coll],
		getMLEID[wcNew],
		ordered
	];
	{res, bulkOp}
]

(*----------------------------------------------------------------------------*)

bulkOpExecute[bulk_bulkopMLE] := Module[
	{reply},
	reply = CreateManagedLibraryExpression["BSON", bsonMLE];
	safeLibraryInvoke[bulkOpExecuteLL, getMLEID[bulk], getMLEID[reply]];
	Normal[BSONObject[reply]]
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoInsertResult"]

(* This is a utility function defined in GeneralUtilities, which makes a nicely
formatted display box *)
DefineCustomBoxes[MongoInsertResult, 
	e:MongoInsertResult[res_Association] :> Block[{},
	BoxForm`ArrangeSummaryBox[
		MongoInsertResult, e, None,
		{
			BoxForm`SummaryItem[{"InsertedCount: ", Lookup[res, "InsertedCount"]}],
			BoxForm`SummaryItem[{"Acknowledged: ", Lookup[res, "Acknowledged"]}]
		},
		{},
		StandardForm
	]
]];

MongoInsertResult[res_]["InsertedCount"] := Lookup[res, "InsertedCount"]
MongoInsertResult[res_]["Acknowledged"] := Lookup[res, "Acknowledged"]
MongoInsertResult[res_]["InsertedIDs"] := Lookup[res, "InsertedIDs"]
MongoInsertResult[res_][___] := $Failed

(*----------------------------------------------------------------------------*)
(* Insertion: Note that the Mongo spec supports three different insert ops:
	insert, insertOne, insertMany. PyMongo deprecated insert, and recommends 
	only insertOne and insertMany. We will follow the API of insertMany,
	and call it MongoCollectionInsert.
*)

PackageExport["MongoCollectionInsert"]

Options[MongoCollectionInsert] = {
	"WriteConcern" -> Automatic,
	"Ordered" -> True
};

MongoCollectionInsert[coll_MongoCollection, doc_, opts:OptionsPattern[]] := 
CatchFailureAsMessage @ Module[
	{wc, ordered},
	(** parse options **)
	{wc, ordered} = OptionValue[{"WriteConcern", "Ordered"}];
	iMongoCollectionInsert[coll, doc, wc, ordered]
]

iMongoCollectionInsert[
	collection_MongoCollection, docs:{__BSONObject}, wc_, ordered_] := Module[
	{keyNames, auth, bulk, optsBSON},
	{auth, bulk} = createBulkOperation[collection, wc, ordered];
	(* no opts yet *)
	optsBSON = ToBSON[<||>];
	(* insert docs into bulk executor. Mutates docs to have _id field!! *)
	safeLibraryInvoke[bulkOpInsert, 
		getMLEID[bulk], 
		getMLEID[optsBSON], 
		getMLEID /@ docs
	];
	(* execute bulk. reply not used in insert *)
	bulkOpExecute[bulk];
	keyNames = bsonLookup[#, "_id"]& /@ docs;
	System`Private`SetNoEntry @ MongoInsertResult @ <|
		"Acknowledged" -> auth, 
		"InsertedIDs" -> keyNames, 
		"InsertedCount" -> Length[keyNames]
	|>
]

iMongoCollectionInsert[coll_MongoCollection, doc_BSONObject, wc_, ordered_] := 
	iMongoCollectionInsert[coll, {doc}, wc, ordered]

iMongoCollectionInsert[coll_MongoCollection, doc_Association|doc_String, wc_, ordered_] := 
	iMongoCollectionInsert[coll, {iToBSON[doc]}, wc, ordered]

iMongoCollectionInsert[coll_MongoCollection, doc_List, wc_, ordered_] := 
	iMongoCollectionInsert[coll, iToBSON /@ doc, wc, ordered]

MongoCollectionInsert::invtype =
	"Document to be inserted must be an Association, JSON String or BSONObject, or a list of these.";
iMongoCollectionInsert[coll_MongoCollection, doc_, wc_, ordered_] := 
	ThrowFailure[MongoCollectionInsert::invtype];
	
(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionReplaceOne"]

Options[MongoCollectionReplaceOne] = {
	"WriteConcern" -> Automatic,
	"Upsert" -> False
};

MongoCollectionReplaceOne[coll_MongoCollection, filter_Association, replacement_Association, opts:OptionsPattern[]] := 
CatchFailureAsMessage @ Module[
	{
		wc, upsert, auth, bulk, optsBSON,
		filterBSON = iToBSON[filter],
		replacementBSON = iToBSON[replacement],
		reply
	},
	(** parse options **)
	{wc, upsert} = OptionValue[{"WriteConcern", "Upsert"}];
	If[!BooleanQ[upsert], ThrowFailure["mongoinvupsert", upsert]];
	(* create bulk op *)
	{auth, bulk} = createBulkOperation[coll, wc, True];
	optsBSON = ToBSON[<|"upsert" -> upsert|>];
	safeLibraryInvoke[bulkOpReplaceOne, 
		getMLEID[bulk],
		getMLEID[filterBSON],
		getMLEID[replacementBSON],
		getMLEID[optsBSON]
	];
	(* execute the bulk op *)
	reply = bulkOpExecute[bulk];
	<|
		"Acknowledged" -> auth, 
		"MatchedCount" -> reply["nMatched"], 
		"ModifiedCount" -> reply["nModified"]
	|>
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionUpdateOne"]
PackageExport["MongoCollectionUpdateMany"]

(*** update one ***)
Options[MongoCollectionUpdateOne] = {
	"WriteConcern" -> Automatic,
	"Upsert" -> False
};

MongoCollectionUpdateOne[coll_MongoCollection, filter_Association, update_Association, opts:OptionsPattern[]] := 
CatchFailureAsMessage[
	iMongoCollectionUpdate[coll, filter, update, OptionValue["WriteConcern"], OptionValue["Upsert"], False]
]

(*** update many ***)
Options[MongoCollectionUpdateMany] = {
	"WriteConcern" -> Automatic,
	"Upsert" -> False
};

MongoCollectionUpdateMany[coll_MongoCollection, filter_Association, update_Association, opts:OptionsPattern[]] := 
CatchFailureAsMessage[
	iMongoCollectionUpdate[coll, filter, update, OptionValue["WriteConcern"], OptionValue["Upsert"], True]
]

(*** dual implementation ***)
iMongoCollectionUpdate[coll_, filter_, update_, wc_, upsert_, many_] := Module[
	{
		auth, bulk, optsBSON,
		filterBSON = iToBSON[filter],
		updateBSON = iToBSON[update],
		reply
	},
	If[!BooleanQ[upsert], ThrowFailure["mongoinvupsert", upsert]];
	(* create bulk op *)
	{auth, bulk} = createBulkOperation[coll, wc, True];
	optsBSON = ToBSON[<|"upsert" -> upsert|>];
	safeLibraryInvoke[bulkOpUpdate, 
		getMLEID[bulk],
		getMLEID[filterBSON],
		getMLEID[updateBSON],
		getMLEID[optsBSON],
		many
	];
	(* execute the bulk op *)
	reply = bulkOpExecute[bulk];
	<|
		"Acknowledged" -> auth, 
		"MatchedCount" -> reply["nMatched"], 
		"ModifiedCount" -> reply["nModified"]
	|>
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionDeleteOne"]
PackageExport["MongoCollectionDeleteMany"]

(*** update one ***)
Options[MongoCollectionDeleteOne] = {
	"WriteConcern" -> Automatic
};

MongoCollectionDeleteOne[coll_MongoCollection, filter_Association, opts:OptionsPattern[]] := 
CatchFailureAsMessage[
	iMongoCollectionDelete[coll, filter, OptionValue["WriteConcern"], False]
]

(*** update many ***)
Options[MongoCollectionDeleteMany] = {
	"WriteConcern" -> Automatic
};

MongoCollectionDeleteMany[coll_MongoCollection, filter_Association, opts:OptionsPattern[]] := 
CatchFailureAsMessage[
	iMongoCollectionDelete[coll, filter, OptionValue["WriteConcern"], True]
]

(*** dual implementation ***)
iMongoCollectionDelete[coll_, filter_, wc_, many_] := Module[
	{
		auth, bulk, optsBSON,
		filterBSON = iToBSON[filter],
		reply
	},
	(* create bulk op *)
	{auth, bulk} = createBulkOperation[coll, wc, True];
	optsBSON = ToBSON[<||>];
	safeLibraryInvoke[bulkOpRemove, 
		getMLEID[bulk],
		getMLEID[filterBSON],
		getMLEID[optsBSON],
		many
	];
	(* execute the bulk op *)
	reply = bulkOpExecute[bulk];
	<|
		"Acknowledged" -> auth, 
		"DeletedCount" -> reply["nRemoved"]
	|>
]
