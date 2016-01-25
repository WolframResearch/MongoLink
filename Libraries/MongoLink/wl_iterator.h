#ifndef WL_ITERATOR_H_INCLUDED
#define WL_ITERATOR_H_INCLUDED

#include <map>
#include <iostream>

#include <bcon.h>
#include <mongoc.h>
#include <bson.h>

#include "wl_common.h"

////////////////////////////////////////////////////////////////////////////////

DLLEXPORT void manage_instance_mongoiterator(WolframLibraryData libData,
                                             mbool mode, mint id);

EXTERN_C DLLEXPORT int WL_IteratorHasNext(WolframLibraryData libData, mint Argc,
                                          MArgument *Args, MArgument Res);

EXTERN_C DLLEXPORT int WL_IteratorNext(WolframLibraryData libData, mint Argc,
                                       MArgument *Args, MArgument Res);
////////////////////////////////////////////////////////////////////////////////

#endif
