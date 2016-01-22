#ifndef COMMON_H_INCLUDED
#define COMMON_H_INCLUDED

#include <map>
#include <iostream>

#include <bcon.h>
#include <mongoc.h>
#include <bson.h>

#include "WolframLibrary.h"
#include "WolframRawArrayLibrary.h"

////////////////////////////////////////////////////////////////////////////////

extern std::map<mint, mongoc_client_t *> clientHandleMap;
extern std::map<mint, mongoc_database_t *> databaseHandleMap;
extern std::map<mint, mongoc_collection_t *> collectionHandleMap;

extern std::map<mint, mongoc_bulk_operation_t *> bulkOperationHandleMap;

extern char *returnCharArray;
extern std::string errorString;

////////////////////////////////////////////////////////////////////////////////

EXTERN_C DLLEXPORT int WL_MongoGetLastError(WolframLibraryData libData,
                                            mint Argc, MArgument *Args,
                                            MArgument Res);

////////////////////////////////////////////////////////////////////////////////

#endif
