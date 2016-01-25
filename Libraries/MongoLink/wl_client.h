#ifndef CLIENT_H_INCLUDED
#define CLIENT_H_INCLUDED

#include <map>
#include <iostream>

#include <bcon.h>
#include <mongoc.h>
#include <bson.h>

#include "wl_common.h"

////////////////////////////////////////////////////////////////////////////////

DLLEXPORT void manage_instance_mongoclient(WolframLibraryData libData,
                                           mbool mode, mint id);

EXTERN_C DLLEXPORT int WL_ClientHandleCreate(WolframLibraryData libData,
                                             mint Argc, MArgument *Args,
                                             MArgument Res);

////////////////////////////////////////////////////////////////////////////////

#endif
