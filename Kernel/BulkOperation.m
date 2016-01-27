(*******************************************************************************

Bulk Operation level functions

*******************************************************************************)

Package["MongoLink`"]

(*** Package Exports ***)
PackageExport["MongoClient"]

PackageExport["MongoBulkOperation"]
PackageExport["BulkOperationInsert"]
PackageExport["BulkOperationExecute"]

(******************************************************************************)

(****** Load Library Functions ******)

bulkOperationInsert = LibraryFunctionLoad[$MongoLinkLib, "WL_bulk_operation_insert", 
	{
		Integer,					(* bulk op handle *)
		Integer						(* connection info *)
	}, 
	"Void"						
]	

bulkOperationExecute = LibraryFunctionLoad[$MongoLinkLib, "WL_mongoc_bulk_operation_execute", 
	{
		Integer					(* bulk op handle *)
	}, 
	"UTF8String"				(* result string *)			
]

(******************************************************************************)

BulkOperationInsert[bulkop_MongoBulkOperation, doc_ /; (AssociationQ@doc || StringQ@doc)] := Module[
	{bson, result},
	bson = BSONCreate@doc;
	
	If[FailureQ@bson, Return@bson];
	
	result = bulkOperationInsert[
		ManagedLibraryExpressionID@bulkop, 
		ManagedLibraryExpressionID@bson
	];
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[BulkOperationInsert]; 
		Return@$Failed
	];
]

(******************************************************************************)

BulkOperationExecute[bulkop_MongoBulkOperation] := Module[
	{result},
	result = bulkOperationExecute[ManagedLibraryExpressionID@bulkop];
	If[LibraryFunctionFailureQ@result, 
		MongoFailureMessage[BulkOperationInsert]; 
		Return@$Failed
	];
	Developer`ReadRawJSONString@result
]