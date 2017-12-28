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

EXTERN_C DLLEXPORT int WL_MongoCollectionDrop(WolframLibraryData libData,
                                               mint Argc, MArgument *Args,
                                               MArgument Res) {
  COLLECTION_GET(collection, 0)
  BSON_GET(opts, 1)

  // http://mongoc.org/libmongoc/current/mongoc_collection_drop_with_opts.html
  bson_error_t error;
  bool result = mongoc_collection_drop_with_opts(collection, opts, &error);

  // Error handling
  if (!result) {
    std::cout << error.message << std::endl;
    errorString = error.message;
    return LIBRARY_FUNCTION_ERROR;
  }

  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_MongoCollectionValidate(WolframLibraryData libData,
                                               mint Argc, MArgument *Args,
                                               MArgument Res) {
  COLLECTION_GET(collection, 0)
  BSON_GET(opts, 1)
  mint reply_key = MArgument_getInteger(Args[2]);

  bson_t *reply = bson_new();
  bsonHandleMap[reply_key] = reply;

  // http://mongoc.org/libmongoc/current/mongoc_collection_validate.html
  bson_error_t error;
  bool result = mongoc_collection_validate(collection, opts, reply, &error);

  // Error handling
  if (!result) {
    std::cout << error.message << std::endl;
    errorString = error.message;
    return LIBRARY_FUNCTION_ERROR;
  }

  return LIBRARY_NO_ERROR;
}
