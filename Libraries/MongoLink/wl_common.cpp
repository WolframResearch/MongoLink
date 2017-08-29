////////////////////////////////////////////////////////////////////////////////
// All common functions + global variables live here
////////////////////////////////////////////////////////////////////////////////

#include "wl_common.h"

/*----------------------------------------------------------------------------*/
// Global handle Map Variables
std::map<mint, mongoc_uri_t *> uriHandleMap;
std::map<mint, mongoc_client_t *> clientHandleMap;
std::map<mint, mongoc_database_t *> databaseHandleMap;
std::map<mint, mongoc_collection_t *> collectionHandleMap;
std::map<mint, mongoc_cursor_t *> cursorHandleMap;
std::map<mint, mongoc_bulk_operation_t *> bulkOperationHandleMap;
std::map<mint, mongoc_write_concern_t *> writeConcernHandleMap;
std::map<mint, bson_t *> bsonHandleMap;

// Return string to store any returned strings outside of scope of functions
char *returnCharArray = 0;
char *returnBSONJSON = 0;
std::string returnString = "None";
std::string errorString = "None";
