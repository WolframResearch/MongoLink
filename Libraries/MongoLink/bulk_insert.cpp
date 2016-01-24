////////////////////////////////////////////////////////////////////////////////
// Wrapper for bulk insert operations
// 	- adapted from http://api.mongodb.org/c/current/bulk.html#bulk-insert
//  - currently only supports BSON creation from JSON
////////////////////////////////////////////////////////////////////////////////

#include "common.h"

////////////////////////////////////////////////////////////////////////////////

DLLEXPORT void
manage_instance_mongocollectionbulkoperation(WolframLibraryData libData,
                                             mbool mode, mint id) {
  // Only do destruction. Deal with creation later
  if ((mode != 0) && (collectionBulkOperationHandleMap.count(id) > 0)) {
    mongoc_bulk_operation_destroy(collectionBulkOperationHandleMap[id]);
    collectionBulkOperationHandleMap.erase(id);
  }
}

EXTERN_C DLLEXPORT int
WL_MongoCollectionBulkOperation(WolframLibraryData libData, mint Argc,
                                MArgument *Args, MArgument Res) {

  int bulk_handle_key = MArgument_getInteger(Args[0]);
  auto collection = collectionHandleMap[MArgument_getInteger(Args[1])];
  int32_t writeConcern = MArgument_getInteger(Args[2]);
  int32_t writeConcernTimeout = MArgument_getInteger(Args[3]);
  bool ordered = MArgument_getInteger(Args[4]);

  auto *wc = mongoc_write_concern_new();
  mongoc_write_concern_set_w(wc, writeConcern);
  mongoc_write_concern_set_wtimeout(wc, writeConcernTimeout); /* milliseconds */

  auto bulk = mongoc_collection_create_bulk_operation(collection, true, wc);

  if (!bulk) {
    errorString = "Cannot create bulk operation.";
    return LIBRARY_FUNCTION_ERROR;
  }
  collectionBulkOperationHandleMap[bulk_handle_key] = bulk;

  // // Disown Strings
  // libData->UTF8String_disown(MArgument_getUTF8String(Args[1]));

  return LIBRARY_NO_ERROR;
}

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////

// static void bulk1(mongoc_collection_t *collection) {
//   mongoc_bulk_operation_t *bulk;
//   bson_error_t error;
//   bson_t *doc;
//   bson_t reply;
//   char *str;
//   bool ret;
//   int i;
//
//   bulk = mongoc_collection_create_bulk_operation(collection, true, NULL);
//
//   for (i = 0; i < 10000; i++) {
//     doc = BCON_NEW("i", BCON_INT32(i));
//     mongoc_bulk_operation_insert(bulk, doc);
//     bson_destroy(doc);
//   }
//
//   ret = mongoc_bulk_operation_execute(bulk, &reply, &error);
//
//   str = bson_as_json(&reply, NULL);
//   printf("%s\n", str);
//   bson_free(str);
//
//   if (!ret) {
//     fprintf(stderr, "Error: %s\n", error.message);
//   }
//
//   bson_destroy(&reply);
//   mongoc_bulk_operation_destroy(bulk);
// }
//
// int main(int argc, char *argv[]) {
//   mongoc_client_t *client;
//   mongoc_collection_t *collection;
//
//   mongoc_init();
//
//   client = mongoc_client_new("mongodb://localhost/");
//   collection = mongoc_client_get_collection(client, "test", "test");
//
//   bulk1(collection);
//
//   mongoc_collection_destroy(collection);
//   mongoc_client_destroy(client);
//
//   mongoc_cleanup();
//
//   return 0;
// }
