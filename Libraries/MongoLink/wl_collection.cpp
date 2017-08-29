////////////////////////////////////////////////////////////////////////////////
// Collection-level functions
//	- For API guide, see:
// http://mongoc.org/libmongoc/current/mongoc_collection_t.html
////////////////////////////////////////////////////////////////////////////////

#include "wl_common.h"

/*----------------------------------------------------------------------------*/
// Collection handle creation
EXTERN_C DLLEXPORT int WL_CollectionGetName(WolframLibraryData libData,
                                            mint Argc, MArgument *Args,
                                            MArgument Res) {
  COLLECTION_GET(collection, 0)
  // Set global returnString to name
  // Api: http://api.mongodb.org/c/current/mongoc_collection_get_name.html
  returnString = mongoc_collection_get_name(collection);
  // Return string
  MArgument_setUTF8String(Res, const_cast<char *>(returnString.c_str()));
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_MongoCollectionCount(WolframLibraryData libData,
                                               mint Argc, MArgument *Args,
                                               MArgument Res) {
  COLLECTION_GET(collection, 0)
  BSON_GET(query, 1)

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

EXTERN_C DLLEXPORT int WL_MongoCollectionFind(WolframLibraryData libData,
                                              mint Argc, MArgument *Args,
                                              MArgument Res) {
  COLLECTION_GET(collection, 0)
  BSON_GET(filter, 1)
  BSON_GET(opts, 2)
  mint outputCursorHandleKey = MArgument_getInteger(Args[3]);

  auto cursor =
      mongoc_collection_find_with_opts(collection, filter, opts, NULL);
  // Cursor can return Null if invalid parameters. Check
  if (!cursor) {
    errorString = "Unable to do perform query.";
    return LIBRARY_FUNCTION_ERROR;
  }
  // add cursor to map
  cursorHandleMap[outputCursorHandleKey] = cursor;
  return LIBRARY_NO_ERROR;
}

// common interface for insert ops
EXTERN_C DLLEXPORT int WL_mongoc_collection_insert(WolframLibraryData libData,
                                                   mint Argc, MArgument *Args,
                                                   MArgument Res) {
  // Inputs
  COLLECTION_GET(collection, 0)
  WRITE_CONCERN_GET(wc, 1)

  auto doc_keys_tensor = MArgument_getMTensor(Args[2]);
  auto num_docs = libData->MTensor_getFlattenedLength(doc_keys_tensor);
  auto doc_keys = libData->MTensor_getIntegerData(doc_keys_tensor);

  mongoc_bulk_operation_t *bulk =
      mongoc_collection_create_bulk_operation(collection, true, wc);

  // insert docs
  for (i = 0; i < num_docs; i++) {
    mongoc_bulk_operation_insert(bulk, doc);
    bson_destroy(doc);
  }

  BSON_GET(document, 1)

  mint bson_oid_key = MArgument_getInteger(Args[3]);

  // check whether bson has oid. If not, create oid and append to bson
  // Need to do this as insertOne API requires returning "_id" field of
  // inserted docs, and C Driver does not support this
  bson_oid_t oid;
  if (!bson_has_field(document, "_id")) {
    bson_oid_init(&oid, NULL);
    BSON_APPEND_OID(document, "_id", &oid);
  }
  // don't support any insert flags yet.
  // http://mongoc.org/libmongoc/current/mongoc_insert_flags_t.html
  mongoc_insert_flags_t flags = MONGOC_INSERT_NONE;

  bson_error_t error;
  // http://mongoc.org/libmongoc/current/mongoc_collection_insert.html
  bool res = mongoc_collection_insert(collection, flags, document,
                                      write_concern, &error);
  if (!res) {
    errorString = error.message;
    return LIBRARY_FUNCTION_ERROR;
  }

  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int
WL_MongoCollectionCreateBulkOp(WolframLibraryData libData, mint Argc,
                               MArgument *Args, MArgument Res) {
  // Inputs
  COLLECTION_GET(collection, 0)
  bool ordered = MArgument_getInteger(Args[1]);
  // use wc_key = 0 to encode NULL
  mint wc_key = MArgument_getInteger(Args[2]);
  mongoc_write_concern_t *wc =
      (wc_key == 0) ? writeConcernHandleMap[wc_key] : NULL;
  mint output_bulk_key = MArgument_getInteger(Args[3]);
  // http://mongoc.org/libmongoc/current/mongoc_collection_create_bulk_operation.html
  bulkOperationHandleMap[output_bulk_key] =
      mongoc_collection_create_bulk_operation(collection, ordered, wc);
  return LIBRARY_NO_ERROR;
}

// NOTE: we only support a single update flag. Will change in future.
EXTERN_C DLLEXPORT int WL_MongoCollectionUpdate(WolframLibraryData libData,
                                                mint Argc, MArgument *Args,
                                                MArgument Res) {
  // Inputs
  COLLECTION_GET(collection, 0)
  BSON_GET(selector, 1)
  BSON_GET(update, 2)
  WRITE_CONCERN_GET(write_concern, 3)
  bool upsert = MArgument_getInteger(Args[4]);
  bool multi = MArgument_getInteger(Args[5]);

  // Deal with update flags
  mongoc_update_flags_t updateFlag = MONGOC_UPDATE_NONE;
  if (upsert)
    updateFlag = (mongoc_update_flags_t)(updateFlag | MONGOC_UPDATE_UPSERT);
  if (multi)
    updateFlag =
        (mongoc_update_flags_t)(updateFlag | MONGOC_UPDATE_MULTI_UPDATE);
  // API:
  // http://api.mongodb.org/c/current/mongoc_collection_update.html
  bson_error_t error;
  bool result = mongoc_collection_update(collection, updateFlag, selector,
                                         update, write_concern, &error);
  // Error handling
  if (!result) {
    errorString = error.message;
    return LIBRARY_FUNCTION_ERROR;
  }
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_MongoCollectionRemove(WolframLibraryData libData,
                                                mint Argc, MArgument *Args,
                                                MArgument Res) {
  // Inputs
  COLLECTION_GET(collection, 0)
  bool multiUpdate = MArgument_getInteger(Args[1]);
  BSON_GET(selector, 2)
  WRITE_CONCERN_GET(write_concern, 3)
  // Deal with remove flags
  mongoc_remove_flags_t removeFlags = MONGOC_REMOVE_NONE;
  if (!multiUpdate)
    removeFlags = MONGOC_REMOVE_SINGLE_REMOVE;

  bson_error_t error;
  bool result = mongoc_collection_remove(collection, removeFlags, selector,
                                         write_concern, &error);
  // Error handling
  if (!result) {
    errorString = error.message;
    return LIBRARY_FUNCTION_ERROR;
  }
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_MongoCollectionAggregation(WolframLibraryData libData,
                                                     mint Argc, MArgument *Args,
                                                     MArgument Res) {
  COLLECTION_GET(collection, 0)
  BSON_GET(pipeline, 1)
  mint outputCursorHandleKey = MArgument_getInteger(Args[2]);
  // http://mongoc.org/libmongoc/current/mongoc_collection_aggregate.html
  mongoc_cursor_t *cursor = mongoc_collection_aggregate(
      collection, MONGOC_QUERY_NONE, pipeline, NULL, NULL);

  // Cursor can return Null if invalid parameters. Check
  if (!cursor) {
    errorString = "Unable to do perform query.";
    return LIBRARY_FUNCTION_ERROR;
  }
  // add cursor to map
  cursorHandleMap[outputCursorHandleKey] = cursor;
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_MongoCollectionStats(WolframLibraryData libData,
                                               mint Argc, MArgument *Args,
                                               MArgument Res) {
  COLLECTION_GET(collection, 0)
  BSON_GET(opts, 1)
  mint reply_key = MArgument_getInteger(Args[2]);

  bson_t *reply = bson_new();
  bsonHandleMap[reply_key] = reply;

  // http://mongoc.org/libmongoc/current/mongoc_collection_stats.html
  bson_error_t error;
  bool result = mongoc_collection_stats(collection, opts, reply, &error);

  // Error handling
  if (!result) {
    std::cout << error.message << std::endl;
    errorString = error.message;
    return LIBRARY_FUNCTION_ERROR;
  }

  return LIBRARY_NO_ERROR;
}