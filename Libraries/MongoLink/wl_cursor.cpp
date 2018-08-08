////////////////////////////////////////////////////////////////////////////////
// Cursor (Cursor) interface
//  - For API guide, see:
// http://mongoc.org/libmongoc/current/mongoc_cursor_t.html
////////////////////////////////////////////////////////////////////////////////

#include "wl_common.h"

/*----------------------------------------------------------------------------*/

EXTERN_C DLLEXPORT int WL_CursorNext(WolframLibraryData libData, mint Argc,
                                     MArgument *Args, MArgument Res) {
  CURSOR_GET(cursor, 0)
  int bson_handle_key = MArgument_getInteger(Args[1]);
  const bson_t *doc;
  // http://mongoc.org/libmongoc/current/mongoc_cursor_next.html
  bool has_next = mongoc_cursor_next(cursor, &doc);

  // handling according to http://mongoc.org/libmongoc/current/cursors.html
  bson_error_t error;
  if (mongoc_cursor_error(cursor, &error)) {
    errorString = error.message;
    return LIBRARY_FUNCTION_ERROR;
  }

  if (!has_next) {
    MArgument_setInteger(Res, 0);
    return LIBRARY_NO_ERROR;
  }

  // not efficient: fix this later!
  bsonHandleMap[bson_handle_key] = bson_copy(doc);
  MArgument_setInteger(Res, 1);
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_CursorSetBatchSize(WolframLibraryData libData,
                                             mint Argc, MArgument *Args,
                                             MArgument Res) {
  CURSOR_GET(cursor, 0)
  uint32_t batch_size = MArgument_getInteger(Args[1]);
  // http://mongoc.org/libmongoc/current/mongoc_cursor_set_batch_size.html
  mongoc_cursor_set_batch_size(cursor, batch_size);
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_CursorInfo(WolframLibraryData libData, mint Argc,
                                     MArgument *Args, MArgument Res) {
  CURSOR_GET(cursor, 0)
  mint type = MArgument_getInteger(Args[1]);
  mint out;
  switch (type) {
  case 1:
    out = mongoc_cursor_get_batch_size(cursor);
    break;
  case 2:
    out = mongoc_cursor_is_alive(cursor);
    break;
  case 3:
    out = mongoc_cursor_get_hint(cursor);
    break;
  case 4:
    out = mongoc_cursor_get_max_await_time_ms(cursor);
    break;
  case 5:
    out = mongoc_cursor_get_limit(cursor);
    break;
  }
  MArgument_setInteger(Res, out);
  return LIBRARY_NO_ERROR;
}