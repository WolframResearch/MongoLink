////////////////////////////////////////////////////////////////////////////////
// Bulk Op
//	- For API guide, see:
// http://mongoc.org/libmongoc/current/mongoc_bulk_operation_t.html
////////////////////////////////////////////////////////////////////////////////

#include "wl_common.h"

bool is_transaction_acknowledged(mongoc_write_concern_t *wc,
                                 mongoc_collection_t *coll) {
  // if wc was NULL, then the write concern from the collection is used.
  // insertMany and insertOne require the return of whether the transaction was
  // acknowledged
  bool acknowledged;
  if (!wc)
    acknowledged = mongoc_write_concern_is_acknowledged(
        mongoc_collection_get_write_concern(coll));
  else
    acknowledged = mongoc_write_concern_is_acknowledged(wc);
  return acknowledged;
}

/*----------------------------------------------------------------------------*/

EXTERN_C DLLEXPORT int WL_CreateBulkOpFromCollection(WolframLibraryData libData,
                                                     mint Argc, MArgument *Args,
                                                     MArgument Res) {
  int bulkop_handle_key = MArgument_getInteger(Args[0]);
  COLLECTION_GET(collection, 1)
  WRITE_CONCERN_GET(wc, 2)
  bool ordered = MArgument_getBoolean(Args[3]);

  mongoc_bulk_operation_t *bulk =
      mongoc_collection_create_bulk_operation(collection, ordered, wc);

  bulkOperationHandleMap[bulkop_handle_key] = bulk;

  mbool ack = is_transaction_acknowledged(wc, collection);
  MArgument_setBoolean(Res, ack);
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_BulkOpExecute(WolframLibraryData libData, mint Argc,
                                        MArgument *Args, MArgument Res) {
  BULK_OP_GET(bulk, 0)
  int reply_bson_key = MArgument_getInteger(Args[1]);
  bson_t reply;
  bson_error_t error;
  bool res = mongoc_bulk_operation_execute(bulk, &reply, &error);
  if (!res) {
    errorString = error.message;
    return LIBRARY_FUNCTION_ERROR;
  }
  bsonHandleMap[reply_bson_key] = bson_copy(&reply);
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int
WL_mongoc_bulk_operation_update(WolframLibraryData libData, mint Argc,
                                MArgument *Args, MArgument Res) {
  BULK_OP_GET(bulk, 0)
  BSON_GET(selector, 1)
  BSON_GET(document, 2)
  BSON_GET(opts, 3)
  bool many = MArgument_getBoolean(Args[4]);

  bson_error_t error;
  bool res;
  if (many) {
    // http://mongoc.org/libmongoc/current/mongoc_bulk_operation_update_many_with_opts.html
    res = mongoc_bulk_operation_update_many_with_opts(bulk, selector, document,
                                                      opts, &error);
  } else {
    // http://mongoc.org/libmongoc/current/mongoc_bulk_operation_update_one_with_opts.html
    res = mongoc_bulk_operation_update_one_with_opts(bulk, selector, document,
                                                     opts, &error);
  }
  if (!res) {
    errorString = error.message;
    return LIBRARY_FUNCTION_ERROR;
  }

  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int
WL_mongoc_bulk_operation_insert(WolframLibraryData libData, mint Argc,
                                MArgument *Args, MArgument Res) {
  BULK_OP_GET(bulk, 0)
  BSON_GET(opts, 1)
  auto doc_keys_tensor = MArgument_getMTensor(Args[2]);
  auto num_docs = libData->MTensor_getFlattenedLength(doc_keys_tensor);
  auto doc_keys = libData->MTensor_getIntegerData(doc_keys_tensor);

  // insert docs
  bson_t *doc;
  bson_oid_t oid;
  bson_error_t error;
  for (int i = 0; i < num_docs; i++) {
    mint doc_key = doc_keys[i];
    if (bsonHandleMap.count(doc_key) == 0) {
      return LIBRARY_FUNCTION_ERROR;
    }
    doc = bsonHandleMap[doc_key];
    // check whether bson has oid. If not, create oid and append to bson
    // Need to do this as insertOne API requires returning "_id" field of
    // inserted docs, and C Driver does not support this
    if (!bson_has_field(doc, "_id")) {
      bson_oid_init(&oid, NULL);
      BSON_APPEND_OID(doc, "_id", &oid);
    }
    // http://mongoc.org/libmongoc/current/mongoc_bulk_operation_insert_with_opts.html
    bool res = mongoc_bulk_operation_insert_with_opts(bulk, doc, opts, &error);
    if (!res) {
      errorString = error.message;
      return LIBRARY_FUNCTION_ERROR;
    }
  }
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int
WL_mongoc_bulk_operation_remove(WolframLibraryData libData, mint Argc,
                                MArgument *Args, MArgument Res) {
  BULK_OP_GET(bulk, 0)
  BSON_GET(selector, 1)
  BSON_GET(opts, 2)
  bool many = MArgument_getBoolean(Args[3]);

  bson_error_t error;
  bool res;
  if (many) {
    // http://mongoc.org/libmongoc/current/mongoc_bulk_operation_remove_many_with_opts.html
    res = mongoc_bulk_operation_remove_many_with_opts(bulk, selector, opts,
                                                      &error);
  } else {
    // http://mongoc.org/libmongoc/current/mongoc_bulk_operation_remove_one_with_opts.html
    res = mongoc_bulk_operation_remove_one_with_opts(bulk, selector, opts,
                                                     &error);
  }
  if (!res) {
    errorString = error.message;
    return LIBRARY_FUNCTION_ERROR;
  }

  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int
WL_mongoc_bulk_operation_replace_one(WolframLibraryData libData, mint Argc,
                                MArgument *Args, MArgument Res) {
  BULK_OP_GET(bulk, 0)
  BSON_GET(selector, 1)
  BSON_GET(document, 2)
  BSON_GET(opts, 3)

  // http://mongoc.org/libmongoc/current/mongoc_bulk_operation_replace_one_with_opts.html
  bson_error_t error;
  bool res =
      mongoc_bulk_operation_replace_one_with_opts(bulk, selector, document, opts, &error);
  if (!res) {
    errorString = error.message;
    return LIBRARY_FUNCTION_ERROR;
  }

  return LIBRARY_NO_ERROR;
}