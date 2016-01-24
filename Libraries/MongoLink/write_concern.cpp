////////////////////////////////////////////////////////////////////////////////
// Write concern handler + functions
////////////////////////////////////////////////////////////////////////////////

#include "write_concern.h"

////////////////////////////////////////////////////////////////////////////////
// Client destruction
DLLEXPORT void manage_instance_mongowriteconcern(WolframLibraryData libData,
                                                 mbool mode, mint id) {
  // Destruction
  if (mode != 0) {
    mongoc_write_concern_destroy(writeConcernHandleMap[id]);
    writeConcernHandleMap.erase(id);
  }
  // Creation
  else
    writeConcernHandleMap[id] = mongoc_write_concern_new();
}

////////////////////////////////////////////////////////////////////////////////

// Client handle creation
EXTERN_C DLLEXPORT int WL_WriteConcernSet(WolframLibraryData libData, mint Argc,
                                          MArgument *Args, MArgument Res) {
  auto wc = writeConcernHandleMap[MArgument_getInteger(Args[0])];
  int32_t w = MArgument_getInteger(Args[1]);

  mongoc_write_concern_set_w(wc, w);
  return LIBRARY_NO_ERROR;
}

////////////////////////////////////////////////////////////////////////////////
EXTERN_C DLLEXPORT int WL_WriteConcernSetWtimeout(WolframLibraryData libData,
                                                  mint Argc, MArgument *Args,
                                                  MArgument Res) {
  auto wc = writeConcernHandleMap[MArgument_getInteger(Args[0])];
  int32_t wtimeout_msec = MArgument_getInteger(Args[1]);

  mongoc_write_concern_set_wtimeout(wc, wtimeout_msec);
  return LIBRARY_NO_ERROR;
}

////////////////////////////////////////////////////////////////////////////////
EXTERN_C DLLEXPORT int WL_WriteConcernSetJournal(WolframLibraryData libData,
                                                 mint Argc, MArgument *Args,
                                                 MArgument Res) {
  auto wc = writeConcernHandleMap[MArgument_getInteger(Args[0])];
  bool journal = MArgument_getInteger(Args[1]);

  mongoc_write_concern_set_journal(wc, journal);
  return LIBRARY_NO_ERROR;
}

////////////////////////////////////////////////////////////////////////////////
EXTERN_C DLLEXPORT int WL_WriteConcernGetInfo(WolframLibraryData libData,
                                              MLINK mlp) {
  // Load write concern handle
  int wc_handle;
  int len;
  if (!MLTestHead(mlp, "List", &len) || len != 1)
    return LIBRARY_FUNCTION_ERROR;
  if (!MLGetInteger(mlp, &wc_handle))
    return LIBRARY_FUNCTION_ERROR;
  auto wc = writeConcernHandleMap[wc_handle];

  // Get metadata
  bool journal = mongoc_write_concern_get_journal(wc);
  int32_t wtimeout = mongoc_write_concern_get_wtimeout(wc);
  int32_t w = mongoc_write_concern_get_w(wc);
  bool majority = mongoc_write_concern_get_wmajority(wc);

  // Export to linkobject
  if (!MLNewPacket(mlp))
    goto retPt;
  if (!MLPutFunction(mlp, "Association", 4))
    goto retPt;
  // Export journal
  if (!MLPutFunction(mlp, "Rule", 2))
    goto retPt;
  if (!MLPutString(mlp, "Journal"))
    goto retPt;
  if (journal) {
    if (!MLPutSymbol(mlp, "True"))
      goto retPt;
  } else if (!MLPutSymbol(mlp, "False"))
    goto retPt;
  // Export wtimeout
  if (!MLPutFunction(mlp, "Rule", 2))
    goto retPt;
  if (!MLPutString(mlp, "Timeout"))
    goto retPt;
  if (!MLPutInteger(mlp, wtimeout))
    goto retPt;
  // Export write concern
  if (!MLPutFunction(mlp, "Rule", 2))
    goto retPt;
  if (!MLPutString(mlp, "WriteConcern"))
    goto retPt;
  if (!MLPutInteger(mlp, w))
    goto retPt;
  // Export majority
  if (!MLPutFunction(mlp, "Rule", 2))
    goto retPt;
  if (!MLPutString(mlp, "Majority"))
    goto retPt;
  if (majority) {
    if (!MLPutSymbol(mlp, "True"))
      goto retPt;
  } else if (!MLPutSymbol(mlp, "False"))
    goto retPt;
  // Return via mathlink

  return LIBRARY_NO_ERROR;
retPt:
  return LIBRARY_FUNCTION_ERROR;
}
