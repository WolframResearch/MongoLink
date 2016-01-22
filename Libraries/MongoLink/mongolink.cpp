////////////////////////////////////////////////////////////////////////////////
// MXNet WL Interface
////////////////////////////////////////////////////////////////////////////////

// #include <map>
#include <assert.h>
#include <stdio.h>

#include <bcon.h>
#include <mongoc.h>
#include <bson.h>

#include "WolframLibrary.h"
#include "WolframRawArrayLibrary.h"

// Source files
// #include "bulk_insert.h"

/* Return the version of Library Link */
EXTERN_C DLLEXPORT mint WolframLibrary_getVersion() {
  return WolframLibraryVersion;
}

EXTERN_C DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData) {
  // Register All Library Managers
  // (*libData->registerLibraryExpressionManager)();
  // "MongoBulkOperation", manage_instance_mongobulkoperation);
  return 0;
}

EXTERN_C DLLEXPORT void
WolframLibrary_uninitialize(WolframLibraryData libData) {
  // Unitialize All Library Managers
  // (*libData->unregisterLibraryExpressionManager)("MongoBulkOperation");
  return;
}
