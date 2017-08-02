////////////////////////////////////////////////////////////////////////////////
// Iterator (Cursor) interface
//	- For API guide, see:
// http://mongoc.org/libmongoc/current/mongoc_cursor_t.html
////////////////////////////////////////////////////////////////////////////////

#include "wl_common.h"

/*----------------------------------------------------------------------------*/

EXTERN_C DLLEXPORT int WL_IteratorHasNext(WolframLibraryData libData, mint Argc,
                                          MArgument *Args, MArgument Res) {
  int iterator_handle_key = MArgument_getInteger(Args[0]);
  if (iteratorHandleMap.count(iterator_handle_key) == 0) {
    errorString = "Iterator does not exist.";
    return LIBRARY_FUNCTION_ERROR;
  }
  auto cursor = iteratorHandleMap[iterator_handle_key];
  bool hasNext = mongoc_cursor_more(cursor);
  // Disown string
  MArgument_setInteger(Res, hasNext);
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_IteratorNext(WolframLibraryData libData, mint Argc,
                                       MArgument *Args, MArgument Res) {
  ITERATOR_GET(cursor, 0)
  int bson_handle_key = MArgument_getInteger(Args[1]);
  const bson_t *doc;
  // http://mongoc.org/libmongoc/current/mongoc_cursor_next.html
  if (!mongoc_cursor_next(cursor, &doc)) {
    errorString =
        "Error reading next element of iterator. Has it been exhausted?";
    return LIBRARY_FUNCTION_ERROR;
  }
  // not efficient: fix this later!
  bsonHandleMap[bson_handle_key] = bson_copy(doc);

  return LIBRARY_NO_ERROR;
}
