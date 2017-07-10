BeginTestSection["BSON"]

bson1 = BSONCreate[<|"hello" -> {1, 2, 3}|>];

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

(*----------------------------------------------------------------------------*)
(* BSON Extended Types:
  https://docs.mongodb.com/manual/reference/mongodb-extended-json/
*)




(*----------------------------------------------------------------------------*)

EndTestSection[]
