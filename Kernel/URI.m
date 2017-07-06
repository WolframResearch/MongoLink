(*******************************************************************************

URI level functions

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]

(*----------------------------------------------------------------------------*)
(****** Load Library Functions ******)

uriCreateHostPort = LibraryFunctionLoad[$MongoLinkLib, "WL_URICreateHostPort", 
	{
		Integer,					(* uri handle *)
		"UTF8String",				(* host *)
		Integer						(* port *)
	}, 
	"Void"						
]

uriCreate = LibraryFunctionLoad[$MongoLinkLib, "WL_URICreate", 
	{
		Integer,					(* uri handle *)
		"UTF8String"				(* uri *)
	}, 
	"Void"						
]

uriGetString = LibraryFunctionLoad[$MongoLinkLib, "WL_URI_Get_String", 
	{
		Integer					(* uri handle *)
	}, 
	"UTF8String"						
]

(* URI Setting functions *)

uriSetUsername = LibraryFunctionLoad[$MongoLinkLib, "WL_uri_set_username", 
	{
		Integer,					(* uri handle *)
		"UTF8String"		
	}, 
	"Void"						
]

uriSetPassword = LibraryFunctionLoad[$MongoLinkLib, "WL_uri_set_password", 
	{
		Integer,					(* uri handle *)
		"UTF8String"		
	}, 
	"Void"						
]

uriSetAuthSource = LibraryFunctionLoad[$MongoLinkLib, "WL_uri_set_auth_source", 
	{
		Integer,					(* uri handle *)
		"UTF8String"		
	}, 
	"Void"						
]

uriSetDatabase = LibraryFunctionLoad[$MongoLinkLib, "WL_uri_set_database", 
	{
		Integer,					(* uri handle *)
		"UTF8String"		
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

MongoURIObject /: ToString[MongoURIObject[id_]] := uriGetString[ManagedLibraryExpressionID @ id]

(* This is a utility function defined in GeneralUtilities, which makes a nicely
formatted display box *)
DefineCustomBoxes[MongoURIObject, 
	e:MongoURIObject[id_] :> Block[{},
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

URIFromString[uri_String] := Module[
	{
		handle = CreateManagedLibraryExpression["MongoURI", MongoURI],
		res
	},
	res = uriCreate[ManagedLibraryExpressionID[handle], uri];
	If[LibraryFunctionFailureQ[res], 
		MongoFailureMessage[URIFromString]; 
		Return[$Failed]
	];
	MongoURIObject[handle]
]

(*----------------------------------------------------------------------------*)
(* internal Function *)
PackageExport["URIConstruct"]

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
]