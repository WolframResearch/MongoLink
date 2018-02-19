////////////////////////////////////////////////////////////////////////////////
// BSON functions
//	- For API guide, see: http://mongoc.org/libbson/current/index.html
////////////////////////////////////////////////////////////////////////////////

#include "wl_common.h"

/*----------------------------------------------------------------------------*/

EXTERN_C DLLEXPORT int WL_CreateBSONfromJSON(WolframLibraryData libData,
                                             mint Argc, MArgument *Args,
                                             MArgument Res) {
  int bson_handle_key = MArgument_getInteger(Args[0]);
  char *json = MArgument_getUTF8String(Args[1]);

  bson_error_t error;
  auto b = bson_new_from_json((const uint8_t *)json, -1, &error);
  if (!b) {
    errorString = error.message;
    libData->UTF8String_disown(json);
    return LIBRARY_FUNCTION_ERROR;
  }
  bsonHandleMap[bson_handle_key] = b;
  // Disown string
  libData->UTF8String_disown(json);
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_bsonAsJSON(WolframLibraryData libData, mint Argc,
                                     MArgument *Args, MArgument Res) {
  BSON_GET(bson, 0)
  bool relaxed = MArgument_getInteger(Args[1]);
  // the returned json strings lifetime must be longer than this function
  // (standard string return in LibraryLink)
  if (returnBSONJSON) {
    bson_free(returnBSONJSON);
    returnBSONJSON = NULL;
  }
  if (relaxed) {
    returnBSONJSON = bson_as_relaxed_extended_json(bson, NULL);
  } else {
    returnBSONJSON = bson_as_canonical_extended_json(bson, NULL);
  }
  MArgument_setUTF8String(Res, returnBSONJSON);
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_raw_array_to_bson(WolframLibraryData libData,
                                            mint Argc, MArgument *Args,
                                            MArgument Res) {
  int bson_handle_key = MArgument_getInteger(Args[0]);
  MRawArray data_tensor = MArgument_getMRawArray(Args[1]);

  size_t size = libData->rawarrayLibraryFunctions->MRawArray_getFlattenedLength(
      data_tensor);
  auto data = reinterpret_cast<uint8_t *>(
      libData->rawarrayLibraryFunctions->MRawArray_getData(data_tensor));

  auto b = bson_new_from_data(data, size);
  if (!b)
    return LIBRARY_FUNCTION_ERROR;

  bsonHandleMap[bson_handle_key] = b;
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_bson_to_rawarray(WolframLibraryData libData,
                                           mint Argc, MArgument *Args,
                                           MArgument Res) {
  BSON_GET(bson, 0)
  auto data = bson_get_data(bson);
  mint dims[1] = {bson->len};

  MRawArray output_raw;
  libData->rawarrayLibraryFunctions->MRawArray_new(MRawArray_Type_Ubit8, 1,
                                                   dims, &output_raw);

  auto data_raw = reinterpret_cast<uint8_t *>(
      libData->rawarrayLibraryFunctions->MRawArray_getData(output_raw));
  std::copy(data, data + bson->len, data_raw);

  // Return RawArray
  MArgument_setMRawArray(Res, output_raw);
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_get_bson_key(WolframLibraryData libData, mint Argc,
                                       MArgument *Args, MArgument Res) {
  BSON_GET(bson, 0)
  mint out_bson_key = MArgument_getInteger(Args[1]);
  char *key = MArgument_getUTF8String(Args[2]);

  bson_iter_t iter;
  // return 0 if key not found, 1 if found
  // http://mongoc.org/libbson/current/bson_iter_init_find_case.html
  bool result = bson_iter_init_find(&iter, bson, key);

  bson_t *out_bson = bson_new();
  bsonHandleMap[out_bson_key] = out_bson;
  // http://mongoc.org/libbson/current/bson_append_iter.html
  if (result)
    bson_append_iter(out_bson, key, -1, &iter);

  libData->UTF8String_disown(key);
  MArgument_setInteger(Res, static_cast<mint>(result));
  return LIBRARY_NO_ERROR;
}