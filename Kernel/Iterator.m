(*******************************************************************************

Mongo Document Iterator Interface

*******************************************************************************)

Package["MongoLink`"]

(*** Package Exports ***)
PackageExport["MongoIterator"]


(******************************************************************************)
(****** Load Library Functions ******)

iteratorHasNext = LibraryFunctionLoad[$MongoLinkLib, "WL_IteratorHasNext", 
	{
		Integer					(* iterator handle *)
	}, 
	Integer						
]	

iteratorNext = LibraryFunctionLoad[$MongoLinkLib, "WL_IteratorNext", 
	{
		Integer					(* bson handle *)

	}, 
	"UTF8String"				(* json *)	
]	

(******************************************************************************)

PackageScope["MongoIteratorRead"]

MongoIteratorRead[MongoIterator[handleKey_]] := Module[
	{result},
	result = iteratorNext[handleKey];
	If[LibraryFunctionFailureQ@result, 
		(*MongoFailureMessage[MongoIterator];*) 
		Return@$Failed
	];
	BSONToAssociation@result
]

(******************************************************************************)


PackageScope["MongoIteratorHasNextQ"]

(* note: this doesn't seem to actually work very well: it says True but then
getting the next element fails, then this returns False *)
MongoIteratorHasNextQ[MongoIterator[handleKey_]] := Module[
	{result},
	result = iteratorHasNext[handleKey]; 
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[MongoIterator]; 
		Return@$Failed
	];
	If[result === 0, False, True]
]