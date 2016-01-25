#ifndef COLLECTION_H_INCLUDED
#define COLLECTION_H_INCLUDED

#include <map>
#include <iostream>

#include <bcon.h>
#include <mongoc.h>
#include <bson.h>

#include "wl_common.h"
// #include "client.h"

////////////////////////////////////////////////////////////////////////////////

DLLEXPORT void manage_instance_mongocollection(WolframLibraryData libData,
                                               mbool mode, mint id);

EXTERN_C DLLEXPORT int WL_CollectionGetName(WolframLibraryData libData,
                                            mint Argc, MArgument *Args,
                                            MArgument Res);

EXTERN_C DLLEXPORT int WL_CollectionHandleCreate(WolframLibraryData libData,
                                                 mint Argc, MArgument *Args,
                                                 MArgument Res);

EXTERN_C DLLEXPORT int WL_MongoCollectionCount(WolframLibraryData libData,
                                               mint Argc, MArgument *Args,
                                               MArgument Res);

EXTERN_C DLLEXPORT int WL_MongoCollectionFind(WolframLibraryData libData,
                                              mint Argc, MArgument *Args,
                                              MArgument Res);

////////////////////////////////////////////////////////////////////////////////

#endif
