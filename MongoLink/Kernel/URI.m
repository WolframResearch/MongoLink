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

uriSetOptionInt32 = LibraryFunctionLoad[$MongoLinkLib, "WL_URISetOptionInt32", 
	{
		Integer,					(* uri handle *)
		"UTF8String",				(* name *)
		Integer 					(* value *)
	}, 
	"Void"
]

uriSetOptionBool = LibraryFunctionLoad[$MongoLinkLib, "WL_URISetOptionBool", 
	{
		Integer,					(* uri handle *)
		"UTF8String",				(* name *)
		True|False 					(* value *)
	}, 
	"Void"
]

uriSetOptionUFT8 = LibraryFunctionLoad[$MongoLinkLib, "WL_URISetOptionUTF8", 
	{
		Integer,					(* uri handle *)
		"UTF8String",				(* name *)
		"UTF8String" 				(* value *)
	}, 
	"Void"
]

uriGetString = LibraryFunctionLoad[$MongoLinkLib, "WL_URIGetString", 
	{
		Integer						(* uri handle *)
	}, 
	"UTF8String"
]

uriSetPropEnum = LibraryFunctionLoad[$MongoLinkLib, "WL_URISetPropEnum", 
	{
		Integer,					(* uri handle *)
		"UTF8String",				(* value *)
		Integer 					(* selector *)
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
getMLEID[MongoURI[uriMLE_, __]] := ManagedLibraryExpressionID[uriMLE];

MongoURI /: ToString[x_MongoURI] := 
	CatchFailureAsMessage @ safeLibraryInvoke[uriGetString, getMLEID @ x]

(*----------------------------------------------------------------------------*)
PackageScope["uriFromString"]

uriFromString[uri_String] := Module[
	{
		handle = CreateManagedLibraryExpression["URI", uriMLE],
		res
	},
	res = safeLibraryInvoke[uriCreate, getMLEID[handle], uri];
	System`Private`SetNoEntry @ MongoURI[handle, uri]
]

(*----------------------------------------------------------------------------*)
PackageScope["uriConstruct"]

setprop[func_, uri_, opts_, val1_, val2_] := 
	If[KeyExistsQ[opts, val1], safeLibraryInvoke[func, getMLEID@uri, opts[val1], val2]];

uriConstruct[connection_String, opts_Association] := Module[
	{uri, opts2},
	uri = uriFromString[connection];

	(** Authentication **)
	setprop[uriSetPropEnum, uri, opts, "authmechanism", 1];
	setprop[uriSetPropEnum, uri, opts, "authsource", 2];
	setprop[uriSetPropEnum, uri, opts, "password", 5];
	setprop[uriSetPropEnum, uri, opts, "username", 6];

	(** Compress **)
	setprop[uriSetPropEnum, uri, opts, "compressors", 3];

	(** Other **)
	opts2 = KeyDrop[opts, {"authmechanism", "authsource", "password", "username", "compressors"}];
	KeyValueMap[uriSetOption[uri, #1, #2]&, opts2];
	uri
]

(*----------------------------------------------------------------------------*)
PackageScope["uriSetOption"]

uriSetOption::invtype = "Invalid type. Only String, Integer or boolean types supported."

uriSetOption[uri_MongoURI, name_String, val_Integer] := 
	safeLibraryInvoke[uriSetOptionInt32, getMLEID @ uri, name, val]

uriSetOption[uri_MongoURI, name_String, val_String] := 
	safeLibraryInvoke[uriSetOptionUFT8, getMLEID @ uri, name, val] 

uriSetOption[uri_MongoURI, name_String, val_ /; BooleanQ[val]] := 
	safeLibraryInvoke[uriSetOptionBool, getMLEID @ uri, name, val] 

uriSetOption[___] := ThrowFailure[uriSetOption::invtype]
