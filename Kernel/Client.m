(*******************************************************************************

Client level functions

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]
PackageImport["DatabaseLink`"]

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
		Integer,						(* weak cert validation *)
		Integer							(* inv hostname *)
	}, 
	"Void"						
]

getDatabaseNames = LibraryFunctionLoad[$MongoLinkLib, "WL_GetDatabaseNames", 
	Automatic, LinkObject					
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoClientObject"]

(* This is a utility function defined in GeneralUtilities, which makes a nicely
formatted display box *)
DefineCustomBoxes[MongoClientObject, 
	e:MongoClientObject[id_] :> Block[{},
	BoxForm`ArrangeSummaryBox[
		MongoClientObject, e, None, 
		{BoxForm`SummaryItem[{"ID: ", ManagedLibraryExpressionID[id]}]},
		{},
		StandardForm
	]
]];

MongoClientObject[id_][database_String] := MongoGetDatabase[MongoClientObject[id], database]

(*----------------------------------------------------------------------------*)
PackageExport["MongoClientConnect"]

MongoClientConnect::winpem = "Support for encrypted PEM files requiring \
a PemFilePassword is not available on Windows."

Options[MongoClientConnect] = {
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
MongoClientConnect[MongoURIObject[uri_, _], opts:OptionsPattern[]] := 
	CatchFailureAsMessage @ Module[
	{
		ssl = OptionValue["SSL"],
		pemFile = fileConform @ OptionValue["PEMFile"],
		pemFilePassword = OptionValue["PEMFilePassword"],
		caFile = fileConform @ OptionValue["CAFile"],
		crList = fileConform @ OptionValue["CertificateRevocationList"],
		verifyCert = OptionValue[VerifySecurityCertificates],
		invHost = OptionValue["AllowInvalidHostname"],
		clientHandle = CreateManagedLibraryExpression["MongoClient", MongoClient],
		clientID, result
	},
	clientID = ManagedLibraryExpressionID[clientHandle];
	result = safeLibraryInvoke[clientHandleCreate, clientID, ManagedLibraryExpressionID[uri]];
	(***** SSL Opts ******)
	(* See http://mongoc.org/libmongoc/current/mongoc_ssl_opt_t.html for 
		this issue *)
	If[($OperatingSystem === "Windows") && (pemFilePassword =!= None),
		Message[MongoClientConnect::winpem];
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
		 	Boole[verifyCert],
		 	Boole[invHost]
		 ]
	];
	
	(* return client object *)
	MongoClientObject[clientHandle]
]

MongoClientConnect[host_String, port_Integer, opts:OptionsPattern[]] := Module[
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
	MongoClientConnect[uri, opts]
]

MongoClientConnect[host_String, opts:OptionsPattern[]] := 
	MongoClientConnect[host, 27017, opts]
	
MongoClientConnect[opts:OptionsPattern[]] := 
	MongoClientConnect["localhost", 27017, opts]

(*----------------------------------------------------------------------------*)
PackageExport["MongoDatabaseNames"]

SetUsage[MongoDatabaseNames,
"MongoDatabaseNames[MongoClientObject[$$]] returns a list of databases on the \
connected server. 
"
]

MongoDatabaseNames[MongoClientObject[database_MongoClient]] := 
	CatchFailureAsMessage @ safeLibraryInvoke[getDatabaseNames, ManagedLibraryExpressionID[database]]