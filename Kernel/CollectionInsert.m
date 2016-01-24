(*******************************************************************************

Bulk Operations Interface

*******************************************************************************)

Package["MongoLink`"]

(*** Package Exports ***)


(******************************************************************************)

(****** Load Library Functions ******)


(*mongoCollectionBulkOperation = LibraryFunctionLoad[$MongoLinkLib, "WL_MongoCollectionBulkOperation", 
	{
		Integer,		(* bulk_handle_key *)
		Integer,		(* collection handle key *)
		Integer, 		(* writeConcern *)
		Integer, 		(* writeConcernTimeout *)
		Integer        (* ordered boole *) 
	}, 
	"Void"						
]	*)

(******************************************************************************)

(*Options[CreateCollectionBulkOperation] =
{
	"Ordered" -> False,
	"WriteConcern" -> "CPU",
	"Timeout" -> 0 (* integer in milliseconds *)
};

CreateCollectionBulkOperation[collection_MongoCollection, opts:OptionsPattern[]] := Module[
	{}
	,
	
	
]
*)

(******************************************************************************)

