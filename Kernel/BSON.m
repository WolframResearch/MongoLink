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
			(* Deal with associations first: can assume it contains any wolfram symbols *)
			(* First, convert special expr like DateObject to MongoDB equivalents *)
			doc2 = ReplaceAll[doc, $EncodingRules];
			(* Now convert to JSON. Note that we convert all other expressions to strings *)
			json = Developer`WriteRawJSONString[doc2,
		 		"Compact" -> True,
		 		"ConversionFunction" -> ToString
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

$EncodingRules = {};
$DecodingRules = {};

(*----- Binary -------
Strict: { "$binary": "<bindata>", "$type": "<t>" }
Shell: BinData ( <t>, <bindata> )
*)


(*----- Date -------
Strict: { "$date": "<date>" }
Shell: new Date ( <date> ) 
*)

AppendTo[$EncodingRules,
	x_DateObject :> <|Rule["$date", ToMillisecondUnixTime[x]]|>

];

AppendTo[$DecodingRules,
	<|Rule["$date", x_]|> :> FromMillisecondUnixTime[x]
];

(*----- Timestamp -------
Strict: { "$timestamp": { "t": <t>, "i": <i> } }
Shell: Timestamp( <t>, <i> )
*)


(*----- Regular Expression -------
Strict: { "$regex": "<sRegex>", "$options": "<sOptions>" }
Shell: 	/<jRegex>/<jOptions>
*)


(*----- OID -------
Strict: { "$oid": "<id>" }
Shell: ObjectId( "<id>" )
*)

oidByteToHexString[x_ByteArray] := StringJoin[IntegerString[#, 16] & /@ Normal[x]]

PackageExport["BSONObjectID"] 

AppendTo[$EncodingRules,
	BSONObjectID[x_] -> <|Rule["$oid", x]|>
];

BSONObjectID /: Normal[BSONObjectID[byte_ByteArray]] :=  <|
	"GenerationTime" -> 
		FromUnixTime @ Interpreter["HexInteger"][StringTake[oidByteToHexString[byte], {1, 8}]],
	"MachineID" -> Interpreter["HexInteger"][StringTake[oidByteToHexString[byte], {9, 14}]],
	"ProcessID" -> Interpreter["HexInteger"][StringTake[oidByteToHexString[byte], {15, 18}]],
	"Counter" -> Interpreter["HexInteger"][StringTake[oidByteToHexString[byte], {19, -1}]]
|>;

DefineCustomBoxes[BSONObjectID, 
	e:BSONObjectID[id_] :> Block[{},
	BoxForm`ArrangeSummaryBox[
		BSONObjectID, e, None, 
		{
			BoxForm`SummaryItem[{"OID: ", StringJoin[IntegerString[#, 16] & /@ Normal[id]]}]
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

AppendTo[$EncodingRules,
	BSONDBReference[dataset_, id_] -> <|Rule["$ref", dataset], Rule["$id", id]|>
];

AppendTo[$DecodingRules,
	<|Rule["$ref", dataset_], Rule["$id", id_]|> :> MongoReference[dataset, id]
];

MongoReference /: Normal[x_MongoReference] :=  <|
	"$ref" -> First[x],
	"$id" -> Last[x]
|>;

(* display form *)
DefineCustomBoxes[BSONDBReference, 
	e:BSONDBReference[dataset_, id_] :> Block[{},
	BoxForm`ArrangeSummaryBox[
		BSONDBReference, e, None, 
		{
			BoxForm`SummaryItem[{"ID: ", id}],
			BoxForm`SummaryItem[{"Database: ", dataset}]
		},
		{},
		StandardForm
	]
]];

(*----- Undefined Type -------
Strict: { "$undefined": true }
Shell: 	undefined
*)

(*----- MinKey -------
Strict: { "$minKey": 1 }
Shell: 	MinKey
*)

(*----- MaxKey -------
Strict: { "$maxKey": 1 }
Shell: 	MaxKey
*)

(*----- NumberLong -------
Strict: { "$numberLong": "<number>" }
Shell: NumberLong( "<number>" )
*)
