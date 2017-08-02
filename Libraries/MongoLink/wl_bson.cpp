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
  if (returnBSONJSON) {
    bson_free(returnBSONJSON);
  }
  returnBSONJSON = bson_as_json(bson, NULL);
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
