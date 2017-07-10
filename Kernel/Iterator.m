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
		Integer					(* bson handle *)

	}, 
	"UTF8String"				(* json *)	
]	

(*----------------------------------------------------------------------------*)
PackageScope["MongoIteratorRead"]

(* note: this function returns an error when no next element. Don't throw message,
 so don't use safeLibraryLoad *)
MongoIteratorRead[MongoIterator[handleKey_]] := Module[
	{result},
	result = iteratorNext[handleKey];
	If[LibraryFunctionFailureQ[result], 
		Return[$Failed]
	];
	BSONToAssociation[result]
]
