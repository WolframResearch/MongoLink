(*******************************************************************************

Client level functions

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]

PackageScope["clientMLE"] (* client ManagedLibraryExpression *)

(*----------------------------------------------------------------------------*)
(****** Load Library Functions ******)

clientHandleCreate = LibraryFunctionLoad[$MongoLinkLib, "WL_ClientHandleCreate", 
	{
		Integer,					(* client handle *)
		Integer						(* uri handle *)
	},
	"Void"						
]

clientSetSSL = LibraryFunctionLoad[$MongoLinkLib, "WL_ClientSetSSL", 
	{
		Integer,						(* handle key *)
		"UTF8String",					(* pem_file *)
		"UTF8String",					(* pem_pwd *)
		"UTF8String",					(* ca_file *)
		"UTF8String",					(* ca_dir *)
		"UTF8String",					(* crl_file *)
		True|False,						(* weak cert validation *)
		True|False						(* inv hostname *)
	}, 
	"Void"						
]

getDatabaseNames = LibraryFunctionLoad[$MongoLinkLib, "WL_GetDatabaseNames", 
	Automatic, LinkObject					
]

clientSimpleCommand = LibraryFunctionLoad[$MongoLinkLib, "WL_ClientSimpleCommand",
	{
		Integer,					(* client handle *)
		Integer,					(* command bson *)
		"UTF8String",				(* json *)
		Integer						(* out bson *)
	},
	"Void"
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoClient"]

(* This is a utility function defined in GeneralUtilities, which makes a nicely
formatted display box *)
DefineCustomBoxes[MongoClient, 
	e:MongoClient[clientMLE_] :> Block[{},
	BoxForm`ArrangeSummaryBox[
		MongoClient, e, None, 
		{BoxForm`SummaryItem[{"ID: ", getMLEID[clientMLE]}]},
		{},
		StandardForm
	]
]];

getMLE[MongoClient[clientMLE_]] := clientMLE;
getMLEID[MongoClient[clientMLE_]] := ManagedLibraryExpressionID[clientMLE];

MongoClient[clientMLE_][db_String] := 
	MongoGetDatabase[MongoClient[clientMLE], db]

MongoClient[clientMLE_][db_String, coll_String] := 
	CatchFailureAsMessage @ 
	MongoGetCollection[iMongoGetDatabase[MongoClient[clientMLE], db], coll]

MongoClient /: Length[c_MongoClient] := Module[
	{names = MongoGetDatabaseNames[c]},
	If[FailureQ[names], Return[names]];
	Length[names]
]

MongoClient /: Keys[c_MongoClient] := MongoGetDatabaseNames[c]

(*----------------------------------------------------------------------------*)
PackageExport["MongoConnect"]

(* Note: we over-ride the default values of the C driver for socketTimeoutMS,
	which is around 5 minutes. This can cause problems for long operations.
	We follow the official default of no timeout, which is also PyMongo defualt:
	https://docs.mongodb.com/manual/reference/connection-string/#connection-options
*)

$DefaultConnection = <|
	"port" -> 27017,
	"host" -> "localhost",
	"sockettimeoutms" -> -1, (* follow pymongo, never timeout *)
	"connecttimeoutms" -> 20000, (* follow pymongo *)
	"journal" -> True (* this is NOT default in pymongo. Seems safer though... *)
|>;

