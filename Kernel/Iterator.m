(*******************************************************************************

Mongo Document Iterator Interface

*******************************************************************************)

Package["MongoLink`"]

(*** Package Exports ***)
PackageExport["MongoIterator"]

(******************************************************************************)
(****** Load Library Functions ******)	

iteratorNext = LibraryFunctionLoad[$MongoLinkLib, "WL_IteratorNext", 
	{
		Integer,					(* cursor handle *)
		Integer						(* bson handle *)

	}, 
	"Void"
]	

(*----------------------------------------------------------------------------*)
PackageScope["MongoIteratorRead"]

MongoIteratorRead[MongoIterator[handleKey_]] := Catch @ Module[
	{bsonHandle},
	bsonHandle = CreateManagedLibraryExpression["MongoBSON", MongoBSON];
	safeLibraryInvoke[iteratorNext, handleKey, ManagedLibraryExpressionID[bsonHandle]];
	BSONToExpression[BSONObject[bsonHandle]]
]
