////////////////////////////////////////////////////////////////////////////////
// Client-level functions
////////////////////////////////////////////////////////////////////////////////

#include "wl_client.h"

////////////////////////////////////////////////////////////////////////////////
// Client destruction
DLLEXPORT void manage_instance_mongoclient(WolframLibraryData libData,
                                           mbool mode, mint id) {
  // Only do destruction. Deal with creation later
  if ((mode != 0) && (clientHandleMap.count(id) > 0)) {
    // API: http://api.mongodb.org/c/current/mongoc_client_destroy.html
    mongoc_client_destroy(clientHandleMap[id]);
    clientHandleMap.erase(id);
  }
}

////////////////////////////////////////////////////////////////////////////////
EXTERN_C DLLEXPORT int WL_ClientHandleCreate(WolframLibraryData libData,
                                             mint Argc, MArgument *Args,
                                             MArgument Res) {
  int client_handle_key = MArgument_getInteger(Args[0]);
  char *connectionInfo = MArgument_getUTF8String(Args[1]);

  auto client = mongoc_client_new(connectionInfo);

  if (!client) {
    errorString = "Invalid URI. Cannot connect to client.";
    return LIBRARY_FUNCTION_ERROR;
  }
  // If connection was successful, add to clientHandleMap
  clientHandleMap[client_handle_key] = client;
  // Disown string
  libData->UTF8String_disown(connectionInfo);
  return LIBRARY_NO_ERROR;
}

////////////////////////////////////////////////////////////////////////////////
EXTERN_C DLLEXPORT int WL_GetDatabaseNames(WolframLibraryData libData,
                                           MLINK mlp) {
  // Load database handle
  int client_handle;
  int len;
  if (!MLTestHead(mlp, "List", &len) || len != 1)
    return LIBRARY_FUNCTION_ERROR;
  if (!MLGetInteger(mlp, &client_handle))
    return LIBRARY_FUNCTION_ERROR;
  auto client = clientHandleMap[client_handle];

  // Create new output packet
  if (!MLNewPacket(mlp))
    return LIBRARY_FUNCTION_ERROR;

  // Get collection names
  bson_error_t error;
  char **strv;
  int length = 0;
  if ((strv = mongoc_client_get_database_names(client, &error))) {
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
