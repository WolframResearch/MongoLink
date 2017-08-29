(*******************************************************************************

Database level functions

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]

PackageScope["databaseMLE"] (* database ManagedLibraryExpression *)

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
PackageExport["MongoDatabase"]

(* This is a utility function defined in GeneralUtilities, which makes a nicely
formatted display box *)
DefineCustomBoxes[MongoDatabase, 
	e:MongoDatabase[dbMLE_, name_, client_] :> Block[{},
	BoxForm`ArrangeSummaryBox[
		MongoDatabase, e, None, 
		{
			BoxForm`SummaryItem[{"ID: ", ManagedLibraryExpressionID[dbMLE]}],
			BoxForm`SummaryItem[{"Name: ", name}]
		},
		{},
		StandardForm
	]
]];

getClient[MongoDatabase[__, client_]] := client
getMLE[MongoDatabase[dbMLE_, __]] := dbMLE;
getMLEID[MongoDatabase[dbMLE_, __]] := ManagedLibraryExpressionID[dbMLE];

(* connect to collection syntactic sugar *)
MongoDatabase[dbMLE_, name_, clientMLE_][collname_String] := 
	MongoGetCollection[MongoDatabase[dbMLE, name, clientMLE], collname]

PackageExport["MongoDatabaseName"]
MongoDatabaseName[MongoDatabase[_, name_, _]] := name;
MongoDatabaseName[___] := $Failed

(*----------------------------------------------------------------------------*)
PackageExport[MongoGetDatabase]

MongoGetDatabase[client_MongoClient, databaseName_String] := 
CatchFailureAsMessage @ Module[
	{dbMLE, result},
	dbMLE = CreateManagedLibraryExpression["Database", databaseMLE];
	result = safeLibraryInvoke[databaseHandleCreate,
		getMLEID[client], 
		ManagedLibraryExpressionID[dbMLE],
		databaseName
	];
	System`Private`SetNoEntry @ 
		MongoDatabase[dbMLE, databaseName, client]
]

(*----------------------------------------------------------------------------*)
PackageExport[MongoCollectionNames]

MongoCollectionNames[db_MongoDatabase] := CatchFailureAsMessage @
	safeLibraryInvoke[getCollectionNames, getMLEID @ db]

(*----------------------------------------------------------------------------*)
PackageExport[MongoCreateCollection]

Options[MongoCreateCollection] =
{
	"Options" -> <||>
};

MongoCreateCollection[db_MongoDatabase, collName_String, 
	opts:OptionsPattern[]] := CatchFailureAsMessage @ Module[
	{result, options, collHandle},
	
	options = iToBSON[OptionValue["Options"]];
	collHandle = CreateManagedLibraryExpression["Collection", collectionMLE];
	result = safeLibraryInvoke[databaseCreateCollection,
		getMLEID[db],
		collName,
		getMLEID[options],
		ManagedLibraryExpressionID[collHandle]
	];
	MongoCollection[collHandle, MongoDatabaseName[db], collName, client]
]

(*----------------------------------------------------------------------------*)
PackageExport[MongoDatabaseDrop]

MongoDatabaseDrop[db_MongoDatabase] := CatchFailureAsMessage @ 
	safeLibraryInvoke[mongoDatabaseDrop, getMLEID[db]];
