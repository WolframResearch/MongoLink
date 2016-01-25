#ifndef WL_CLIENT_H_INCLUDED
#define WL_CLIENT_H_INCLUDED

#include <map>
#include <iostream>

#include <bcon.h>
#include <mongoc.h>
#include <bson.h>

#include "wl_common.h"
#include "wl_client.h"

////////////////////////////////////////////////////////////////////////////////

extern DLLEXPORT void manage_instance_mongodatabase(WolframLibraryData libData,
                                                    mbool mode, mint id);

EXTERN_C DLLEXPORT int WL_DatabaseHandleCreate(WolframLibraryData libData,
                                               mint Argc, MArgument *Args,
                                               MArgument Res);

EXTERN_C DLLEXPORT int WL_GetCollectionNames(WolframLibraryData libData,
                                             MLINK mlp);
////////////////////////////////////////////////////////////////////////////////

#endif
