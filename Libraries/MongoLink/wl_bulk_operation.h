#ifndef BULK_OPERATION_H_INCLUDED
#define BULK_OPERATION_H_INCLUDED

#include <map>
#include <iostream>

#include <bcon.h>
#include <mongoc.h>
#include <bson.h>

#include "wl_common.h"

////////////////////////////////////////////////////////////////////////////////

DLLEXPORT void manage_instance_mongobulkoperation(WolframLibraryData libData,
                                                  mbool mode, mint id);

EXTERN_C DLLEXPORT int WL_bulk_operation_insert(WolframLibraryData libData,
                                                mint Argc, MArgument *Args,
                                                MArgument Res);

EXTERN_C DLLEXPORT int
WL_mongoc_bulk_operation_execute(WolframLibraryData libData, mint Argc,
                                 MArgument *Args, MArgument Res);

////////////////////////////////////////////////////////////////////////////////

#endif
