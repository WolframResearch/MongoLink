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
		uri = StringJoin[uri, "?ssl=true"],
		uri = StringJoin[uri, "?ssl=false"]
	];
	MongoURIFromString[uri]
]

MongoURIConstruct[host_String, opts:OptionsPattern[]] := 
	MongoURIConstruct[host, 27017, opts]

MongoURIConstruct[opts:OptionsPattern[]] := 
	MongoURIConstruct["localhost", 27017, opts]
