(*******************************************************************************

Mongo Document Cursor Interface

See: https://docs.mongodb.com/manual/reference/method/js-cursor/

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]

PackageScope["cursorMLE"] (* cursor ManagedLibraryExpression *)

(******************************************************************************)
(****** Load Library Functions ******)	

cursorNext = LibraryFunctionLoad[$MongoLinkLib, "WL_CursorNext", 
	{
		Integer,					(* cursor handle *)
		Integer						(* bson handle *)

	},
	Integer
]

cursorSetBatchSize = LibraryFunctionLoad[$MongoLinkLib, "WL_CursorSetBatchSize", 
	{
		Integer,					(* cursor handle *)
		Integer						(* batch size *)

	},
	"Void"
]

cursorGetBatchSize = LibraryFunctionLoad[$MongoLinkLib, "WL_CursorGetBatchSize", 
	{
		Integer					(* cursor handle *)

	},
	Integer
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCursor"]

(* This is a utility function defined in GeneralUtilities, which makes a nicely
formatted display box *)
DefineCustomBoxes[MongoCursor, 
	e:MongoCursor[cursorMLE_, client_] :> Block[{},
	BoxForm`ArrangeSummaryBox[
		MongoCursor, e, None, 
		{
			BoxForm`SummaryItem[{"ID: ", getMLEID[cursorMLE]}]
		},
		{},
		StandardForm
	]
]];

getClient[MongoCursor[__, client_]] := client

getMLE[MongoCursor[cursorMLE_, __]] := cursorMLE;
getMLEID[MongoCursor[cursorMLE_, __]] := ManagedLibraryExpressionID[cursorMLE];

MongoCursor /: Read[cursor_MongoCursor] := MongoCursorNext[cursor]
MongoCursor /: ReadList[cursor_MongoCursor] := MongoCursorToArray[cursor]

MongoCursor /: Dataset[cursor_MongoCursor] := Dataset @ MongoCursorToArray[cursor]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCursorNext"]

MongoCursorNext[cursor_MongoCursor] := CatchFailureAsMessage @ iMongoCursorNext[cursor]

iMongoCursorNext[cursor_MongoCursor] := Module[
	{bson, hasNext},
	bson = CreateManagedLibraryExpression["BSON", bsonMLE];
	hasNext = safeLibraryInvoke[cursorNext, getMLEID[cursor], getMLEID[bson]];
	(* return Null if iterator is exhausted *)
	If[hasNext === 0, 
		Null,
		BSONToAssociation @ BSONObject[bson]
	]
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCursorToArray"]

MongoCursorToArray[cursor_MongoCursor] := CatchFailureAsMessage @ Module[
	{bag, current},
	bag = Internal`Bag[];
	current = iMongoCursorNext[cursor];
	While[current =!= Null,
		Internal`StuffBag[bag, current];
		current = iMongoCursorNext[cursor]
	];
	Internal`BagPart[bag, All]
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCursorSetBatchSize"]

MongoCursorSetBatchSize[cursor_MongoCursor, size_Integer] := CatchFailureAsMessage @
	safeLibraryInvoke[cursorSetBatchSize, getMLEID[cursor], size];

MongoCursorBatchSize[cursor_MongoCursor, Automatic] := CatchFailureAsMessage @
	safeLibraryInvoke[cursorSetBatchSize, getMLEID[cursor], 0];

(*----------------------------------------------------------------------------*)
PackageExport["MongoCursorGetBatchSize"]

MongoCursorGetBatchSize[cursor_MongoCursor] := CatchFailureAsMessage @
	Replace[safeLibraryInvoke[cursorGetBatchSize, getMLEID[cursor]], 0 -> Automatic]

