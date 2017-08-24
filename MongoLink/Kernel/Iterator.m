(*******************************************************************************

Mongo Document Iterator Interface

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]

(*** Package Exports ***)
PackageExport["MongoIterator"]

(******************************************************************************)
(****** Load Library Functions ******)	

iteratorNext = LibraryFunctionLoad[$MongoLinkLib, "WL_IteratorNext", 
	{
		Integer,					(* cursor handle *)
		Integer						(* bson handle *)

	}, 
	Integer
]	

(*----------------------------------------------------------------------------*)
PackageScope["MongoIteratorRead"]

MongoIteratorRead[MongoIterator[handleKey_]] := CatchFailureAsMessage @ Module[
	{bsonHandle, hasNext},
	bsonHandle = CreateManagedLibraryExpression["MongoBSON", MongoBSON];
	hasNext = 
		safeLibraryInvoke[iteratorNext, handleKey, ManagedLibraryExpressionID[bsonHandle]];
	If[hasNext === 0, Return[$Failed]];
	BSONToExpression[BSONObject[bsonHandle]]
]
