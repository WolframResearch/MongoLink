////////////////////////////////////////////////////////////////////////////////
// URI Level Functions
////////////////////////////////////////////////////////////////////////////////

#include "wl_common.h"

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
