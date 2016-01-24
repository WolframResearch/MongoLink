////////////////////////////////////////////////////////////////////////////////
// BSON functions
//	- For API guide, see: https://api.mongodb.org/libbson/current/
////////////////////////////////////////////////////////////////////////////////

#include "collection.h"

////////////////////////////////////////////////////////////////////////////////

EXTERN_C DLLEXPORT int WL_MongoCollectionCount(WolframLibraryData libData,
                                               mint Argc, MArgument *Args,
                                               MArgument Res) {
  auto collection = collectionHandleMap[MArgument_getInteger(Args[0])];
  auto query = bsonHandleMap[MArgument_getInteger(Args[1])];

  bson_error_t error;
  mint count = mongoc_collection_count(collection, MONGOC_QUERY_NONE, query, 0,
                                       0, NULL, &error);
  // Error handling
  if (count < 0) {
    errorString = error.message;
    return LIBRARY_FUNCTION_ERROR;
  }

  MArgument_setInteger(Res, count);
  return LIBRARY_NO_ERROR;
}

////////////////////////////////////////////////////////////////////////////////
