////////////////////////////////////////////////////////////////////////////////
// Connection handle creation + destruction
// 	- to: client, database + collection
////////////////////////////////////////////////////////////////////////////////

#include "connection.h"

////////////////////////////////////////////////////////////////////////////////
// Client destruction
DLLEXPORT void manage_instance_mongoclient(WolframLibraryData libData,
                                           mbool mode, mint id) {
  // Only do destruction. Deal with creation later
  if ((mode != 0) && (clientHandleMap.count(id) > 0)) {
    mongoc_client_destroy(clientHandleMap[id]);
    clientHandleMap.erase(id);
  }
}

// Client handle creation
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

DLLEXPORT void manage_instance_mongodatabase(WolframLibraryData libData,
                                             mbool mode, mint id) {
  // Only do destruction. Deal with creation later
  if ((mode != 0) && (databaseHandleMap.count(id) > 0)) {
    mongoc_database_destroy(databaseHandleMap[id]);
    databaseHandleMap.erase(id);
  }
}

// Database handle creation
EXTERN_C DLLEXPORT int WL_DatabaseHandleCreate(WolframLibraryData libData,
                                               mint Argc, MArgument *Args,
                                               MArgument Res) {
  int client_handle_key = MArgument_getInteger(Args[0]);
  int database_handle_key = MArgument_getInteger(Args[1]);
  char *databaseName = MArgument_getUTF8String(Args[2]);

  databaseHandleMap[database_handle_key] = mongoc_client_get_database(
      clientHandleMap[client_handle_key], databaseName);

  // Disown string
  libData->UTF8String_disown(databaseName);
  return LIBRARY_NO_ERROR;
}

////////////////////////////////////////////////////////////////////////////////

DLLEXPORT void manage_instance_mongocollection(WolframLibraryData libData,
                                               mbool mode, mint id) {
  // Only do destruction. Deal with creation later
  if ((mode != 0) && (collectionHandleMap.count(id) > 0)) {
    mongoc_collection_destroy(collectionHandleMap[id]);
    collectionHandleMap.erase(id);
  }
}

// Collection handle creation
EXTERN_C DLLEXPORT int WL_CollectionHandleCreate(WolframLibraryData libData,
                                                 mint Argc, MArgument *Args,
                                                 MArgument Res) {
  int client_handle_key = MArgument_getInteger(Args[0]);
  int collection_handle_key = MArgument_getInteger(Args[1]);
  char *databaseName = MArgument_getUTF8String(Args[2]);
  char *collectionName = MArgument_getUTF8String(Args[3]);

  collectionHandleMap[collection_handle_key] = mongoc_client_get_collection(
      clientHandleMap[client_handle_key], databaseName, collectionName);

  // Disown string
  libData->UTF8String_disown(databaseName);
  libData->UTF8String_disown(collectionName);
  return LIBRARY_NO_ERROR;
}
