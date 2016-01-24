////////////////////////////////////////////////////////////////////////////////
// MXNet WL Interface
////////////////////////////////////////////////////////////////////////////////

// #include <map>
#include <assert.h>
#include <stdio.h>

#include <bcon.h>
#include <mongoc.h>
#include <bson.h>

// Source files
#include "common.h"
#include "connection.h"
#include "bulk_insert.h"
#include "write_concern.h"

/* Return the version of Library Link */
EXTERN_C DLLEXPORT mint WolframLibrary_getVersion() {
  return WolframLibraryVersion;
}

EXTERN_C DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData) {
  // initialize mongodb
  mongoc_init();
  // Register All Library Managers
  (*libData->registerLibraryExpressionManager)("MongoClient",
                                               manage_instance_mongoclient);
  (*libData->registerLibraryExpressionManager)("MongoDatabase",
                                               manage_instance_mongodatabase);
  (*libData->registerLibraryExpressionManager)("MongoCollection",
                                               manage_instance_mongocollection);
  (*libData->registerLibraryExpressionManager)(
      "MongoCollectionBulkOperation",
      manage_instance_mongocollectionbulkoperation);
  (*libData->registerLibraryExpressionManager)(
      "MongoWriteConcern", manage_instance_mongowriteconcern);
  return 0;
}

EXTERN_C DLLEXPORT void
WolframLibrary_uninitialize(WolframLibraryData libData) {
  // Cleanup mongo
  mongoc_cleanup();
  // Unitialize All Library Managers
  (*libData->unregisterLibraryExpressionManager)("MongoClient");
  (*libData->unregisterLibraryExpressionManager)("MongoDatabase");
  (*libData->unregisterLibraryExpressionManager)("MongoCollection");
  (*libData->unregisterLibraryExpressionManager)(
      "MongoCollectionBulkOperation");
  (*libData->unregisterLibraryExpressionManager)("MongoWriteConcern");
  return;
}
