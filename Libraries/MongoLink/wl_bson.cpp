////////////////////////////////////////////////////////////////////////////////
// BSON functions
//	- For API guide, see: http://mongoc.org/libbson/current/index.html
////////////////////////////////////////////////////////////////////////////////

#include "wl_common.h"

////////////////////////////////////////////////////////////////////////////////

EXTERN_C DLLEXPORT int WL_CreateBSONfromJSON(WolframLibraryData libData,
                                             mint Argc, MArgument *Args,
                                             MArgument Res) {
  int bson_handle_key = MArgument_getInteger(Args[0]);
  char *json = MArgument_getUTF8String(Args[1]);

  bson_error_t error;
  auto b = bson_new_from_json((const uint8_t *)json, -1, &error);
  if (!b) {
    errorString = error.message;
    return LIBRARY_FUNCTION_ERROR;
  }
  bsonHandleMap[bson_handle_key] = b;
  // Disown string
  libData->UTF8String_disown(json);
  return LIBRARY_NO_ERROR;
}

////////////////////////////////////////////////////////////////////////////////

EXTERN_C DLLEXPORT int WL_bsonAsJSON(WolframLibraryData libData, mint Argc,
                                     MArgument *Args, MArgument Res) {
  if (returnBSONJSON) {
    bson_free(returnBSONJSON);
  }
  int bson_handle_key = MArgument_getInteger(Args[0]);
  returnBSONJSON = bson_as_json(bsonHandleMap[bson_handle_key], NULL);
  MArgument_setUTF8String(Res, returnBSONJSON);
  return LIBRARY_NO_ERROR;
}
