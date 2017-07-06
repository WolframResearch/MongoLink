////////////////////////////////////////////////////////////////////////////////
// URI Level Functions
////////////////////////////////////////////////////////////////////////////////

#include "wl_common.h"

////////////////////////////////////////////////////////////////////////////////
EXTERN_C DLLEXPORT int WL_URICreateHostPort(WolframLibraryData libData,
                                            mint Argc, MArgument *Args,
                                            MArgument Res) {
  int uri_handle_key = MArgument_getInteger(Args[0]);
  char *host = MArgument_getUTF8String(Args[1]);
  int port = MArgument_getInteger(Args[2]);

  // note: this cannot fail
  auto uri = mongoc_uri_new_for_host_port(host, static_cast<uint16_t>(port));
  uriHandleMap[uri_handle_key] = uri;

  // Disown string
  libData->UTF8String_disown(host);
  return LIBRARY_NO_ERROR;
}

////////////////////////////////////////////////////////////////////////////////
EXTERN_C DLLEXPORT int WL_URICreate(WolframLibraryData libData, mint Argc,
                                    MArgument *Args, MArgument Res) {
  int uri_handle_key = MArgument_getInteger(Args[0]);
  char *uri_string = MArgument_getUTF8String(Args[1]);

  auto uri = mongoc_uri_new(uri_string);
  if (!uri) {
    libData->UTF8String_disown(uri_string);
    return LIBRARY_FUNCTION_ERROR;
  }

  uriHandleMap[uri_handle_key] = uri;
  // Disown string
  libData->UTF8String_disown(uri_string);
  return LIBRARY_NO_ERROR;
}

////////////////////////////////////////////////////////////////////////////////
EXTERN_C DLLEXPORT int WL_URI_Get_String(WolframLibraryData libData, mint Argc,
                                         MArgument *Args, MArgument Res) {
  URI_GET(uri, 0)
  returnString = mongoc_uri_get_string(uri);
  // Return string
  MArgument_setUTF8String(Res, const_cast<char *>(returnString.c_str()));
  return LIBRARY_NO_ERROR;
}

////////////////////////////////////////////////////////////////////////////////
EXTERN_C DLLEXPORT int WL_uri_set_username(WolframLibraryData libData,
                                           mint Argc, MArgument *Args,
                                           MArgument Res) {
  URI_GET(uri, 0)
  mongoc_uri_set_username(uri, MArgument_getUTF8String(Args[1]));
  // Disown string
  libData->UTF8String_disown(MArgument_getUTF8String(Args[1]));
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_uri_set_password(WolframLibraryData libData,
                                           mint Argc, MArgument *Args,
                                           MArgument Res) {
  URI_GET(uri, 0)
  mongoc_uri_set_password(uri, MArgument_getUTF8String(Args[1]));
  // Disown string
  libData->UTF8String_disown(MArgument_getUTF8String(Args[1]));
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_uri_set_auth_source(WolframLibraryData libData,
                                              mint Argc, MArgument *Args,
                                              MArgument Res) {
  URI_GET(uri, 0)
  if (!mongoc_uri_set_auth_source(uri, MArgument_getUTF8String(Args[1]))) {
    libData->UTF8String_disown(MArgument_getUTF8String(Args[1]));
    return LIBRARY_FUNCTION_ERROR;
  }
  // Disown string
  libData->UTF8String_disown(MArgument_getUTF8String(Args[1]));
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_uri_set_database(WolframLibraryData libData,
                                           mint Argc, MArgument *Args,
                                           MArgument Res) {
  URI_GET(uri, 0)

  returnString = mongoc_uri_get_string(uri);
  std::cout << returnString << std::endl;

  mongoc_uri_set_database(uri, MArgument_getUTF8String(Args[1]));

  std::cout << mongoc_uri_get_database(uri) << std::endl;
  std::cout << mongoc_uri_get_password(uri) << std::endl;
  std::cout <<  mongoc_uri_get_string(uri) << std::endl;

  // Disown string
  libData->UTF8String_disown(MArgument_getUTF8String(Args[1]));
  return LIBRARY_NO_ERROR;
}