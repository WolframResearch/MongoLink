(*******************************************************************************

URI level functions

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]

PackageScope["uriMLE"] (* URI ManagedLibraryExpression *)

(*----------------------------------------------------------------------------*)
(****** Load Library Functions ******)

uriCreate = LibraryFunctionLoad[$MongoLinkLib, "WL_URICreate", 
	{
		Integer,					(* uri handle *)
		"UTF8String"				(* uri *)
	}, 
	"Void"
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoURI"]

SetUsage[MongoURI,
"MongoURI[$$] is a symbolic representation of a MongoDB URI.

The following operations are defined on the MongoURI object:
| ToString @ MongoURI[$$] | Converts MongoURI[$$] into its string representation. |
"
]

MongoURI /: ToString[MongoURI[uriMLE_, uri_String]] := URLDecode[uri]

(* This is a utility function defined in GeneralUtilities, which makes a nicely
formatted display box *)
DefineCustomBoxes[MongoURI, 
	e:MongoURI[uriMLE_, uri_String] :> Block[{},
	BoxForm`ArrangeSummaryBox[
		MongoURI, e, None,
		{BoxForm`SummaryItem[{"ID: ", ManagedLibraryExpressionID[uriMLE]}]},
		{},
		StandardForm
	]
]];

getMLE[MongoURI[uriMLE_, __]] := uriMLE;
getMLEID[MongoCollection[uriMLE_, __]] := ManagedLibraryExpressionID[uriMLE];

(*----------------------------------------------------------------------------*)
PackageExport["MongoURIFromString"]

(*SetUsage[URIFromString,
"URIFromString[uri$] creates a MongoURI[$$] from a uri$ string. 
"
]*)
MongoURIFromString::inv = "Invalid URI."

MongoURIFromString[uri_String] := CatchFailureAsMessage @ Module[
	{
		handle = CreateManagedLibraryExpression["URI", uriMLE],
		res
	},
	res = safeLibraryInvoke[uriCreate, ManagedLibraryExpressionID[handle], uri];
	System`Private`SetNoEntry @ MongoURI[handle, uri]
]

(*----------------------------------------------------------------------------*)
(* internal Function *)
PackageExport["MongoURIConstruct"]

SetUsage[MongoURIConstruct,"
MongoURIConstruct[host$, port$] creates a URI string using string name host$ \
and port port$.
MongoURIConstruct[host$] is equivalent to MongoURIConstruct[host$, 27017].
MongoURIConstruct[] is equivalent to MongoURIConstruct['localhost', 27017].

The following options are available:
| 'Username' | None | The username to connect to MongoDB database. \
Username will be ignored if no password option is supplied. |
| 'Password' | None | The password to connect to MongoDB database. \
Password will be ignored if no username option is supplied. \
If you enter '$Prompt' as a password, \
a dialog box opens that will prompt you for the password. |
| 'Database' | None | The name of the MongoDB database.|
"
]

Options[MongoURIConstruct] = {
	"Username" -> None,
	"Password" -> None,
	"Database" -> None,
	"SSL" -> Automatic
};

MongoURIConstruct[host_String, port_Integer, opts:OptionsPattern[]] := Module[
	{
		username = OptionValue["Username"],
		password = OptionValue["Password"],
		database = OptionValue["Database"],
		ssl = OptionValue["SSL"],
		cred, uri
	},

	If[password === "$Prompt",
		{username, password} = 
			DatabaseLink`UI`Private`PasswordDialog[{username, ""}]
	];
	
	If[(username =!= None) && (password =!= None), 
		cred = StringJoin[URLEncode[username], ":", URLEncode[password], "@"], 
		cred = ""
	];
	If[database =!= None, 
		database = StringJoin["/", URLEncode[database]], 
		database = ""
	];

	uri = StringJoin["mongodb://", cred, host, ":", ToString[port], database];
	
	(* ssl options: add to URI if True or False, but not Automatic *)
	If[ssl,
		uri = StringJoin[uri, "/?ssl=true"],
		uri = StringJoin[uri, "/?ssl=false"]
	];
	
	MongoURIFromString[uri]
]

MongoURIConstruct[host_String, opts:OptionsPattern[]] := 
	MongoURIConstruct[host, 27017, opts]

MongoURIConstruct[opts:OptionsPattern[]] := 
	MongoURIConstruct["localhost", 27017, opts]
