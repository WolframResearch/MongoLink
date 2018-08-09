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

cursorGetInfo = LibraryFunctionLoad[$MongoLinkLib, "WL_CursorInfo", 
	{
		Integer,					(* cursor handle *)
		Integer						(* type switch *)

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

Options[MongoCursorToArray] = {
	MaxItems -> Infinity
}

MongoCursorToArray[cursor_MongoCursor, OptionsPattern[]] := 
CatchFailureAsMessage @ Module[
	{bag, current},
	max = OptionValue[MaxItems];

	bag = Internal`Bag[];
	current = iMongoCursorNext[cursor];
	count = 1;
	While[(current =!= Null) && (count <= max),
		Internal`StuffBag[bag, current];
		current = iMongoCursorNext[cursor];
		count += 1;
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
	Replace[safeLibraryInvoke[cursorGetInfo, getMLEID[cursor], 1], 0 -> Automatic]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCursorInformation"]

MongoCursorInformation[cursor_MongoCursor] := CatchFailureAsMessage @ Module[
	{info = getMLEID[cursor]},
	info = safeLibraryInvoke[cursorGetInfo, getMLEID[cursor], #]& /@ Range[5];
	<|
		"BatchSize" -> Replace[info[[1]], 0 -> Automatic],
		"AliveQ" -> Replace[info[[2]], {0 -> False, 1 -> True}],
		"ServerID" -> info[[3]],
		"MaxWaitTime" -> timeconv @ info[[4]],
		"Limit" -> Replace[info[[5]], 0 -> Infinity]
	|>
]

timeconv[x_] := If[x == 0, Automatic, Quantity[8, "Milliseconds"]]