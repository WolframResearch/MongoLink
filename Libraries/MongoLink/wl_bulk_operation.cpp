////////////////////////////////////////////////////////////////////////////////
// Bulk-operation level functions
////////////////////////////////////////////////////////////////////////////////

#include "wl_common.h"

////////////////////////////////////////////////////////////////////////////////
EXTERN_C DLLEXPORT int WL_bulk_operation_insert(WolframLibraryData libData,
                                                mint Argc, MArgument *Args,
                                                MArgument Res) {
  auto bulk = bulkOperationHandleMap[MArgument_getInteger(Args[0])];
  auto document = bsonHandleMap[MArgument_getInteger(Args[1])];
  // API: http://api.mongodb.org/c/current/mongoc_bulk_operation_insert.html
  mongoc_bulk_operation_insert(bulk, document);
  return LIBRARY_NO_ERROR;
}

////////////////////////////////////////////////////////////////////////////////
EXTERN_C DLLEXPORT int
WL_mongoc_bulk_operation_execute(WolframLibraryData libData, mint Argc,
                                 MArgument *Args, MArgument Res) {

  auto bulk = bulkOperationHandleMap[MArgument_getInteger(Args[0])];

  bson_t reply;
  bson_error_t error;
  // API: http://api.mongodb.org/c/current/mongoc_bulk_operation_execute.html
  if (!mongoc_bulk_operation_execute(bulk, &reply, &error)) {
    errorString = error.message;
    return LIBRARY_FUNCTION_ERROR;
  }

  // Return as std::string (performance uncritical, no problem copying)
  returnString = bson_as_json(&reply, NULL);
  bson_destroy(&reply);
  // Return
  MArgument_setUTF8String(Res, const_cast<char *>(returnString.c_str()));
  return LIBRARY_NO_ERROR;
}
