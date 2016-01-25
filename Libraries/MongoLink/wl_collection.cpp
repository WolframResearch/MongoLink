////////////////////////////////////////////////////////////////////////////////
// BSON functions
//	- For API guide, see: https://api.mongodb.org/libbson/current/
////////////////////////////////////////////////////////////////////////////////

#include "wl_collection.h"

////////////////////////////////////////////////////////////////////////////////

DLLEXPORT void manage_instance_mongocollection(WolframLibraryData libData,
                                               mbool mode, mint id) {
  // Only do destruction. Deal with creation later
  if ((mode != 0) && (collectionHandleMap.count(id) > 0)) {
    mongoc_collection_destroy(collectionHandleMap[id]);
    collectionHandleMap.erase(id);
  }
}

////////////////////////////////////////////////////////////////////////////////

// Collection handle creation
EXTERN_C DLLEXPORT int WL_CollectionGetName(WolframLibraryData libData,
                                            mint Argc, MArgument *Args,
                                            MArgument Res) {

  auto collection = collectionHandleMap[MArgument_getInteger(Args[0])];
  // Set global returnString to name
  // Api: http://api.mongodb.org/c/current/mongoc_collection_get_name.html
  returnString = mongoc_collection_get_name(collection);

  MArgument_setUTF8String(Res, const_cast<char *>(returnString.c_str()));
  return LIBRARY_NO_ERROR;
}

// Collection handle creation
EXTERN_C DLLEXPORT int WL_CollectionHandleCreate(WolframLibraryData libData,
                                                 mint Argc, MArgument *Args,
                                                 MArgument Res) {
  int client_handle_key = MArgument_getInteger(Args[0]);
  int collection_handle_key = MArgument_getInteger(Args[1]);
  char *databaseName = MArgument_getUTF8String(Args[2]);
  char *collectionName = MArgument_getUTF8String(Args[3]);

  // Create collection handle, append to collectionHandleMap if successfully
  // created.
  // API: http://api.mongodb.org/c/current/mongoc_client_get_collection.html
  auto collection = mongoc_client_get_collection(
      clientHandleMap[client_handle_key], databaseName, collectionName);

  if (!collection) {
    errorString = "Cannot connect to collection.";
    return LIBRARY_FUNCTION_ERROR;
  }
  collectionHandleMap[collection_handle_key] = collection;

  // Disown strings
  libData->UTF8String_disown(databaseName);
  libData->UTF8String_disown(collectionName);
  return LIBRARY_NO_ERROR;
}

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
// Produces iterator object
EXTERN_C DLLEXPORT int WL_MongoCollectionFind(WolframLibraryData libData,
                                              mint Argc, MArgument *Args,
                                              MArgument Res) {
  auto collection = collectionHandleMap[MArgument_getInteger(Args[0])];
  // ignore mongoc_query_flags_t for now
  uint32_t skip = MArgument_getInteger(Args[1]);
  uint32_t limit = MArgument_getInteger(Args[2]);
  uint32_t batch_size = MArgument_getInteger(Args[3]);
  auto query = bsonHandleMap[MArgument_getInteger(Args[4])];
  auto fields = bsonHandleMap[MArgument_getInteger(Args[5])];

  mint outputIteratorHandleKey = MArgument_getInteger(Args[6]);

  // API: http://api.mongodb.org/c/current/mongoc_collection_find.html
  auto cursor = mongoc_collection_find(collection, MONGOC_QUERY_NONE, skip,
                                       limit, batch_size, query, fields, NULL);

  // Cursor can return Null if invalid parameters. Check
  if (!cursor) {
    errorString = "Unable to do perform query.";
    return LIBRARY_FUNCTION_ERROR;
  }

  // add iterator to map
  iteratorHandleMap[outputIteratorHandleKey] = cursor;

  return LIBRARY_NO_ERROR;
}
