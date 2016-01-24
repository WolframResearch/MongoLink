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
  int wc_handle;
  mongoc_write_concern_t *wc;
  // Get metadata
  bool journal = mongoc_write_concern_get_journal(wc);
  int32_t wtimeout = mongoc_write_concern_get_wtimeout(wc);
  int32_t w = mongoc_write_concern_get_w(wc);
  bool majority = mongoc_write_concern_get_wmajority(wc);
  int len;
  if (!MLTestHead(mlp, "List", &len) || len != 1)
    goto retPt;

  z1 if (!MLGetInteger(mlp, &wc_handle)) goto retPt;
  z2 wc = writeConcernHandleMap[wc_handle];
  if (!MLNewPacket(mlp))
    goto retPt;
  z3 if (!MLPutFunction(mlp, "Association", 1)) goto retPt;
  if (!MLPutFunction(mlp, "Rule", 2))
    goto retPt;
  z4 if (!MLPutString(mlp, "Journal")) goto retPt;
  z5 if (!MLPutInteger(mlp, 423)) goto retPt;
  z6
      // if (!WSPutInteger(mlp, 4))
      //   goto retPt;
      // if (!WSPutInteger(mlp, 289374))
      //   goto retPt;
      // Return via mathlink

      return LIBRARY_NO_ERROR;
retPt:
  return LIBRARY_FUNCTION_ERROR;
}
