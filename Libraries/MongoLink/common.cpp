////////////////////////////////////////////////////////////////////////////////
// All common functions + global variables live here
////////////////////////////////////////////////////////////////////////////////

#include "common.h"

// Global handle Map Variables
std::map<mint, mongoc_bulk_operation_t *> bulkOperationHandleMap;

// Return string to store any returned strings outside of scope of functions
// std::string return_string;
