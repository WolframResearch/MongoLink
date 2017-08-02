#ifndef COMMON_H_INCLUDED
#define COMMON_H_INCLUDED

#include <assert.h>
#include <stdio.h>

#include <iostream>
#include <map>

#include <bcon.h>
#include <bson.h>
#include <bson.h>
#include <mongoc.h>

#include "mathlink.h"
#include "WolframLibrary.h"
#include "WolframRawArrayLibrary.h"

/*----------------------------------------------------------------------------*/

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

#define URI_GET(var, key)                                                      \
  mongoc_uri_t *var;                                                           \
  if (uriHandleMap.count(MArgument_getInteger(Args[key])) == 0) {              \
    return LIBRARY_FUNCTION_ERROR;                                             \
  }                                                                            \
  var = uriHandleMap[MArgument_getInteger(Args[key])];

#define CLIENT_GET(var, key)                                                   \
  mongoc_client_t *var;                                                        \
  if (clientHandleMap.count(MArgument_getInteger(Args[key])) == 0) {           \
    return LIBRARY_FUNCTION_ERROR;                                             \
  }                                                                            \
  var = clientHandleMap[MArgument_getInteger(Args[key])];

#define DATABASE_GET(var, key)                                                 \
  mongoc_database_t *var;                                                      \
  if (databaseHandleMap.count(MArgument_getInteger(Args[key])) == 0) {         \
    return LIBRARY_FUNCTION_ERROR;                                             \
  }                                                                            \
  var = databaseHandleMap[MArgument_getInteger(Args[key])];

#define COLLECTION_GET(var, key)                                               \
  mongoc_collection_t *var;                                                    \
  if (collectionHandleMap.count(MArgument_getInteger(Args[key])) == 0) {       \
    return LIBRARY_FUNCTION_ERROR;                                             \
  }                                                                            \
  var = collectionHandleMap[MArgument_getInteger(Args[key])];

#define ITERATOR_GET(var, key)                                                 \
  mongoc_cursor_t *var;                                                        \
  if (iteratorHandleMap.count(MArgument_getInteger(Args[key])) == 0) {         \
    return LIBRARY_FUNCTION_ERROR;                                             \
  }                                                                            \
  var = iteratorHandleMap[MArgument_getInteger(Args[key])];

#define BULK_OP_GET(var, key)                                                  \
  mongoc_bulk_operation_t *var;                                                \
  if (bulkOperationHandleMap.count(MArgument_getInteger(Args[key])) == 0) {    \
    return LIBRARY_FUNCTION_ERROR;                                             \
  }                                                                            \
  var = bulkOperationHandleMap[MArgument_getInteger(Args[key])];

#define WRITE_CONCERN_GET(var, key)                                            \
  mongoc_write_concern_t *var;                                                 \
  if (writeConcernHandleMap.count(MArgument_getInteger(Args[key])) == 0) {     \
    return LIBRARY_FUNCTION_ERROR;                                             \
  }                                                                            \
  var = writeConcernHandleMap[MArgument_getInteger(Args[key])];

#define BSON_GET(var, key)                                                     \
  bson_t *var;                                                                 \
  if (bsonHandleMap.count(MArgument_getInteger(Args[key])) == 0) {             \
    return LIBRARY_FUNCTION_ERROR;                                             \
  }                                                                            \
  var = bsonHandleMap[MArgument_getInteger(Args[key])];

/*----------------------------------------------------------------------------*/

#endif
