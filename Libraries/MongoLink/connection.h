#ifndef CONNECTION_H_INCLUDED
#define CONNECTION_H_INCLUDED

#include <map>

#include <bcon.h>
#include <mongoc.h>
#include <bson.h>

#include "common.h"

#include "WolframLibrary.h"
#include "WolframRawArrayLibrary.h"

////////////////////////////////////////////////////////////////////////////////

DLLEXPORT void manage_instance_mongoclient(WolframLibraryData libData,
                                           mbool mode, mint id);

EXTERN_C DLLEXPORT int WL_ClientCreate(WolframLibraryData libData, mint Argc,
                                       MArgument *Args, MArgument Res);

DLLEXPORT void manage_instance_mongodatabase(WolframLibraryData libData,
                                             mbool mode, mint id);

EXTERN_C DLLEXPORT int WL_DatabaseHandleCreate(WolframLibraryData libData,
                                               mint Argc, MArgument *Args,
                                               MArgument Res);

DLLEXPORT void manage_instance_mongocollection(WolframLibraryData libData,
                                               mbool mode, mint id);

EXTERN_C DLLEXPORT int WL_CollectionHandleCreate(WolframLibraryData libData,
                                                 mint Argc, MArgument *Args,
                                                 MArgument Res);

////////////////////////////////////////////////////////////////////////////////

#endif
