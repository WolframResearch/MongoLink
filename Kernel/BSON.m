(*******************************************************************************

BSON: create BSON objects from either JSON or associations

*******************************************************************************)

Package["MongoLink`"]

(*** Package Exports ***)
PackageExport["MongoBSON"]

PackageExport["MongoObjectID"]

PackageExport["BSONCreate"]
PackageExport["BSONToJSON"]
PackageExport["BSONToAssociation"]

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

(******************************************************************************)
(* Rules for encoding and decoding Associations to BSON *)

$EncodingRules = {
	MongoObjectID[x_] -> <|Rule["$oid", x]|>,
	x_DateObject :> <|Rule["$date", toMillisecondUnixTime@x]|>
};

$DecodingRules = {
	<|Rule["$oid", x_]|> :> MongoObjectID[x],
	<|Rule["$date", x_]|> :> fromMillisecondUnixTime[x]
};

(******************************************************************************)
(* Normal form for MongoObjectID *)

MongoObjectID /: Normal[x_MongoObjectID] :=  <|
	"GenerationTime" -> FromUnixTime@Interpreter["HexInteger"]@StringTake[First@x, {1, 8}],
	"MachineID" -> Interpreter["HexInteger"]@StringTake[First@x, {9, 14}],
	"ProcessID" -> Interpreter["HexInteger"]@StringTake[First@x, {15, 18}],
	"Counter" -> Interpreter["HexInteger"]@StringTake[First@x, {19, -1}]
|>	

(******************************************************************************)

BSONCreate[doc_ /; (AssociationQ@doc || StringQ@doc)] := Module[
	{bsonHandle, result, json, doc2},
	bsonHandle = CreateManagedLibraryExpression["MongoBSON", MongoBSON];
	result = If[
		(* Deal with associations first: can assume it contains any wolfram symbols *)
		AssociationQ@doc,
			(* First, convert special expr like DateObject to MongoDB equivalents *)
			doc2 = ReplaceAll[doc, $EncodingRules];
			(* Now convert to JSON. Note that we convert all other expressions to strings *)
			json = Developer`WriteRawJSONString[doc2, 
		 		"Compact" -> True, 
		 		"ConversionFunction" -> ToString
		 	];
		 If[FailureQ@json, Return@json];
		 createBSONfromJSON[ManagedLibraryExpressionID@bsonHandle, json]
		 ,
		 createBSONfromJSON[ManagedLibraryExpressionID@bsonHandle, doc]
	];
	(* Check for errors *)
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[BSONCreate]; 
		Return@$Failed
	];
	bsonHandle
]

(******************************************************************************)

BSONToJSON[bson_MongoBSON] := Module[
	{result},
	result = bsonAsJSON[ManagedLibraryExpressionID@bson];
	
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[BSONToJSON]; 
		Return@$Failed
	];
	result
]

(******************************************************************************)

BSONToAssociation[bson_MongoBSON] := Module[
	{json},
	json = BSONToJSON[bson];
	If[FailureQ@json, 
		Return@json,
		Return@BSONToAssociation[json]	
	]
]

BSONToAssociation[json_String] := Module[
	{assoc},
	assoc = Developer`ReadRawJSONString@json;
	If[FailureQ@assoc, Return@assoc];
	
	(* Now interpret the various MongoDB types, like $symbol or $date, as WL types *)
	ReplaceAll[assoc, $DecodingRules]
]


