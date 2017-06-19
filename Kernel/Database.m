(*******************************************************************************

Database level functions

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]


(*----------------------------------------------------------------------------*)
(****** Load Library Functions ******)

databaseHandleCreate = LibraryFunctionLoad[$MongoLinkLib, "WL_DatabaseHandleCreate", 
	{
		Integer,					(* client handle *)
		Integer,					(* database handle *)
		"UTF8String"				(* database name *)

	}, 
	"Void"						
]	

getCollectionNames = LibraryFunctionLoad[$MongoLinkLib, "WL_GetCollectionNames", 
	Automatic, LinkObject					
]	

mongoDatabaseName = LibraryFunctionLoad[$MongoLinkLib, "WL_DatabaseGetName", 
	{
		Integer			(* collection handle *)
	}, 
	"UTF8String"		(* name *)						
]

databaseCreateCollection = LibraryFunctionLoad[$MongoLinkLib, "WL_DatabaseCreateCollection", 
	{
		Integer,			(* database handle *)
		"UTF8String",		(* collection handle *)
		Integer,			(* bson handle *)
		Integer				(* collection handle *)
	}, 
	"Void"					
]	

(*----------------------------------------------------------------------------*)
PackageExport["MongoDatabaseObject"]

(* This is a utility function defined in GeneralUtilities, which makes a nicely
formatted display box *)
DefineCustomBoxes[MongoDatabaseObject, 
	e:MongoDatabaseObject[id_, name_] :> Block[{},
	BoxForm`ArrangeSummaryBox[
		MongoDatabaseObject, e, None, 
		{
			BoxForm`SummaryItem[{"ID: ", ManagedLibraryExpressionID[id]}],
			BoxForm`SummaryItem[{"Name: ", name}]
		},
		{},
		StandardForm
	]
]];

MongoDatabaseObject[_, name_]["Name"] := name
MongoDatabaseObject[id_, _]["ID"] := ManagedLibraryExpressionID[id]

(*----------------------------------------------------------------------------*)
PackageExport[DatabaseConnect]

SetUsage[DatabaseConnect,
"DatabaseConnect[MongoClientObject[$$], databaseName$] connects to a database \
databaseName$ part of the client MongoClientObject[$$]. Equivalent to \
MongoClientObject[$$][databaseName$]."
]

DatabaseConnect[client_, databaseName_String] := Module[
	{databaseHandle, result},
	databaseHandle = CreateManagedLibraryExpression["MongoDatabase", MongoDatabase];
	result = databaseHandleCreate[
		ManagedLibraryExpressionID[client], 
		ManagedLibraryExpressionID[databaseHandle],
		databaseName
	];
	If[LibraryFunctionFailureQ[result], 
		MongoFailureMessage[DatabaseConnect]; 
		Return[$Failed]
	];
	MongoDatabaseObject[databaseHandle, databaseName]
]

DatabaseConnect[MongoClientObject[client_], databaseName_String] := 
	DatabaseConnect[client, databaseName] 

(*----------------------------------------------------------------------------*)
PackageExport[DatabaseCollectionNames]

SetUsage[DatabaseCollectionNames,
"DatabaseConnect[MongoDatabaseObject[$$]] gets a list of all the \
collection names in the database MongoDatabaseObject[$$]. 
"
]

DatabaseCollectionNames[MongoDatabaseObject[database_, _]] := Module[
	{result},
	result = getCollectionNames[ManagedLibraryExpressionID[database]];
	If[LibraryFunctionFailureQ[result], 
		MongoFailureMessage[DatabaseCollectionNames]; 
		Return[$Failed]
	];
	result
]

(*----------------------------------------------------------------------------*)
PackageExport[DatabaseCreateCollection]

SetUsage[DatabaseCreateCollection,
"DatabaseCreateCollection[MongoDatabaseObject[$$], collectionName$] creates a new \
collection with name collectionName$ inside the database MongoDatabaseObject[$$]. 
"
]

Options[DatabaseCreateCollection] =
{
	"Options" -> <||>
};

DatabaseCreateCollection[MongoDatabaseObject[database_, _], collectionName_String, opts:OptionsPattern[]] := Module[
	{result, options, collection},
	
	options = BSONCreate[OptionValue@"Options"];
	collection = CreateManagedLibraryExpression["MongoCollection", MongoCollection];
	result = databaseCreateCollection[
		ManagedLibraryExpressionID@database,
		collectionName,
		ManagedLibraryExpressionID@options,
		ManagedLibraryExpressionID@collection
	];
	If[LibraryFunctionFailureQ[result], 
		MongoFailureMessage[DatabaseCreateCollection]; 
		Return[$Failed]
	];
	collection
]

