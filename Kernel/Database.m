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

mongoDatabaseDrop = LibraryFunctionLoad[$MongoLinkLib, "WL_mongoc_database_drop", 
	{
		Integer			(* database handle *)
	}, 
	"Void"								
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoDatabaseObject"]

(* This is a utility function defined in GeneralUtilities, which makes a nicely
formatted display box *)
DefineCustomBoxes[MongoDatabaseObject, 
	e:MongoDatabaseObject[id_, name_, client_] :> Block[{},
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

MongoDatabaseObject[id_, name_, client_][collname_String] := 
	MongoGetCollection[MongoDatabaseObject[id, name, client], collname]

PackageExport["MongoDatabaseName"]
MongoDatabaseName[MongoDatabaseObject[_, name_, _]] := name;
MongoDatabaseName[___] := $Failed

PackageExport["MongoDatabaseHandle"]
MongoDatabaseHandle[MongoDatabaseObject[id_, _, _]] := id;
MongoDatabaseHandle[___] := $Failed

(*----------------------------------------------------------------------------*)
PackageExport[MongoGetDatabase]

SetUsage[MongoGetDatabase,
"DatabaseConnect[MongoClientObject[$$], databaseName$] connects to a database \
databaseName$ part of the client MongoClientObject[$$]. Equivalent to \
MongoClientObject[$$][databaseName$]."
]

MongoGetDatabase[MongoClientObject[client_], databaseName_String] := Catch @ Module[
	{databaseHandle, result},
	databaseHandle = CreateManagedLibraryExpression["MongoDatabase", MongoDatabase];
	result = safeLibraryInvoke[databaseHandleCreate,
		ManagedLibraryExpressionID[client], 
		ManagedLibraryExpressionID[databaseHandle],
		databaseName
	];
	MongoDatabaseObject[databaseHandle, databaseName, MongoClientObject[client]]
]

(*----------------------------------------------------------------------------*)
PackageExport[MongoCollectionNames]

SetUsage[MongoCollectionNames,
"DatabaseConnect[MongoDatabaseObject[$$]] gets a list of all the \
collection names in the database MongoDatabaseObject[$$]. 
"
]

MongoCollectionNames[MongoDatabaseObject[_, _, database_]] := 
	Catch @ safeLibraryInvoke[getCollectionNames, ManagedLibraryExpressionID[database]];

(*----------------------------------------------------------------------------*)
PackageExport[MongoCreateCollection]

SetUsage[MongoCreateCollection,
"MongoCreateCollection[MongoDatabaseObject[$$], collectionName$] creates a new \
collection with name collectionName$ inside the database MongoDatabaseObject[$$]. 
"
]

Options[MongoCreateCollection] =
{
	"Options" -> <||>
};

MongoCreateCollection[db_MongoDatabaseObject, 
	collectionName_String, opts:OptionsPattern[]] := Catch @ Module[
	{result, options, collection},
	
	options = BSONCreate @ OptionValue["Options"];
	collection = CreateManagedLibraryExpression["MongoCollection", MongoCollection];
	result = safeLibraryInvoke[databaseCreateCollection,
		ManagedLibraryExpressionID[First @ db],
		collectionName,
		ManagedLibraryExpressionID[First @ options],
		ManagedLibraryExpressionID[collection]
	];
	MongoCollectionObject[collection, databaseName, collectionName, db]
]

(*----------------------------------------------------------------------------*)
PackageExport[MongoDatabaseDrop]

MongoDatabaseDrop[MongoDatabaseObject[handle_, _, _]] := Catch @ 
	safeLibraryInvoke[mongoDatabaseDrop, ManagedLibraryExpressionID[handle]];
