#ifndef COMMON_H_INCLUDED
#define COMMON_H_INCLUDED

#include <assert.h>
#include <stdio.h>

#include <map>
#include <iostream>

#include <bcon.h>
#include <bson.h>
#include <mongoc.h>
#include <bson.h>

#include "mathlink.h"
#include "WolframLibrary.h"

////////////////////////////////////////////////////////////////////////////////

void WLPrint(const char *fmstr, ...);
void EnableLogging(WolframLibraryData libData);

#define z1 std::cout << 1 << std::endl;
#define z2 std::cout << 2 << std::endl;
#define z3 std::cout << 3 << std::endl;
#define z4 std::cout << 4 << std::endl;
#define z5 std::cout << 5 << std::endl;
#define z6 std::cout << 6 << std::endl;

extern std::map<mint, mongoc_uri_t *> uriHandleMap;
extern std::map<mint, mongoc_client_t *> clientHandleMap;
extern std::map<mint, mongoc_database_t *> databaseHandleMap;
extern std::map<mint, mongoc_collection_t *> collectionHandleMap;
extern std::map<mint, mongoc_cursor_t *> iteratorHandleMap;
extern std::map<mint, mongoc_bulk_operation_t *> bulkOperationHandleMap;
extern std::map<mint, mongoc_write_concern_t *> writeConcernHandleMap;
extern std::map<mint, bson_t *> bsonHandleMap;

extern char *returnCharArray;
extern char *returnBSONJSON; // Used to parse bson to json. Special destructor
extern std::string returnString;
extern std::string errorString;

#define URI_GET(var, key)                                                  \
  mongoc_uri_t* var;                                                           \
  if (uriHandleMap.count(MArgument_getInteger(Args[key])) == 0) {            \
    return LIBRARY_FUNCTION_ERROR;                                             \
  }                                                                            \
  var = uriHandleMap[MArgument_getInteger(Args[key])];

////////////////////////////////////////////////////////////////////////////////

EXTERN_C DLLEXPORT int WL_EnableLogging(WolframLibraryData libData, mint Argc,
                                        MArgument *Args, MArgument Res);

////////////////////////////////////////////////////////////////////////////////

#endif
