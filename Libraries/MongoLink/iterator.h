#ifndef ITERATOR_H_INCLUDED
#define ITERATOR_H_INCLUDED

#include <map>
#include <iostream>

#include <bcon.h>
#include <mongoc.h>
#include <bson.h>

#include "common.h"

////////////////////////////////////////////////////////////////////////////////

DLLEXPORT void manage_instance_mongoiterator(WolframLibraryData libData,
                                             mbool mode, mint id);

////////////////////////////////////////////////////////////////////////////////

#endif
