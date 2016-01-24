#ifndef COLLECTION_H_INCLUDED
#define COLLECTION_H_INCLUDED

#include <map>
#include <iostream>

#include <bcon.h>
#include <mongoc.h>
#include <bson.h>

#include "common.h"

////////////////////////////////////////////////////////////////////////////////

EXTERN_C DLLEXPORT int WL_MongoCollectionCount(WolframLibraryData libData,
                                               mint Argc, MArgument *Args,
                                               MArgument Res);

////////////////////////////////////////////////////////////////////////////////

#endif
