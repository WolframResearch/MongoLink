(*******************************************************************************

General Collection level functions

*******************************************************************************)

Package["MongoLink`"]

(*** Package Exports ***)
PackageExport["CollectionCount"]

(******************************************************************************)

(****** Load Library Functions ******)

mongoCollectionCount = LibraryFunctionLoad[$MongoLinkLib, "WL_MongoCollectionCount", 
	{
		Integer,			(* connection handle *)
		Integer				(* bson handle *)
	}, 
	Integer					(* count *)						
]	

(******************************************************************************)

Options[CollectionCount] =
{
	"Query" -> <||>
};

CollectionCount[connection_MongoCollection, opts:OptionsPattern[]] := Module[
	{query, bsonQuery, result},
	query  = OptionValue@"Query";
	bsonQuery = BSONCreate@query;
	
	result = mongoCollectionCount[
		ManagedLibraryExpressionID@connection, 
		ManagedLibraryExpressionID@bsonQuery
	];
	
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[ConnectionCount]; 
		Return@$Failed
	];
	result
]
