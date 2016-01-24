#ifndef BULK_INSERT_INCLUDED
#define BULK_INSERT_INCLUDED

#include <map>
#include <assert.h>
#include <stdio.h>

#include <bcon.h>
#include <mongoc.h>
#include <bson.h>

#include "WolframLibrary.h"
#include "WolframRawArrayLibrary.h"

////////////////////////////////////////////////////////////////////////////////

DLLEXPORT void
manage_instance_mongocollectionbulkoperation(WolframLibraryData libData,
                                             mbool mode, mint id);

////////////////////////////////////////////////////////////////////////////////

#endif
