#ifndef BSON_H_INCLUDED
#define BSON_H_INCLUDED

#include <map>
#include <iostream>

#include <bcon.h>
#include <mongoc.h>
#include <bson.h>

#include "common.h"

////////////////////////////////////////////////////////////////////////////////

DLLEXPORT void manage_instance_mongobson(WolframLibraryData libData, mbool mode,
                                         mint id);

EXTERN_C DLLEXPORT int WL_CreateBSONfromJSON(WolframLibraryData libData,
                                             mint Argc, MArgument *Args,
                                             MArgument Res);

EXTERN_C DLLEXPORT int WL_bsonAsJSON(WolframLibraryData libData, mint Argc,
                                     MArgument *Args, MArgument Res);

////////////////////////////////////////////////////////////////////////////////

#endif