DeclareArgumentCount[MongoConnect, {0, 1}];
MongoConnect[connection_Association] := CatchFailureAsMessage @ Module[
	{
		replaceRules, con, uri, clientID, result,
		clientHandle = CreateManagedLibraryExpression["Client", clientMLE],
		password, username, cred,
		ssl, pemFile, caFile, crList, pemFilePassword, verifyCert, test
	},
	(* conform WL names to native mongo names *)
	replaceRules = {
		VerifySecurityCertificates -> "sslallowinvalidcertificates",
		"AllowInvalidHostname" -> "sslallowinvalidhostnames",
		"CAFile" -> "sslcertificateauthorityfile",
		"PEMFile" -> "sslclientcertificatekeyfile",
		"PEMFilePassword" -> "sslclientcertificatekeypassword"
	};
	con = processOpts[connection, $DefaultConnection, replaceRules];

	(* special handling for passwords *)
	{password, username} = Lookup[con, {"password", "username"}, None];
	If[password === "$Prompt",
		cred = AuthenticationDialog["UsernamePassword" -> {"Username" -> username}];
		If[Head[cred] =!= Association,
			Message[OpenMongoConnection::authcancel];
			Return[$Failed]
		];
		{username, password} = Lookup[cred, {"Username", "Password"}];
		con = Join[con, <|"password" -> password, "username" -> username|>];
	];

	(* pop ssl opts: handle separately *)
	ssl = popAssociation[con, "ssl", Automatic];
	verifyCert = popAssociation[con, "sslallowinvalidcertificates", True];
	invHost = popAssociation[con, "sslallowinvalidhostnames", False];
	{pemFile, caFile, crList} = fileConform /@ 
		popAssociation[con, 
			{"sslclientcertificatekeyfile", "sslcertificateauthorityfile", "certificaterevocationlist"}, 
			None
		];
	pemFilePassword = popAssociation[con, "sslclientcertificatekeypassword", ""];

	(* construct URI *)
	uri = uriConstruct[con];

	clientID = getMLEID[clientHandle];
	result = safeLibraryInvoke[clientHandleCreate, clientID, getMLEID[uri]];

	(***** SSL Opts ******)
	(* See http://mongoc.org/libmongoc/current/mongoc_ssl_opt_t.html for 
		this issue *)
	If[($OperatingSystem === "Windows") && (pemFilePassword =!= None),
		Message[OpenMongoConnection::winpem];
		Return[$Failed]
	];
	If[(ssl =!= False) && ((pemFile =!= "") || (caFile =!= "") || (crList =!= "")),
		 safeLibraryInvoke[clientSetSSL, 
		 	clientID,
		 	pemFile,
		 	pemFilePassword,
		 	caFile,
		 	"", (* ca_dir: not going to support *)
		 	crList,
		 	verifyCert,
		 	invHost
		 ]
	];

	(* check whether connected *)
	test = 
		mongoClientCommandSimple[MongoClient[clientHandle], <|"ping" -> 1|>, "admin"];
	If[!AssociationQ[test], Return@$Failed];
	If[Round@Lookup[test, "ok", Return[$Failed]] =!= 1, Return[$Failed]];

	(* return client object *)
	System`Private`SetNoEntry @ MongoClient[clientHandle]

]

(* conformization *)
MongoConnect[] := MongoConnect[<||>]
MongoConnect[uri_String] := MongoConnect[<|"host" -> uri|>]
MongoConnect[MongoURI[uri_, _]] := MongoConnect[<|"host" -> uri|>]

MongoConnect::invargs = "MongoConnect expects either a String or an Association, `` was given."
MongoConnect[x_] := (Message[MongoConnect::invargs, x]; $Failed)


(*----------------------------------------------------------------------------*)
PackageExport["MongoGetDatabaseNames"]

SetUsage[MongoGetDatabaseNames,
"MongoGetDatabaseNames[MongoClient[$$]] returns a list of databases on the \
connected server. 
"
]

MongoGetDatabaseNames[client_MongoClient] := 
	CatchFailureAsMessage @ safeLibraryInvoke[getDatabaseNames, getMLEID[client]]

DeclareArgumentCount[MongoGetDatabaseNames, 1];
MongoGetDatabaseNames::invargs = 
	"MongoGetDatabaseNames expects a MongoClient object, but `` was given."
MongoGetDatabaseNames[x_] := (Message[MongoGetDatabaseNames::invargs, x]; $Failed)

(*----------------------------------------------------------------------------*)
PackageScope["mongoClientCommandSimple"]

mongoClientCommandSimple[client_MongoClient, command_, database_] := Module[
	{comBSON = iToBSON[command], outBSON},
	outBSON = CreateManagedLibraryExpression["BSON", bsonMLE];
	safeLibraryInvoke[
		clientSimpleCommand, 
		getMLEID[client],
		getMLEID[comBSON],
		database,
		getMLEID[outBSON]
	];
	BSONToAssociation @ BSONObject[outBSON]
]
