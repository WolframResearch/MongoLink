(*******************************************************************************

Bulk Operation level functions

*******************************************************************************)

Package["MongoLink`"]

PackageScope["MongoBulkOperation"]

(*----------------------------------------------------------------------------*)
(****** Load Library Functions ******)

bulkOperationInsertLib = LibraryFunctionLoad[$MongoLinkLib, "WL_bulk_operation_insert", 
	{
		Integer,					(* bulk op handle *)
		Integer						(* connection info *)
	}, 
	"Void"						
]	

bulkOperationExecuteLib = LibraryFunctionLoad[$MongoLinkLib, "WL_mongoc_bulk_operation_execute", 
	{
		Integer					(* bulk op handle *)
	}, 
	"UTF8String"				(* result string *)			
]

(*----------------------------------------------------------------------------*)
PackageScope["bulkOperationInsert"]

bulkOperationInsert[bulkop_MongoBulkOperation, doc_BSONObject] := safeLibraryInvoke[
	bulkOperationInsertLib,
	ManagedLibraryExpressionID[bulkop], 
	ManagedLibraryExpressionID[First @ doc]
];

bulkOperationInsert::invtype = "Expected second arg to be BSONObject, but got ``.";
bulkOperationInsert[bulkop_MongoBulkOperation, _] := 
	(Message[bulkOperationInsert::invtype]; Throw[$Failed])

(*----------------------------------------------------------------------------*)
PackageScope["bulkOperationExecute"]

bulkOperationExecute[bulkop_MongoBulkOperation] := Module[
	{result},
	result = safeLibraryInvoke[bulkOperationExecuteLib, ManagedLibraryExpressionID[bulkop]];
	Developer`ReadRawJSONString[result]
]