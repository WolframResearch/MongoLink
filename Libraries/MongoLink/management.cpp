////////////////////////////////////////////////////////////////////////////////
// ManagedLibraryExpression code
////////////////////////////////////////////////////////////////////////////////

#include "wl_common.h"

/*----------------------------------------------------------------------------*/

DLLEXPORT void manage_instance_mongobson(WolframLibraryData libData, mbool mode,
                                         mint id) {
  // Destruction
  if ((mode != 0) && (bsonHandleMap.count(id) > 0)) {
    bson_destroy(bsonHandleMap[id]);
    bsonHandleMap.erase(id);
  }
}

DLLEXPORT void manage_instance_mongobulkoperation(WolframLibraryData libData,
                                                  mbool mode, mint id) {
  // Only do destruction. Deal with creation later
  if ((mode != 0) && (bulkOperationHandleMap.count(id) > 0)) {
    mongoc_bulk_operation_destroy(bulkOperationHandleMap[id]);
    bulkOperationHandleMap.erase(id);
  }
}

DLLEXPORT void manage_instance_mongoclient(WolframLibraryData libData,
                                           mbool mode, mint id) {
  // Only do destruction. Deal with creation later
  if ((mode != 0) && (clientHandleMap.count(id) > 0)) {
    // API: http://api.mongodb.org/c/current/mongoc_client_destroy.html
    mongoc_client_destroy(clientHandleMap[id]);
    clientHandleMap.erase(id);
  }
}

DLLEXPORT void manage_instance_mongocollection(WolframLibraryData libData,
                                               mbool mode, mint id) {
  // Only do destruction. Deal with creation later
  if ((mode != 0) && (collectionHandleMap.count(id) > 0)) {
    mongoc_collection_destroy(collectionHandleMap[id]);
    collectionHandleMap.erase(id);
  }
}

DLLEXPORT void manage_instance_mongodatabase(WolframLibraryData libData,
                                             mbool mode, mint id) {
  // Only do destruction. Deal with creation later
  if ((mode != 0) && (databaseHandleMap.count(id) > 0)) {
    mongoc_database_destroy(databaseHandleMap[id]);
    databaseHandleMap.erase(id);
  }
}

DLLEXPORT void manage_instance_mongoiterator(WolframLibraryData libData,
                                             mbool mode, mint id) {
  // Destruction
  if ((mode != 0) && (iteratorHandleMap.count(id) > 0)) {
    mongoc_cursor_destroy(iteratorHandleMap[id]);
    iteratorHandleMap.erase(id);
  }
}

DLLEXPORT void manage_instance_mongouri(WolframLibraryData libData, mbool mode,
                                        mint id) {
  // Only do destruction. Deal with creation later
  if ((mode != 0) && (uriHandleMap.count(id) > 0)) {
    // API: http://mongoc.org/libmongoc/current/mongoc_uri_destroy.html
    mongoc_uri_destroy(uriHandleMap[id]);
    uriHandleMap.erase(id);
  }
}

DLLEXPORT void manage_instance_mongowriteconcern(WolframLibraryData libData,
                                                 mbool mode, mint id) {
  // Destruction
  if (mode != 0 && (writeConcernHandleMap.count(id) > 0)) {
    mongoc_write_concern_destroy(writeConcernHandleMap[id]);
    writeConcernHandleMap.erase(id);
  }
}

/*----------------------------------------------------------------------------*/

/* Return the version of Library Link */
EXTERN_C DLLEXPORT mint WolframLibrary_getVersion() {
  return WolframLibraryVersion;
}

EXTERN_C DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData) {
  // initialize mongodb
  mongoc_init();
  // Register All Library Managers
  (*libData->registerLibraryExpressionManager)("MongoURI",
                                               manage_instance_mongouri);
  (*libData->registerLibraryExpressionManager)("MongoClient",
                                               manage_instance_mongoclient);
  (*libData->registerLibraryExpressionManager)("MongoDatabase",
                                               manage_instance_mongodatabase);
  (*libData->registerLibraryExpressionManager)("MongoCollection",
                                               manage_instance_mongocollection);
  (*libData->registerLibraryExpressionManager)(
      "MongoBulkOperation", manage_instance_mongobulkoperation);
  (*libData->registerLibraryExpressionManager)(
      "MongoWriteConcern", manage_instance_mongowriteconcern);
  (*libData->registerLibraryExpressionManager)("MongoBSON",
                                               manage_instance_mongobson);
  (*libData->registerLibraryExpressionManager)("MongoIterator",
                                               manage_instance_mongoiterator);
  return 0;
}

EXTERN_C DLLEXPORT void
WolframLibrary_uninitialize(WolframLibraryData libData) {
  // Cleanup mongo
  mongoc_cleanup();
  // Unitialize All Library Managers
  (*libData->unregisterLibraryExpressionManager)("MongoURI");
  (*libData->unregisterLibraryExpressionManager)("MongoClient");
  (*libData->unregisterLibraryExpressionManager)("MongoDatabase");
  (*libData->unregisterLibraryExpressionManager)("MongoCollection");
  (*libData->unregisterLibraryExpressionManager)("MongoBulkOperation");
  (*libData->unregisterLibraryExpressionManager)("MongoWriteConcern");
  (*libData->unregisterLibraryExpressionManager)("MongoBSON");
  (*libData->unregisterLibraryExpressionManager)("MongoIterator");
  return;
}

/*----------------------------------------------------------------------------*/

EXTERN_C DLLEXPORT int WL_MongoGetLastError(WolframLibraryData libData,
                                            mint Argc, MArgument *Args,
                                            MArgument Res) {
  MArgument_setUTF8String(Res, const_cast<char *>(errorString.c_str()));
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_MongoGetVersion(WolframLibraryData libData, mint Argc,
                                          MArgument *Args, MArgument Res) {
  returnString = MONGOC_VERSION_S;
  MArgument_setUTF8String(Res, const_cast<char *>(returnString.c_str()));
  return LIBRARY_NO_ERROR;
}

// initializer: "It is responsible for initializing global state such as \
// process counters, SSL, and threading primitives."
// http://mongoc.org/libmongoc/current/mongoc_init.html
EXTERN_C DLLEXPORT int WL_MongoInitialize(WolframLibraryData libData, mint Argc,
                                          MArgument *Args, MArgument Res) {
  mongoc_init();
  return LIBRARY_NO_ERROR;
}