(*******************************************************************************

BSON: create BSON objects from either JSON or associations

*******************************************************************************)

(* NOTE: this implementation is NOT efficient. An efficient parser and writer 
 is a future project. It should send an association to C via MathLink, and then
 use bson_write_t http://mongoc.org/libbson/current/bson_writer_t.html.
 Same for reading: http://mongoc.org/libbson/current/bson_reader_t.html
*)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]

(******************************************************************************)
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

PackageExport["BSONToAssociation"]
BSONToAssociation[BSONObject[id_]] := Catch @ safeLibraryInvoke[parseBSON, ManagedLibraryExpressionID[id]]

(*----------------------------------------------------------------------------*)
PackageExport["BSONCreate"]

BSONCreate[doc_ /; (AssociationQ[doc] || StringQ[doc])] := Catch @ Module[
	{bsonHandle, result, json, doc2},
	bsonHandle = CreateManagedLibraryExpression["MongoBSON", MongoBSON];
	result = If[AssociationQ[doc],
		json = Developer`WriteRawJSONString[doc2,
		 	"Compact" -> True,
		 	"ConversionRules" -> $EncodingRules
		 ];
		 If[FailureQ[json], Return[json]];
		 safeLibraryInvoke[createBSONfromJSON, ManagedLibraryExpressionID[bsonHandle], json]
		 ,
		 safeLibraryInvoke[createBSONfromJSON, ManagedLibraryExpressionID[bsonHandle], doc]
	];
	BSONObject[bsonHandle]
]

BSONCreate[doc_RawArray /; (Developer`RawArrayType[doc] === "UnsignedInteger8")] := Catch @ Module[
	{bsonHandle}, 
	bsonHandle = CreateManagedLibraryExpression["MongoBSON", MongoBSON];
	safeLibraryInvoke[rawarrayToBSON, ManagedLibraryExpressionID[bsonHandle], doc];
	BSONObject[bsonHandle]
]

BSONCreate[doc_ByteArray] := BSONCreate[RawArray["UnsignedInteger8", Normal[doc]]]

(*----------------------------------------------------------------------------*)
(*********** BSON Types *************)
(* see https://docs.mongodb.com/manual/reference/mongodb-extended-json/ *)
(* Many of these types are not supported yet. *)

(* Note: json converter already handles True, False, Null *)

$EncodingRules = {
	Infinity -> <|"$maxKey" -> 1|>,
	Minus[Infinity] -> <|"$minKey" -> 1|>,
	x_DateObject :> <|"$date", Round @ ToMillisecondUnixTime[x]|>,
	BSONObjectID[x_] -> <|"$oid" -> x|>,
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

