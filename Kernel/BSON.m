(*******************************************************************************

BSON: create BSON objects from either JSON or associations

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]

(*----------------------------------------------------------------------------*)
(****** Load Library Functions ******)

createBSONfromJSON = LibraryFunctionLoad[$MongoLinkLib, "WL_CreateBSONfromJSON",
	{
		Integer,					(* bson handle *)
		"UTF8String"				(* json *)
	},
	"Void"
]

bsonAsJSON = LibraryFunctionLoad[$MongoLinkLib, "WL_bsonAsJSON",
	{
		Integer					(* bson handle *)

	},
	"UTF8String"				(* json *)
]

rawarrayToBSON = LibraryFunctionLoad[$MongoLinkLib, "WL_raw_array_to_bson",
	{
		Integer,					(* bson handle *)
		{"RawArray", "Constant"} 	(* raw array *)

	},
	"Void"				
]

bsonAsRawArray = LibraryFunctionLoad[$MongoLinkLib, "WL_bson_to_rawarray",
	{
		Integer					(* bson handle *)

	},
	"RawArray"
]

parseBSON = LibraryFunctionLoad[$MongoLinkLib, "WL_ParseBSON",
	Automatic, 
	LinkObject
]

(*----------------------------------------------------------------------------*)
PackageExport["BSONObject"]

(* This is a utility function defined in GeneralUtilities, which makes a nicely
formatted display box *)
DefineCustomBoxes[BSONObject, 
	e:BSONObject[id_] :> Block[{},
	BoxForm`ArrangeSummaryBox[
		BSONObject, e, None, 
		{
			BoxForm`SummaryItem[{"ID: ", ManagedLibraryExpressionID[id]}]
		},
		{},
		StandardForm
	]
]];

BSONObject /: ByteArray[bson_BSONObject] := BSONToByteArray[bson]
BSONObject /: Normal[bson_BSONObject] := BSONToExpression[bson]

(*----------------------------------------------------------------------------*)
(* conversion funcs *)

PackageExport["BSONToRawArray"]
BSONToRawArray[BSONObject[id_]] := 
	safeLibraryInvoke[bsonAsRawArray, ManagedLibraryExpressionID[id]]

PackageExport["BSONToByteArray"]
BSONToByteArray[bson_BSONObject] := 
	ByteArray[Normal @ BSONToRawArray[bson]]

PackageExport["BSONToJSON"]
BSONToJSON[BSONObject[id_]] := Catch @ safeLibraryInvoke[bsonAsJSON, ManagedLibraryExpressionID[id]]

PackageExport["BSONToExpression"]

BSONToExpression[x_BSONObject] := Catch @ iBSONToExpression[x]

iBSONToExpression[BSONObject[id_]] := safeLibraryInvoke[parseBSON, ManagedLibraryExpressionID[id]]
iBSONToExpression[x:{__BSONObject}] := iBSONToExpression /@ x
iBSONToExpression[___] := Throw[$Failed]

(*----------------------------------------------------------------------------*)
PackageExport["BSONCreate"]
PackageScope["iBSONCreate"]

iBSONCreate::invjson = "Cannot parse the input into json.";
iBSONCreate::invtype = "Argument must be string, Association or list.";

iBSONCreate[doc_ /; (ListQ[doc] || AssociationQ[doc])] := Module[
	{json},
	json = Developer`WriteRawJSONString[doc,
	 	"Compact" -> True,
	 	"ConversionRules" -> $EncodingRules
	];
	If[FailureQ[json],
	 	Message[iBSONCreate::invjson];
	 	Throw[$Failed]
	 ];
	 iBSONCreate[json]
]

(* assumes doc is json *)
iBSONCreate[doc_String] := Module[
	{bsonHandle},
	bsonHandle = CreateManagedLibraryExpression["MongoBSON", MongoBSON];
	safeLibraryInvoke[createBSONfromJSON, ManagedLibraryExpressionID[bsonHandle], doc];
	BSONObject[bsonHandle]
]

iBSONCreate[doc_RawArray /; (Developer`RawArrayType[doc] === "UnsignedInteger8")] := Module[
	{bsonHandle}, 
	bsonHandle = CreateManagedLibraryExpression["MongoBSON", MongoBSON];
	safeLibraryInvoke[rawarrayToBSON, ManagedLibraryExpressionID[bsonHandle], doc];
	BSONObject[bsonHandle]
]

iBSONCreate[doc_ByteArray] := iBSONCreate[RawArray["UnsignedInteger8", Normal[doc]]]

iBSONCreate[doc_] := (Message[iBSONCreate::invtype]; Throw[$Failed]);

iBSONCreate[doc_BSONObject] := doc (* idempotency *)

BSONCreate[doc_] := Catch @ iBSONCreate[doc];

(*----------------------------------------------------------------------------*)
(*********** BSON Types *************)
(* see https://docs.mongodb.com/manual/reference/mongodb-extended-json/ *)
(* Many of these types are not supported yet. *)

(* Note: json converter already handles True, False, Null *)

$EncodingRules = {
	Infinity :> <|"$maxKey" -> 1|>,
	Minus[Infinity] :> <|"$minKey" -> 1|>,
	x_DateObject :> <|"$date", Round @ ToMillisecondUnixTime[x]|>,
	BSONObjectID[x_] :> <|"$oid" -> x|>,
	BSONDBReference[coll_, id_] :> <|"$ref" -> coll, "$id" -> First[id]|>
};

(*----- ObjectID -------*)
PackageExport["BSONObjectID"]

BSONObjectID /: Normal[BSONObjectID[hex_String]] :=  <|
	"GenerationTime" -> 
		FromUnixTime @ Interpreter["HexInteger"][StringTake[hex, {1, 8}]],
	"MachineID" -> Interpreter["HexInteger"][StringTake[hex, {9, 14}]],
	"ProcessID" -> Interpreter["HexInteger"][StringTake[hex, {15, 18}]],
	"Counter" -> Interpreter["HexInteger"][StringTake[hex, {19, -1}]]
|>;

DefineCustomBoxes[BSONObjectID, 
	e:BSONObjectID[id_] :> Block[{},
	BoxForm`ArrangeSummaryBox[
		BSONObjectID, e, None, 
		{
			BoxForm`SummaryItem[{"OID: ", id}]
		},
		{},
		StandardForm
	]
]];

(*----- DB Reference -------*)
(* 
Strict: { "$oid": "<id>" }
Shell: ObjectId( "<id>" )
*)
PackageExport["BSONDBReference"]

BSONDBReference /: Normal[BSONDBReference[coll_, oid_]] :=  <|
	"Collection" -> coll,
	"ObjectID" -> oid
|>;

(* display form *)
DefineCustomBoxes[BSONDBReference, 
	e:BSONDBReference[coll_, id_] :> Block[{},
	BoxForm`ArrangeSummaryBox[
		BSONDBReference, e, None, 
		{
			BoxForm`SummaryItem[{"OID: ", id}],
			BoxForm`SummaryItem[{"Collection: ", coll}]
		},
		{},
		StandardForm
	]
]];

