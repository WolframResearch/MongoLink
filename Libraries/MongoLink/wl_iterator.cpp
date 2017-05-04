////////////////////////////////////////////////////////////////////////////////
// Iterator (Cursor) interface
//	- For API guide, see:
// http://mongoc.org/libmongoc/current/mongoc_cursor_t.html
////////////////////////////////////////////////////////////////////////////////

#include "wl_iterator.h"

////////////////////////////////////////////////////////////////////////////////
// Client destruction
DLLEXPORT void manage_instance_mongoiterator(WolframLibraryData libData,
                                             mbool mode, mint id) {
  // Destruction
  if ((mode != 0) && (iteratorHandleMap.count(id) > 0)) {
    mongoc_cursor_destroy(iteratorHandleMap[id]);
    iteratorHandleMap.erase(id);
  }
}

////////////////////////////////////////////////////////////////////////////////

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

////////////////////////////////////////////////////////////////////////////////

EXTERN_C DLLEXPORT int WL_IteratorNext(WolframLibraryData libData, mint Argc,
                                       MArgument *Args, MArgument Res) {
  int iterator_handle_key = MArgument_getInteger(Args[0]);
  int bson_handle_key = MArgument_getInteger(Args[1]);
  // Check that iterator exists
  if (iteratorHandleMap.count(iterator_handle_key) == 0) {
    errorString = "Iterator does not exist.";
    return LIBRARY_FUNCTION_ERROR;
  }
  auto cursor = iteratorHandleMap[iterator_handle_key];
  const bson_t *doc;
  if (!mongoc_cursor_next(cursor, &doc)) {
    errorString =
        "Error reading next element of iterator. Has it been exhausted?";
    return LIBRARY_FUNCTION_ERROR;
  }
  // Free global variable if necessary
  if (returnBSONJSON) {
    bson_free(returnBSONJSON);
  }
  // Convert BSON to json
  returnBSONJSON = bson_as_json(doc, NULL);
  // Return
  MArgument_setUTF8String(Res, returnBSONJSON);
  return LIBRARY_NO_ERROR;
}
