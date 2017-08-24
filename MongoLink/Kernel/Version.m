(*******************************************************************************

Version level functions

*******************************************************************************)


Package["MongoLink`"]

PackageImport["GeneralUtilities`"]


(*----------------------------------------------------------------------------*)
(****** Load Library Functions ******)

mongoGetVersion = LibraryFunctionLoad[$MongoLinkLib, "WL_MongoGetVersion",
	{
	},
	"UTF8String"
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoDriverVersion"]

MongoDriverVersion::usage = 
"MongoDriverVersion[] returns a string of the Mongo C Driver used by MongoLink.
"

MongoDriverVersion[] := mongoGetVersion[]