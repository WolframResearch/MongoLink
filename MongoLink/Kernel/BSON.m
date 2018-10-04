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
		True|False				(* relaxed json true/false *)

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
	safeLibraryInvoke[bsonAsJSON, getMLEID[id], relaxed]
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

General::tobsoninvjson = "iToBSON failed: Expression `` cannot be exported as JSON.";
General::tobsoninvtype = 
	"iToBSON failed: Argument must be a String, Association, List, or NumericArray.";
General::tobsoninvnatype = 
	"iToBSON failed: NumericArray has type ``, but must have type UnsignedInteger8.";

iToBSON[doc_Association] := Module[
	{json},

	(* capture message *)
	myMessageList = {};
	Internal`InheritedBlock[{Message, $InMsg = False}, 
  		Unprotect[Message];
		Message[msg_, vars___] /; ! $InMsg := 
   		Block[{$InMsg = True}, 
    		AppendTo[myMessageList, {HoldForm[msg], vars}];
    		Message[msg, vars]
    	];
  		(*code to run*)
  		json = Quiet @ Developer`WriteRawJSONString[doc,
	 		"Compact" -> True,
	 		"ConversionRules" -> $EncodingRules
		];
	];
	If[FailureQ[json],
	 	ThrowFailure["tobsoninvjson", myMessageList[[1, 2]]];
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

iToBSON[doc: (_RawArray | _NumericArray)] := Module[
	{bsonHandle, type}, 
	type = Developer`RawArrayType[doc];
	If[type =!= "UnsignedInteger8",
		ThrowFailure["tobsoninvnatype", type]
	];
	bsonHandle = CreateManagedLibraryExpression["BSON", bsonMLE];
	safeLibraryInvoke[rawarrayToBSON, getMLEID[bsonHandle], doc];
	BSONObject[bsonHandle]
]

iToBSON[doc_ByteArray] := iToBSON[RawArray["UnsignedInteger8", Normal[doc]]]

iToBSON[doc_] := ThrowFailure["tobsoninvtype"]

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
	DirectedInfinity[1] :> <|"$maxKey" -> 1|>,
	DirectedInfinity[-1] :> <|"$minKey" -> 1|>,
	(* for binary data 00 is the recommended default type for drivers, 
		see http://bsonspec.org/spec.html *)
	x_ByteArray :> <|"$binary" -> <|
		"base64" -> Developer`EncodeBase64[x],
		"subType" -> "00"
	|>|>,
	x_DateObject :> <|"$date" -> Round @ ToMillisecondUnixTime[x]|>,
	BSONObjectID[x_] :> <|"$oid" -> x|>,
	BSONTimestamp[time_, inc_] :> <|"$timestamp" -> <|"t" -> time, "i" -> inc|>|>,
	BSONDBReference[coll_, id_] :> <|"$ref" -> coll, "$id" -> First[id]|>,
	BSONDecimal128[x_] :> <|"$numberDecimal" -> x|>
};

(*----- ObjectID -------*)
PackageExport["BSONObjectID"]

BSONObjectID /: Normal[BSONObjectID[hex_String]] := Dataset @ <|
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

(*----- Timestamp -------*)
PackageExport["BSONTimestamp"]

DefineCustomBoxes[BSONTimestamp, 
	e:BSONTimestamp[time_, inc_] :> Block[{},
	BoxForm`ArrangeSummaryBox[
		BSONObjectID, e, None, 
		{
			BoxForm`SummaryItem[{"Time: ", time}],
			BoxForm`SummaryItem[{"Increment: ", inc}]
		},
		{},
		StandardForm
	]
]];

(*----- Decimal128 -------*)
PackageExport["BSONDecimal128"]

(* check that number is not more precise than Decimal128 can handle *)
BSONDecimal128::invnum = "Number is too `` for Decimal128.";

(* There is probably a faster way to do this *)
safeDecimal128[num_] := Module[
	{
		str = RealDigitsString[num, 34],
		val
	},
	val = If[Positive[num], "large", "small"];
	If[Last[MantissaExponent[num, 10]] > 34, ThrowFailure[BSONDecimal128::invnum, val]];
	BSONDecimal128[str]
]

BSONDecimal128 /: Normal[BSONDecimal128[num_String]] := ToExpression[num]

DefineCustomBoxes[BSONDecimal128, 
	e:BSONDecimal128[num_String] :> Block[{},
	BoxForm`ArrangeSummaryBox[
		BSONDecimal128, e, None, 
		{
			BoxForm`SummaryItem[{"Value: ", num}]
		},
		{},
		StandardForm
	]
]];

BSONDecimal128[num_Real] := CatchFailureAsMessage @ safeDecimal128[num]
BSONDecimal128[num_Integer] := BSONDecimal128[N[num]]

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

