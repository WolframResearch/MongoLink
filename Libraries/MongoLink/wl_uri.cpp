////////////////////////////////////////////////////////////////////////////////
// URI Level Functions
////////////////////////////////////////////////////////////////////////////////

#include "wl_common.h"

/*----------------------------------------------------------------------------*/

EXTERN_C DLLEXPORT int WL_URICreate(WolframLibraryData libData, mint Argc,
                                    MArgument *Args, MArgument Res) {
  int uri_handle_key = MArgument_getInteger(Args[0]);
  char *uri_string = MArgument_getUTF8String(Args[1]);

  bson_error_t error;
  mongoc_uri_t *uri = mongoc_uri_new_with_error(uri_string, &error);
  if (!uri) {
    errorString = error.message;
    libData->UTF8String_disown(uri_string);
    return LIBRARY_FUNCTION_ERROR;
  }

  uriHandleMap[uri_handle_key] = uri;
  // Disown string
  libData->UTF8String_disown(uri_string);
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_URISetOptionInt32(WolframLibraryData libData,
                                            mint Argc, MArgument *Args,
                                            MArgument Res) {
  URI_GET(uri, 0)
  char *name = MArgument_getUTF8String(Args[1]);
  int32_t value = MArgument_getInteger(Args[2]);
  bool res = mongoc_uri_set_option_as_int32(uri, name, value);
  // the mongo c driver seems to report invalid option values via logging,
  // but for some reason fails to report invalid options. Just fails.
  // so: logging writes to error string. If its empty, report error manually
  if (!res) {
    if (errorString.empty())
      errorString =
          "Invalid option or value for \"" + std::string(name) + std::string("\"");
    libData->UTF8String_disown(name);
    return LIBRARY_FUNCTION_ERROR;
  }
  libData->UTF8String_disown(name);
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_URISetOptionBool(WolframLibraryData libData,
                                           mint Argc, MArgument *Args,
                                           MArgument Res) {
  URI_GET(uri, 0)
  char *name = MArgument_getUTF8String(Args[1]);
  bool value = MArgument_getBoolean(Args[2]);
  bool res = mongoc_uri_set_option_as_bool(uri, name, value);
  // the mongo c driver seems to report invalid option values via logging,
  // but for some reason fails to report invalid options. Just fails.
  // so: logging writes to error string. If its empty, report error manually
  if (!res) {
    if (errorString.empty())
      errorString =
          "Invalid option or value for \"" + std::string(name) + std::string("\"");
    libData->UTF8String_disown(name);
    return LIBRARY_FUNCTION_ERROR;
  }
  libData->UTF8String_disown(name);
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_URISetOptionUTF8(WolframLibraryData libData,
                                           mint Argc, MArgument *Args,
                                           MArgument Res) {
  URI_GET(uri, 0)
  char *name = MArgument_getUTF8String(Args[1]);
  char *value = MArgument_getUTF8String(Args[2]);

  bool res = mongoc_uri_set_option_as_utf8(uri, name, value);
  libData->UTF8String_disown(value);
  // the mongo c driver seems to report invalid option values via logging,
  // but for some reason fails to report invalid options. Just fails.
  // so: logging writes to error string. If its empty, report error manually
  if (!res) {
    if (errorString.empty())
      errorString =
          "Invalid option or value for \"" + std::string(name) + std::string("\"");
    libData->UTF8String_disown(name);
    return LIBRARY_FUNCTION_ERROR;
  }
  libData->UTF8String_disown(name);
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_URIGetString(WolframLibraryData libData, mint Argc,
                                       MArgument *Args, MArgument Res) {
  URI_GET(uri, 0)

  auto temp = mongoc_uri_get_options(uri);
  MArgument_setUTF8String(Res, const_cast<char *>(mongoc_uri_get_string(uri)));
  return LIBRARY_NO_ERROR;
}

// put named option setters together
EXTERN_C DLLEXPORT int WL_URISetPropEnum(WolframLibraryData libData, mint Argc,
                                         MArgument *Args, MArgument Res) {
  URI_GET(uri, 0)
  char *value = MArgument_getUTF8String(Args[1]);
  mint selector = MArgument_getInteger(Args[2]);
  bool res;
  switch (selector) {
  case 1:
    res = mongoc_uri_set_auth_mechanism(uri, value);
    break;
  case 2:
    res = mongoc_uri_set_auth_source(uri, value);
    break;
  case 3:
    res = mongoc_uri_set_compressors(uri, value);
    break;
  case 4:
    res = mongoc_uri_set_database(uri, value);
    break;
  case 5:
    res = mongoc_uri_set_password(uri, value);
    break;
  case 6:
    res = mongoc_uri_set_username(uri, value);
    break;
  }
  libData->UTF8String_disown(value);
  if (!res)
    return LIBRARY_FUNCTION_ERROR;
  return LIBRARY_NO_ERROR;
}