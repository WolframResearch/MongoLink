BeginTestSection["BSON"]

assoc = <|"hello" -> {1, 2.5, 3.}|>;
json = "{ \"hello\" : [ 1, 2.5, 3.0 ] }";
list = {<|"hello" -> {1, 2.5, 3.}|>, <|"1" -> <|"Name" -> "dog"|>|>, <|
    "f5" -> "foo"|>};
bson1 = BSONCreate[<|"hello" -> {1, 2.5, 3.}|>];

(*----------------------------------------------------------------------------*)
(* Conversion Functions *)

(* raw array conversion *)
VerificationTest[
	BSONToJSON @ BSONCreate[BSONToRawArray[bson1]],
	BSONToJSON @ bson1,
	TestID -> 1
]

(* byte array conversion 1 *)
VerificationTest[
	BSONToJSON @ BSONCreate[BSONToByteArray[bson1]],
	BSONToJSON @ bson1,
	TestID -> 2
]

(* byte array conversion 2 *)
VerificationTest[
	BSONToJSON @ BSONCreate[ByteArray[bson1]],
	BSONToJSON @ bson1,
	TestID -> 3
]

(* byte array association *)
VerificationTest[
	BSONToJSON @ BSONCreate[BSONToAssociation[bson1]],
	BSONToJSON @ bson1,
	TestID -> 4
]

(*JSON*)

VerificationTest[
	BSONToJSON[bson1], 
	"{ \"hello\" : [ 1, 2.5, 3.0 ] }",
  	TestID -> "BSON to JSON"
]
(*----------------------------------------------------------------------------*)
(* BSONCreate *)

(*BSONCreate for associations*)
VerificationTest[
	BSONCreate[assoc], 
	_BSONObject, 
 	TestID -> "Assocation to BSON", 
 	SameTest -> MatchQ
 ]
 
 (*BSONCreate for JSON*)

VerificationTest[
	BSONCreate[json], 
	_BSONObject, 
 	TestID -> "JSON to BSON", 
 	SameTest -> MatchQ
 ]

(*BSONCreate for list*)

VerificationTest[
	BSONCreate[list], 
	_BSONObject, 
 	TestID -> "list to BSON", 
 	SameTest -> MatchQ
 ]
(*----------------------------------------------------------------------------*)
(* BSON Extended Types:
  https://docs.mongodb.com/manual/reference/mongodb-extended-json/
*)




(*----------------------------------------------------------------------------*)

EndTestSection[]
