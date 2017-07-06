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
		"UTF8String"				(* connection info *)
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

MongoClientObject[id_][database_String] := DatabaseConnect[id, database]

(*----------------------------------------------------------------------------*)
PackageExport["ClientConnect"]

SetUsage[ClientConnect,
"
ClientConnect[MongoURIObject[$$]] connects to a client using the URI defined \
by the MongoURIObject[$$].
ClientConnect[host$, port$] connects to the host with string name host$ \
via the port port$.
ClientConnect[host$] is equivalent to ClientConnect[host$, 27017].
ClientConnect[] is equivalent to ClientConnect['localhost', 27017].

The following SSL configuration options are available:
|'SSL' | False | If True, connect to the server using SSL. |
|'SSLCertificateFile' | None | The certificate file used to identify the local \
connection against mongod. Implies 'SSL' is True.  |
|'SSLKeyFile' | None | If True, connect to the server using SSL |
|'SSLCertificateRequire' | True | Specifies whether a certificate is required \
from the other side of the connection. If True, implies 'SSL' is True. |
|'SSLPEMFilePassword' | None | The password or passphrase for decrypting the \
private key in 'SSLCertificateFile' or 'SSLKeyFile'. Only necessary if the private key is encrypted. |
|'SSLCertificateRevocationList' | None | The path to a PEM or DER formatted certificate revocation list. |
The following options are only available when a URI is not specified:
| 'Username' | None | The username to connect with. |
| 'Password' | None | The password to connect with. If you enter '$Prompt' as \
a password, a dialog box opens that will prompt you for the password. \
This helps keep the password more secure. |
Note: ClientConnect will not block, it will return immediately. Thus there is \
no guarantee of there being no server error if ClientConnect returns a ClientObject.
"
]

ClientConnect::pemfile = "PEM File not found.";
ClientConnect::cafile = "CA File not found.";

Options[ClientConnect] = {
	"Username" -> None,
	"Password" -> None,
	"SSL" -> False,
	"PEMFile" -> None,
	"PEMFilePassword" -> None,
	"CAFile" -> None,
	"CertificateRevocationList" -> None,	
	VerifySecurityCertificates -> True
};

ClientConnect[host_String, port_Integer, opts:OptionsPattern[]] := Module[
	{
		clientHandle, result,
		username = OptionValue["Username"],
		password = OptionValue["Password"],
		ssl = OptionValue["SSL"],
		pemFile = OptionValue["PEMFile"],
		pemFilePassword = OptionValue["PEMFilePassword"],
		caFile = OptionValue["CAFile"],
		crList = OptionValue["CertificateRevocationList"],
		verifyCert = OptionValue[VerifySecurityCertificates]
	},

	If[(pemFile =!= None) && !FileExistsQ[pemFile],
		Message[ClientConnect::pemfile];
		Return[$Failed];
	];
	If[(caFile =!= None) && !FileExistsQ[caFile],
		Message[ClientConnect::cafile];
		Return[$Failed];
	];

	If[password === "$Prompt",
		{username, password} = 
			DatabaseLink`UI`Private`PasswordDialog[{username, ""}]
	];




	clientHandle = CreateManagedLibraryExpression["MongoClient", MongoClient];
	result = clientHandleCreate[ManagedLibraryExpressionID[clientHandle], host];
	If[LibraryFunctionFailureQ[result], 
		MongoFailureMessage[ClientConnect]; 
		Return[$Failed]
	];
	MongoClientObject[clientHandle]
]

ClientConnect[host_String, opts:OptionsPattern[]] := 
	ClientConnect[host, 27017, opts]
	
ClientConnect[opts:OptionsPattern[]] := 
	ClientConnect["localhost", 27017, opts]

(* URI Client connect *)
ClientConnect[uri_MongoURIObject, opts:OptionsPattern[]] := Module[
	{},
	1
	
]


ClientConnect["localhost", 27017, opts]


(*----------------------------------------------------------------------------*)
PackageExport["ClientDatabaseNames"]

SetUsage[ClientDatabaseNames,
"ClientDatabaseNames[MongoClientObject[$$]] returns a list of databases on the \
connected server. 
"
]

ClientDatabaseNames[MongoClientObject[database_MongoClient]] := Module[
	{result},
	result = getDatabaseNames[ManagedLibraryExpressionID[database]];
	If[LibraryFunctionFailureQ[result], 
		MongoFailureMessage[ClientDatabaseNames]; 
		Return[$Failed]
	];
	result
]