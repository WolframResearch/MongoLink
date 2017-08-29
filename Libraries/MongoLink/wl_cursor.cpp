////////////////////////////////////////////////////////////////////////////////
// Cursor (Cursor) interface
//	- For API guide, see:
// http://mongoc.org/libmongoc/current/mongoc_cursor_t.html
////////////////////////////////////////////////////////////////////////////////

#include "wl_common.h"

/*----------------------------------------------------------------------------*/

EXTERN_C DLLEXPORT int WL_CursorNext(WolframLibraryData libData, mint Argc,
                                     MArgument *Args, MArgument Res) {
  ITERATOR_GET(cursor, 0)
  int bson_handle_key = MArgument_getInteger(Args[1]);
  const bson_t *doc;
  // http://mongoc.org/libmongoc/current/mongoc_cursor_next.html
  bool has_next = mongoc_cursor_next(cursor, &doc);
  if (!has_next) {
    MArgument_setInteger(Res, 0);
    return LIBRARY_NO_ERROR;
  }
  // handling according to http://mongoc.org/libmongoc/current/cursors.html
  bson_error_t error;
  if (mongoc_cursor_error(cursor, &error)) {
    errorString = error.message;
    return LIBRARY_FUNCTION_ERROR;
  }
  // not efficient: fix this later!
  bsonHandleMap[bson_handle_key] = bson_copy(doc);
  MArgument_setInteger(Res, 1);
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_CursorSetBatchSize(WolframLibraryData libData,
                                             mint Argc, MArgument *Args,
                                             MArgument Res) {
  ITERATOR_GET(cursor, 0)
  uint32_t batch_size = MArgument_getInteger(Args[1]);
  // http://mongoc.org/libmongoc/current/mongoc_cursor_set_batch_size.html
  mongoc_cursor_set_batch_size(cursor, batch_size);
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_CursorGetBatchSize(WolframLibraryData libData,
                                             mint Argc, MArgument *Args,
                                             MArgument Res) {
  ITERATOR_GET(cursor, 0)
  // http://mongoc.org/libmongoc/current/mongoc_cursor_get_batch_size.html
  mint batch_size = mongoc_cursor_get_batch_size(cursor);
  MArgument_setInteger(Res, batch_size);
  return LIBRARY_NO_ERROR;
}
