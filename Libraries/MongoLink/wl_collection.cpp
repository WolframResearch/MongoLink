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

////////////////////////////////////////////////////////////////////////////////
EXTERN_C DLLEXPORT int
WL_MongoCollectionCreateBulkOp(WolframLibraryData libData, mint Argc,
                               MArgument *Args, MArgument Res) {
  // Inputs
  auto collection = collectionHandleMap[MArgument_getInteger(Args[0])];
  bool ordered = MArgument_getInteger(Args[1]);
  auto writeconcern = writeConcernHandleMap[MArgument_getInteger(Args[2])];

  mint output_bulk_key = MArgument_getInteger(Args[3]);

  // API:
  // http://api.mongodb.org/c/current/mongoc_collection_create_bulk_operation.html
  bulkOperationHandleMap[output_bulk_key] =
      mongoc_collection_create_bulk_operation(collection, ordered, NULL);

  return LIBRARY_NO_ERROR;
}

////////////////////////////////////////////////////////////////////////////////

// EXTERN_C DLLEXPORT int WL_MongoCollectionRemove(WolframLibraryData libData,
//                                                 mint Argc, MArgument *Args,
//                                                 MArgument Res) {
//   // Inputs
//   auto collection = collectionHandleMap[MArgument_getInteger(Args[0])];
//   auto selector = bsonHandleMap[MArgument_getInteger(Args[1])];
//   auto write_concern = writeConcernHandleMap[MArgument_getInteger(Args[2])];
//
//   mint output_bulk_key = MArgument_getInteger(Args[3]);
//
//   // API:
//   // http://api.mongodb.org/c/current/mongoc_collection_remove.html
//   if(!mongoc_collection_remove(
//       collection, NULL,
//       const bson_t *selector, const mongoc_write_concern_t *write_concern,
//       bson_error_t *error);
//   (collection, ordered, NULL);
//
//   return LIBRARY_NO_ERROR;
// }
