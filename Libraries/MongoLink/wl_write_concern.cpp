////////////////////////////////////////////////////////////////////////////////
// Write concern handler + functions
// For API guide, see:
// http://mongoc.org/libmongoc/current/mongoc_write_concern_t.html
////////////////////////////////////////////////////////////////////////////////

#include "wl_common.h"

/*----------------------------------------------------------------------------*/

// Note: this creation was once done by manage_instance_mongowriteconcern.
// However: you often need Null write concerns. This allows a key to be created
// independently of initialization
EXTERN_C DLLEXPORT int WL_WriteConcernNew(WolframLibraryData libData, mint Argc,
                                          MArgument *Args, MArgument Res) {
  int wc_handle_key = MArgument_getInteger(Args[0]);
  writeConcernHandleMap[wc_handle_key] = mongoc_write_concern_new();
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_WriteConcernSet(WolframLibraryData libData, mint Argc,
                                          MArgument *Args, MArgument Res) {
  WRITE_CONCERN_GET(wc, 0)
  int32_t w = MArgument_getInteger(Args[1]);
  mongoc_write_concern_set_w(wc, w);
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_WriteConcernSetWtimeout(WolframLibraryData libData,
                                                  mint Argc, MArgument *Args,
                                                  MArgument Res) {
  WRITE_CONCERN_GET(wc, 0)
  int32_t wtimeout_msec = MArgument_getInteger(Args[1]);
  mongoc_write_concern_set_wtimeout(wc, wtimeout_msec);
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_WriteConcernSetJournal(WolframLibraryData libData,
                                                 mint Argc, MArgument *Args,
                                                 MArgument Res) {
  WRITE_CONCERN_GET(wc, 0)
  bool journal = MArgument_getInteger(Args[1]);
  mongoc_write_concern_set_journal(wc, journal);
  return LIBRARY_NO_ERROR;
}