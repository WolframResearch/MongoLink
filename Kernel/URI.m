(*******************************************************************************

URI level functions

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]

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
PackageExport["MongoURIObject"]

SetUsage[MongoURIObject,
"MongoURIObject[$$] is a symbolic representation of a MongoDB URI.

The following operations are defined on the MongoURIObject object:
| ToString @ MongoURIObject[$$] | Converts MongoURIObject[$$] into its string representation. |
"
]

MongoURIObject /: ToString[MongoURIObject[id_, uri_]] := URLDecode[uri]

(* This is a utility function defined in GeneralUtilities, which makes a nicely
formatted display box *)
DefineCustomBoxes[MongoURIObject, 
	e:MongoURIObject[id_, uri_] :> Block[{},
	BoxForm`ArrangeSummaryBox[
		MongoURIObject, e, None, 
		{BoxForm`SummaryItem[{"ID: ", ManagedLibraryExpressionID[id]}]},
		{},
		StandardForm
	]
]];

(*----------------------------------------------------------------------------*)
PackageExport["URIFromString"]

(*SetUsage[URIFromString,
"URIFromString[uri$] creates a MongoURIObject[$$] from a uri$ string. 
"
]*)
URIFromString::inv = "Invalid URI."

URIFromString[uri_String] := Module[
	{
		handle = CreateManagedLibraryExpression["MongoURI", MongoURI],
		res
	},
	res = uriCreate[ManagedLibraryExpressionID[handle], uri];
	If[LibraryFunctionFailureQ[res], 
		Message[URIFromString::inv];
		Return[$Failed]
	];
	MongoURIObject[handle, uri]
]

(*----------------------------------------------------------------------------*)
(* internal Function *)
PackageExport["URIConstruct"]

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
	"Database" -> None
};

MongoURIConstruct[host_String, port_Integer, opts:OptionsPattern[]] := Module[
	{
		username = OptionValue["Username"],
		password = OptionValue["Password"],
		database = OptionValue["Database"],
		res, cred, uri
	},

	If[password === "$Prompt",
		{username, password} = 
			DatabaseLink`UI`Private`PasswordDialog[{username, ""}]
	];
	
	If[(username =!= None) && (password =!= None), 
		cred = StringJoin[URLEncode[username], ":", 
		URLEncode[password], "@"], cred = ""
		];
	If[database =!= None, 
		database = StringJoin["/", URLEncode[database]], 
		database = ""
		];	

	uri = StringJoin["mongodb://", cred, host, ":", ToString[port], database];
	If[LibraryFunctionFailureQ[res], 
		Return[$Failed]
	];	
	
	URIFromString[uri]
]

MongoURIConstruct[host_String, opts:OptionsPattern[]] := 
	MongoURIConstruct[host, 27017, opts]

MongoURIConstruct[opts:OptionsPattern[]] := 
	MongoURIConstruct["localhost", 27017, opts]

(*----------------------------------------------------------------------------*)
(* internal Function *)
(*PackageExport["URIConstruct"]

Options[URIConstruct] = {
	"Username" -> None,
	"Password" -> None,
	"Database" -> None
};

URIConstruct[host_String, port_Integer, opts:OptionsPattern[]] := Module[
	{
		username = OptionValue["Username"],
		password = OptionValue["Password"],
		database = OptionValue["Database"],
		handle = CreateManagedLibraryExpression["MongoURI", MongoURI],
		id, res
	},
	id = ManagedLibraryExpressionID[handle];
	res = uriCreateHostPort[ManagedLibraryExpressionID[handle], host, port];
	If[LibraryFunctionFailureQ[res], 
		Return[$Failed]
	];
	
	If[username =!= None, uriSetUsername[id, username]];
	If[password =!= None, uriSetPassword[id, password]];
	If[database =!= None, uriSetDatabase[id, database]];	
	
	MongoURIObject[handle]
]*)