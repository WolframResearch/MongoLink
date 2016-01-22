////////////////////////////////////////////////////////////////////////////////
// All common functions + global variables live here
////////////////////////////////////////////////////////////////////////////////

#include "common.h"

// Global handle Map Variables
std::map<mint, mongoc_client_t *> clientHandleMap;
std::map<mint, mongoc_database_t *> databaseHandleMap;
std::map<mint, mongoc_collection_t *> collectionHandleMap;

std::map<mint, mongoc_bulk_operation_t *> bulkOperationHandleMap;

// Return string to store any returned strings outside of scope of functions
// std::string return_string;
