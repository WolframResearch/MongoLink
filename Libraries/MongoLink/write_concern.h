#ifndef WRITECONCERN_H_INCLUDED
#define WRITECONCERN_H_INCLUDED

#include <map>
#include <iostream>

#include <bcon.h>
#include <mongoc.h>
#include <bson.h>

#include "common.h"

////////////////////////////////////////////////////////////////////////////////

DLLEXPORT void manage_instance_mongowriteconcern(WolframLibraryData libData,
                                                 mbool mode, mint id);

EXTERN_C DLLEXPORT int WL_WriteConcernSet(WolframLibraryData libData, mint Argc,
                                          MArgument *Args, MArgument Res);

EXTERN_C DLLEXPORT int WL_WriteConcernSetWtimeout(WolframLibraryData libData,
                                                  mint Argc, MArgument *Args,
                                                  MArgument Res);

EXTERN_C DLLEXPORT int WL_WriteConcernSetJournal(WolframLibraryData libData,
                                                 mint Argc, MArgument *Args,
                                                 MArgument Res);

EXTERN_C DLLEXPORT int WL_WriteConcernGetInfo(WolframLibraryData libData,
                                              MLINK mlp);

////////////////////////////////////////////////////////////////////////////////

#endif
