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
  clientHandleMap[client_handle_key] = mongoc_client_new(connectionInfo);

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

// mongoc_collection_destroy(collection);
// mongoc_database_destroy(database);
// mongoc_client_destroy(client);
//
// int main(int argc, char *argv[]) {
//   mongoc_client_t *client;
//   mongoc_database_t *database;
//   mongoc_collection_t *collection;
//   bson_t *command, reply, *insert;
//   bson_error_t error;
//   char *str;
//   bool retval;
//
//   /*
//    * Required to initialize libmongoc's internals
//    */
//
//   /*
//    * Create a new client instance
//    */
//   client = mongoc_client_new("mongodb://localhost:27017");
//
//   /*
//    * Get a handle on the database "db_name" and collection "coll_name"
//    */
//   database = mongoc_client_get_database(client, "db_name");
//   collection = mongoc_client_get_collection(client, "db_name",
//   "coll_name");
//
//   /*
//    * Do work. This example pings the database, prints the result as JSON
//    and
//    * performs an insert
//    */
//   command = BCON_NEW("ping", BCON_INT32(1));
//
//   retval = mongoc_client_command_simple(client, "admin", command, NULL,
//   &reply,
//                                         &error);
//
//   if (!retval) {
//     fprintf(stderr, "%s\n", error.message);
//     return EXIT_FAILURE;
//   }
//
//   str = bson_as_json(&reply, NULL);
//   printf("%s\n", str);
//
//   insert = BCON_NEW("hello", BCON_UTF8("world"));
//
//   if (!mongoc_collection_insert(collection, MONGOC_INSERT_NONE, insert,
//   NULL,
//                                 &error)) {
//     fprintf(stderr, "%s\n", error.message);
//   }
//
//   bson_destroy(insert);
//   bson_destroy(&reply);
//   bson_destroy(command);
//   bson_free(str);
//
//   /*
//    * Release our handles and clean up libmongoc
//    */
//   mongoc_collection_destroy(collection);
//   mongoc_database_destroy(database);
//   mongoc_client_destroy(client);
//   mongoc_cleanup();
//
//   return 0;
// }
