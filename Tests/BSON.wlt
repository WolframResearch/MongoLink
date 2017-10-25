BeginTestSection["BSON"]

assoc = <|"hello" -> {1, 2.5, 3.}|>;
json = "{ \"hello\" : [ 1, 2.5, 3.0 ] }";
bson1 = ToBSON[<|"hello" -> {1, 2.5, 3.}|>];

(*----------------------------------------------------------------------------*)
(* Conversion Functions *)

(* raw array conversion *)

VerificationTest[
	BSONToRawArray[bson1], 
	_RawArray, 
 	TestID -> "BSON to raw array", 
 	SameTest -> MatchQ
 ]
 
VerificationTest[
	BSONToJSON @ ToBSON[BSONToRawArray[bson1]],
	BSONToJSON @ bson1,
	TestID -> "BSON to RawArray to JSON"
]

(* byte array conversion 1 *)

VerificationTest[
	BSONToByteArray[bson1], 
	_ByteArray, 
 	TestID -> "BSON to byte array",
 	SameTest -> MatchQ
 ]
 
VerificationTest[
	BSONToJSON @ ToBSON[BSONToByteArray[bson1]],
	BSONToJSON @ bson1,
	TestID -> "BSON to ByteArray to JSON v1"
]

(* byte array conversion 2 *)

VerificationTest[
	ByteArray[bson1], 
	BSONToByteArray[bson1], 
 	TestID -> "ByteArray same as BSONToByteArray"
 ]
 
VerificationTest[
	BSONToJSON @ ToBSON[ByteArray[bson1]],
	BSONToJSON @ bson1,
	TestID -> "BSON to ByteArray to JSON v2"
]

(* byte array association *)

VerificationTest[
	BSONToAssociation[bson1], 
	_Association, 
 	TestID -> "BSON to assoc", 
 	SameTest -> MatchQ
 ] 
 
VerificationTest[
	BSONToJSON @ ToBSON[BSONToAssociation[bson1]],
	BSONToJSON @ bson1,
	TestID -> "BSON to expression to JSON"
]

(*----------------------------------------------------------------------------*)
(* ToBSON *)

(*ToBSON for associations*)
VerificationTest[
	ToBSON[assoc], 
	_BSONObject, 
 	TestID -> "Assocation to BSON", 
 	SameTest -> MatchQ
 ]
 
 (*ToBSON for JSON*)

VerificationTest[
	ToBSON[json], 
	_BSONObject, 
 	TestID -> "JSON to BSON", 
 	SameTest -> MatchQ
 ]
 
(*----------------------------------------------------------------------------*)
(* BSONObjectID *)

VerificationTest[
 	Normal@BSONObjectID["666f6f2d6261722d71757578"], 
 	_Dataset, 
 	TestID -> "BSONObjectID returns association", 
 	SameTest -> MatchQ
 ]
 
(*----------------------------------------------------------------------------*)
(* BSONObject *)

 VerificationTest[
 	Normal@ToBSON[assoc], 
 	BSONToAssociation[ToBSON[assoc]], 
 	TestID -> "BSONObject//Normal returns same as BSONtoExpression"
 ]
 
(*----------------------------------------------------------------------------*)
(* Round Trip *)

VerificationTest[
	assoc,
	BSONToAssociation@ToBSON@BSONToJSON@ToBSON@BSONToByteArray@ToBSON@BSONToRawArray@ToBSON@assoc,
	TestID -> "Association round trip"
 ]

(*----------------------------------------------------------------------------*)
(* BSON Extended Types:
  https://docs.mongodb.com/manual/reference/mongodb-extended-json/
*)




(*----------------------------------------------------------------------------*)

EndTestSection[]
