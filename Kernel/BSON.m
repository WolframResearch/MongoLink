(*******************************************************************************

BSON: create BSON objects from either JSON or associations

*******************************************************************************)

Package["MongoLink`"]

(*** Package Exports ***)
PackageExport["MongoBSON"]

PackageExport["BSONCreate"]
PackageExport["BSONToJSON"]

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

BSONCreate[doc_ /; (AssociationQ@doc || StringQ@doc)] := Module[
	{bsonHandle, result, json},
	bsonHandle = CreateManagedLibraryExpression["MongoBSON", MongoBSON];
	result = If[AssociationQ@doc, 	
		 json = Developer`WriteRawJSONString[doc, "Compact" -> True];
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

