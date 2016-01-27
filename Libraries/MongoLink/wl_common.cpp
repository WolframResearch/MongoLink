////////////////////////////////////////////////////////////////////////////////
// All common functions + global variables live here
////////////////////////////////////////////////////////////////////////////////

#include "wl_common.h"

// Global handle Map Variables
std::map<mint, mongoc_client_t *> clientHandleMap;
std::map<mint, mongoc_database_t *> databaseHandleMap;
std::map<mint, mongoc_collection_t *> collectionHandleMap;
std::map<mint, mongoc_cursor_t *> iteratorHandleMap;
std::map<mint, mongoc_bulk_operation_t *> bulkOperationHandleMap;
std::map<mint, mongoc_write_concern_t *> writeConcernHandleMap;
std::map<mint, bson_t *> bsonHandleMap;

// Return string to store any returned strings outside of scope of functions
char *returnCharArray = 0;
char *returnBSONJSON = 0;
std::string returnString = "None";
std::string errorString = "None";

#include <cstdarg>

char tmp[8192];

static WolframLibraryData debugLibData = NULL;

void WLPrint(const char *fmtstr, ...) {
  va_list argList;

  if (debugLibData == NULL)
    return;

  va_start(argList, fmtstr);
  vsprintf(tmp, fmtstr, argList);
  va_end(argList);

  MLINK link = debugLibData->getWSLINK(debugLibData);
  MLPutFunction(link, "EvaluatePacket", 1);
  MLPutFunction(link, "CellPrint", 1);
  MLPutFunction(link, "Cell", 4);
  MLPutString(link, tmp);
  MLPutString(link, "Print");
  MLPutFunction(link, "Rule", 2);
  MLPutSymbol(link, "CellLabel");
  MLPutString(link, "LibraryLink");
  MLPutFunction(link, "Rule", 2);
  MLPutSymbol(link, "ShowCellLabel");
  MLPutString(link, "True");

  debugLibData->processWSLINK(link);
  auto pkt = MLNextPacket(link);
  if (pkt == RETURNPKT) {
    MLNewPacket(link);
  }
}

void EnableLogging(WolframLibraryData libData) { debugLibData = libData; }

////////////////////////////////////////////////////////////////////////////////

EXTERN_C DLLEXPORT int WL_MongoGetLastError(WolframLibraryData libData,
                                            mint Argc, MArgument *Args,
                                            MArgument Res) {
  MArgument_setUTF8String(Res, const_cast<char *>(errorString.c_str()));
  WLPrint("%d: %d", 5, 6);
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_EnableLogging(WolframLibraryData libData, mint Argc,
                                        MArgument *Args, MArgument Res) {
  EnableLogging(libData);
  return LIBRARY_NO_ERROR;
}

////////////////////////////////////////////////////////////////////////////////
