(*******************************************************************************

Client level functions

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]
PackageImport["DatabaseLink`"]

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
	MongoClientGetDatabase[MongoClient[clientMLE], db]

(*----------------------------------------------------------------------------*)
PackageExport["OpenMongoConnection"]

OpenMongoConnection::winpem = "Support for encrypted PEM files requiring \
a PemFilePassword is not available on Windows."

Options[OpenMongoConnection] = {
	"Username" -> None,
	"Password" -> None,
	"SSL" -> Automatic,
	"PEMFile" -> None,
	"PEMFilePassword" -> None,
	"CAFile" -> None,
	"CertificateRevocationList" -> None,	
	VerifySecurityCertificates -> True,
	"AllowInvalidHostname" -> False
};

(* URI Client connect *)
OpenMongoConnection[MongoURI[uri_, _], opts:OptionsPattern[]] := 
	CatchFailureAsMessage @ Module[
	{
		ssl = OptionValue["SSL"],
		pemFile = fileConform @ OptionValue["PEMFile"],
		pemFilePassword = OptionValue["PEMFilePassword"],
		caFile = fileConform @ OptionValue["CAFile"],
		crList = fileConform @ OptionValue["CertificateRevocationList"],
		verifyCert = OptionValue[VerifySecurityCertificates],
		invHost = OptionValue["AllowInvalidHostname"],
		clientHandle = CreateManagedLibraryExpression["Client", clientMLE],
		clientID, result
	},
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
		 	Replace[pemFilePassword, None -> ""],
		 	caFile,
		 	"", (* ca_dir: not going to support *)
		 	crList,
		 	verifyCert,
		 	invHost
		 ]
	];
	
	(* return client object *)
	System`Private`SetNoEntry @ MongoClient[clientHandle]
]

OpenMongoConnection[host_String, port_Integer, opts:OptionsPattern[]] := Module[
	{
		username = OptionValue["Username"],
		password = OptionValue["Password"],
		uri
	},
	If[password === "$Prompt",
		{username, password} = 
			DatabaseLink`UI`Private`PasswordDialog[{username, ""}]
	];
	
	(* this should never fail *)
	uri = MongoURIConstruct[host, port, "Username" -> username, "Password" -> password];
	OpenMongoConnection[uri, opts]
]

OpenMongoConnection[host_String, opts:OptionsPattern[]] := 
	OpenMongoConnection[host, 27017, opts]

OpenMongoConnection[opts:OptionsPattern[]] := 
	OpenMongoConnection["localhost", 27017, opts]

(*----------------------------------------------------------------------------*)
PackageExport["MongoClientGetDatabaseNames"]

SetUsage[MongoClientGetDatabaseNames,
"MongoClientGetDatabaseNames[MongoClient[$$]] returns a list of databases on the \
connected server. 
"
]

MongoClientGetDatabaseNames[client_MongoClient] := 
	CatchFailureAsMessage @ safeLibraryInvoke[getDatabaseNames, getMLEID[client]]