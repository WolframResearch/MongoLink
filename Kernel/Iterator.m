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

MongoIterator[handleKey_][] := Module[
	{result},
	result = iteratorNext[handleKey];
	If[LibraryFunctionFailureQ@result, 
		(*MongoFailureMessage[MongoIterator];*) 
		Return@$Failed
	];
	Developer`ReadRawJSONString@result
]

(******************************************************************************)

MongoIterator[handleKey_]["HasNext"] := Module[
	{result},
	result = iteratorHasNext[handleKey]; Print[result];
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[MongoIterator]; 
		Return@$Failed
	];
	If[result === 0, False, True]
]