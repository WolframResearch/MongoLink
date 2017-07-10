(*******************************************************************************

Bulk Operation level functions

*******************************************************************************)

Package["MongoLink`"]

PackageScope["MongoBulkOperation"]

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

(*----------------------------------------------------------------------------*)
PackageScope["BulkOperationInsert"]

BulkOperationInsert::fail = "Failed to evaluate BulkOperationInsert."

BulkOperationInsert[bulkop_MongoBulkOperation, doc_ /; (AssociationQ@doc || StringQ@doc)] := Module[
	{bson},
	bson = BSONCreate[doc];
	If[FailureQ[bson], 
		Message[BulkOperationInsert::fail];
		Throw[$Failed]
	];
	safeLibraryInvoke[bulkOperationInsert,
		ManagedLibraryExpressionID[bulkop], 
		ManagedLibraryExpressionID[First @ bson]
	];
	bulkop
]

(*----------------------------------------------------------------------------*)
PackageScope["BulkOperationExecute"]

BulkOperationExecute[bulkop_MongoBulkOperation] := Module[
	{result},
	result = safeLibraryInvoke[bulkOperationExecute, ManagedLibraryExpressionID[bulkop]];
	Developer`ReadRawJSONString[result]
]