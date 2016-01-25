////////////////////////////////////////////////////////////////////////////////
// Database-level functions
////////////////////////////////////////////////////////////////////////////////

#include "wl_database.h"

////////////////////////////////////////////////////////////////////////////////
DLLEXPORT void manage_instance_mongodatabase(WolframLibraryData libData,
                                             mbool mode, mint id) {
  // Only do destruction. Deal with creation later
  if ((mode != 0) && (databaseHandleMap.count(id) > 0)) {
    mongoc_database_destroy(databaseHandleMap[id]);
    databaseHandleMap.erase(id);
  }
}

////////////////////////////////////////////////////////////////////////////////
// Database handle creation
EXTERN_C DLLEXPORT int WL_DatabaseHandleCreate(WolframLibraryData libData,
                                               mint Argc, MArgument *Args,
                                               MArgument Res) {
  int client_handle_key = MArgument_getInteger(Args[0]);
  int database_handle_key = MArgument_getInteger(Args[1]);
  char *databaseName = MArgument_getUTF8String(Args[2]);

  auto database = mongoc_client_get_database(clientHandleMap[client_handle_key],
                                             databaseName);
  if (!database) {
    errorString = "Cannot connect to database.";
    return LIBRARY_FUNCTION_ERROR;
  }
  databaseHandleMap[database_handle_key] = database;

  // Disown string
  libData->UTF8String_disown(databaseName);
  return LIBRARY_NO_ERROR;
}

////////////////////////////////////////////////////////////////////////////////
// Database handle creation

////////////////////////////////////////////////////////////////////////////////
EXTERN_C DLLEXPORT int WL_GetCollectionNames(WolframLibraryData libData,
                                             MLINK mlp) {
  // Load database handle
  int database_handle;
  int len;
  if (!MLTestHead(mlp, "List", &len) || len != 1)
    return LIBRARY_FUNCTION_ERROR;
  if (!MLGetInteger(mlp, &database_handle))
    return LIBRARY_FUNCTION_ERROR;
  auto database = databaseHandleMap[database_handle];

  // Create new output packet
  if (!MLNewPacket(mlp))
    return LIBRARY_FUNCTION_ERROR;

  // Get collection names
  bson_error_t error;
  char **strv;
  int length = 0;
  if ((strv = mongoc_database_get_collection_names(database, &error))) {
    for (int i = 0; strv[i]; i++)
      ++length; // need to know length to initialize output list
  } else {
    errorString = error.message;
    return LIBRARY_FUNCTION_ERROR;
  }

  // If success, loop over string array:
  if (!MLPutFunction(mlp, "List", length))
    return LIBRARY_FUNCTION_ERROR;

  for (int i = 0; i < length; i++)
    if (!MLPutString(mlp, strv[i]))
      return LIBRARY_FUNCTION_ERROR;

  // Free string array
  bson_strfreev(strv);
  // Return
  return LIBRARY_NO_ERROR;
}
