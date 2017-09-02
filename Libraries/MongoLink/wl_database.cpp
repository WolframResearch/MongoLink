////////////////////////////////////////////////////////////////////////////////
// Database-level functions
// - For API guide, see:
// http://mongoc.org/libmongoc/current/mongoc_database_t.html
////////////////////////////////////////////////////////////////////////////////

#include "wl_common.h"

/*----------------------------------------------------------------------------*/

EXTERN_C DLLEXPORT int WL_DatabaseGetName(WolframLibraryData libData, mint Argc,
                                          MArgument *Args, MArgument Res) {
  auto database = databaseHandleMap[MArgument_getInteger(Args[0])];
  // Set global returnString to name
  returnString = mongoc_database_get_name(database);
  MArgument_setUTF8String(Res, const_cast<char *>(returnString.c_str()));
  return LIBRARY_NO_ERROR;
}

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

EXTERN_C DLLEXPORT int WL_DatabaseGetCollection(WolframLibraryData libData,
                                                mint Argc, MArgument *Args,
                                                MArgument Res) {
  auto database = databaseHandleMap[MArgument_getInteger(Args[0])];
  int collection_handle_key = MArgument_getInteger(Args[1]);
  char *collectionName = MArgument_getUTF8String(Args[2]);
  // Create collection handle, append to collectionHandleMap if successfully
  // created.
  auto collection = mongoc_database_get_collection(database, collectionName);
  if (!collection) {
    errorString = "Cannot connect to collection.";
    return LIBRARY_FUNCTION_ERROR;
  }
  collectionHandleMap[collection_handle_key] = collection;
  // Disown strings
  libData->UTF8String_disown(collectionName);
  return LIBRARY_NO_ERROR;
}

////////////////////////////////////////////////////////////////////////////
EXTERN_C DLLEXPORT int WL_mongoc_database_drop(WolframLibraryData libData,
                                               mint Argc, MArgument *Args,
                                               MArgument Res) {

  bson_error_t error;
  DATABASE_GET(db, 0)
  auto res = mongoc_database_drop(db, &error);
  if (!res) {
    errorString = error.message;
    return LIBRARY_FUNCTION_ERROR;
  }
  return LIBRARY_NO_ERROR;
}
