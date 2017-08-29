(*******************************************************************************

BSON: create BSON objects from either JSON or associations

Note: BSON is independent of MongoDB, so don't prepend name MongoBSON. Rather,
use name BSONObject.

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]

PackageScope["bsonMLE"] (* bson ManagedLibraryExpression *)

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
		Integer,				(* bson handle *)
		Integer					(* relaxed json true/false *)

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

bsonGetBSONKey = LibraryFunctionLoad[$MongoLinkLib, "WL_get_bson_key",
	{
		Integer, 				(* bson handle *)
		Integer,				(* return bson *)
		"UTF8String"			(* key *)

	},
	Integer
]

(*----------------------------------------------------------------------------*)
PackageExport["BSONObject"]

(* This is a utility function defined in GeneralUtilities, which makes a nicely
formatted display box *)
DefineCustomBoxes[BSONObject, 
	e:BSONObject[bsonMLE_] :> Block[{},
	BoxForm`ArrangeSummaryBox[
		BSONObject, e, None, 
		{
			BoxForm`SummaryItem[{"ID: ", getMLEID[bsonMLE]}]
		},
		{},
		StandardForm
	]
]];

getMLE[BSONObject[bsonMLE_]] := bsonMLE;
getMLEID[BSONObject[bsonMLE_]] := ManagedLibraryExpressionID[bsonMLE];

BSONObject /: ByteArray[bson_BSONObject] := BSONToByteArray[bson]
BSONObject /: Normal[bson_BSONObject] := BSONToAssociation[bson]

(*----------------------------------------------------------------------------*)
(* conversion funcs *)

PackageExport["BSONToRawArray"]
BSONToRawArray[BSONObject[id_]] := 
	safeLibraryInvoke[bsonAsRawArray, getMLEID[id]]

PackageExport["BSONToByteArray"]
BSONToByteArray[bson_BSONObject] := 
	ByteArray[Normal @ BSONToRawArray[bson]]

(*----------------------------------------------------------------------------*)
PackageExport["BSONToJSON"]

Options[BSONToJSON] = {
	"Relaxed" -> False
};

BSONToJSON::invrelaxed = "Value for option \"Relaxed\" must be boolean, but `` was given.";

BSONToJSON[BSONObject[id_], opts:OptionsPattern[]] := CatchFailureAsMessage @ Module[
	{relaxed = OptionValue["Relaxed"]},
	If[!BooleanQ[relaxed], ThrowFailure[BSONToJSON::invrelaxed, relaxed]];
	safeLibraryInvoke[bsonAsJSON, getMLEID[id], Boole[relaxed]]
]

(*----------------------------------------------------------------------------*)
PackageExport["BSONToAssociation"]

BSONToAssociation[x_BSONObject] := CatchFailureAsMessage @ iBSONToAssociation[x]

iBSONToAssociation[bson_BSONObject] := safeLibraryInvoke[parseBSON, getMLEID[bson]]
iBSONToAssociation[x:{__BSONObject}] := iBSONToAssociation /@ x

iBSONToAssociation::invarg = "Invalid argument."
iBSONToAssociation[___] := ThrowFailure[iBSONToAssociation::invarg]

(*----------------------------------------------------------------------------*)
PackageExport["ToBSON"]
PackageScope["iToBSON"]

iToBSON::invjson = "Cannot parse the input into json.";
iToBSON::invtype = "Argument must be string, Association or list.";

iToBSON[doc_Association] := Module[
	{json},
	json = Developer`WriteRawJSONString[doc,
	 	"Compact" -> True,
	 	"ConversionRules" -> $EncodingRules
	];
	If[FailureQ[json],
	 	ThrowFailure[iToBSON::invjson]
	];
	 iToBSON[json]
]

(* assumes doc is json *)
iToBSON[doc_String] := Module[
	{bsonHandle},
	bsonHandle = CreateManagedLibraryExpression["BSON", bsonMLE];
	safeLibraryInvoke[createBSONfromJSON, getMLEID[bsonHandle], doc];
	BSONObject[bsonHandle]
]

iToBSON[doc_RawArray /; (Developer`RawArrayType[doc] === "UnsignedInteger8")] := Module[
	{bsonHandle}, 
	bsonHandle = CreateManagedLibraryExpression["BSON", bsonMLE];
	safeLibraryInvoke[rawarrayToBSON, getMLEID[bsonHandle], doc];
	BSONObject[bsonHandle]
]

iToBSON[doc_ByteArray] := iToBSON[RawArray["UnsignedInteger8", Normal[doc]]]

iToBSON[doc_] := ThrowFailure[iToBSON::invtype]

iToBSON[doc_BSONObject] := doc (* idempotency *)

ToBSON[doc_] := CatchFailureAsMessage @ iToBSON[doc];

(*----------------------------------------------------------------------------*)
PackageScope["bsonLookup"]

bsonLookup[bson_BSONObject, key_String] := Module[
	{bsonOut, res},
	bsonOut = CreateManagedLibraryExpression["BSON", bsonMLE];
	res = safeLibraryInvoke[bsonGetBSONKey, getMLEID[bson], getMLEID[bsonOut], key];
	If[res === 0, Return @ Missing["KeyAbsent", key]];
	Lookup[BSONToAssociation[BSONObject[bsonOut]], key]
]

(*----------------------------------------------------------------------------*)
(*********** BSON Types *************)
(* see https://docs.mongodb.com/manual/reference/mongodb-extended-json/ *)
(* This is also useful:
	https://github.com/mongodb/specifications/blob/master/source/extended-json.rst
*)
(* Many of these types are not supported yet. *)

(* Note: json converter already handles True, False, Null *)

$EncodingRules = {
	Infinity :> <|"$maxKey" -> 1|>,
	Minus[Infinity] :> <|"$minKey" -> 1|>,
	(* for binary data 00 is the recommended default type for drivers, 
		see http://bsonspec.org/spec.html *)
	x_ByteArray :> <|"$binary" -> <|
		"base64" -> Developer`EncodeBase64[x],
		"subType" -> "00"
	|>|>,
	x_DateObject :> <|"$date" -> Round @ ToMillisecondUnixTime[x]|>,
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

