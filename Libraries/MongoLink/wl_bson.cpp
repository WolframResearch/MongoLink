////////////////////////////////////////////////////////////////////////////////
// BSON functions
//	- For API guide, see: http://mongoc.org/libbson/current/index.html
////////////////////////////////////////////////////////////////////////////////

#include "wl_common.h"

////////////////////////////////////////////////////////////////////////////////

EXTERN_C DLLEXPORT int WL_CreateBSONfromJSON(WolframLibraryData libData,
                                             mint Argc, MArgument *Args,
                                             MArgument Res) {
  int bson_handle_key = MArgument_getInteger(Args[0]);
  char *json = MArgument_getUTF8String(Args[1]);

  bson_error_t error;
  auto b = bson_new_from_json((const uint8_t *)json, -1, &error);
  if (!b) {
    errorString = error.message;
    libData->UTF8String_disown(json);
    return LIBRARY_FUNCTION_ERROR;
  }
  bsonHandleMap[bson_handle_key] = b;
  // Disown string
  libData->UTF8String_disown(json);
  return LIBRARY_NO_ERROR;
}

////////////////////////////////////////////////////////////////////////////////

EXTERN_C DLLEXPORT int WL_bsonAsJSON(WolframLibraryData libData, mint Argc,
                                     MArgument *Args, MArgument Res) {
  BSON_GET(bson, 0)
  if (returnBSONJSON) {
    bson_free(returnBSONJSON);
  }
  returnBSONJSON = bson_as_json(bson, NULL);
  MArgument_setUTF8String(Res, returnBSONJSON);
  return LIBRARY_NO_ERROR;
}

////////////////////////////////////////////////////////////////////////////////

EXTERN_C DLLEXPORT int WL_raw_array_to_bson(WolframLibraryData libData,
                                            mint Argc, MArgument *Args,
                                            MArgument Res) {
  int bson_handle_key = MArgument_getInteger(Args[0]);
  MRawArray data_tensor = MArgument_getMRawArray(Args[1]);

  size_t size = libData->rawarrayLibraryFunctions->MRawArray_getFlattenedLength(
      data_tensor);
  auto data = reinterpret_cast<uint8_t *>(
      libData->rawarrayLibraryFunctions->MRawArray_getData(data_tensor));

  auto b = bson_new_from_data(data, size);
  if (!b)
    return LIBRARY_FUNCTION_ERROR;

  bsonHandleMap[bson_handle_key] = b;
  return LIBRARY_NO_ERROR;
}

////////////////////////////////////////////////////////////////////////////////

EXTERN_C DLLEXPORT int WL_bson_to_rawarray(WolframLibraryData libData,
                                           mint Argc, MArgument *Args,
                                           MArgument Res) {
  BSON_GET(bson, 0)
  auto data = bson_get_data(bson);
  mint dims[1] = {bson->len};

  MRawArray output_raw;
  libData->rawarrayLibraryFunctions->MRawArray_new(MRawArray_Type_Ubit8, 1,
                                                   dims, &output_raw);

  auto data_raw = reinterpret_cast<uint8_t *>(
      libData->rawarrayLibraryFunctions->MRawArray_getData(output_raw));
  std::copy(data, data + bson->len, data_raw);

  // Return RawArray
  MArgument_setMRawArray(Res, output_raw);
  return LIBRARY_NO_ERROR;
}

////////////////

/*
 * Structures.
 */

typedef struct {
  uint32_t count;
  bool keys;
  uint32_t depth;
  MLINK *wstp_state;
} bson_wl_state_t;

/*
 * Forward declarations.
 */
static bool _bson_as_wl_visit_array(const bson_iter_t *iter, const char *key,
                                    const bson_t *v_array, void *data);
static bool _bson_as_wl_visit_document(const bson_iter_t *iter, const char *key,
                                       const bson_t *v_document, void *data);

bool _bson_as_wl_visit_before(const bson_iter_t *iter, const char *key,
                              void *data) {
  auto s = reinterpret_cast<bson_wl_state_t *>(data);

  s->count++;
  MLINK *mlp = s->wstp_state;

  if (s->keys) {
    MLPutFunction(*mlp, "Rule", 2);
    MLPutString(*mlp, key);
  }

  return false;
}

bool _bson_as_wl_visit_after(const bson_iter_t *iter, const char *key,
                             void *data) {
  return false;
}

/* normal bson field callbacks */
bool _bson_as_wl_visit_double(const bson_iter_t *iter, const char *key,
                              double v_double, void *data) {
  std::cout << "double!!!!!!!!!!!!!" << std::endl;
  MLINK *mlp = reinterpret_cast<bson_wl_state_t *>(data)->wstp_state;
  MLPutReal64(*mlp, v_double);
  return false;
}

bool _bson_as_wl_visit_utf8(const bson_iter_t *iter, const char *key,
                            size_t v_utf8_len, const char *v_utf8, void *data) {
  MLINK *mlp = reinterpret_cast<bson_wl_state_t *>(data)->wstp_state;
  MLPutString(*mlp, v_utf8);
  return true;
}

bool _bson_as_wl_visit_binary(const bson_iter_t *iter, const char *key,
                              bson_subtype_t v_subtype, size_t v_binary_len,
                              const uint8_t *v_binary, void *data) {
  MLINK *mlp = reinterpret_cast<bson_wl_state_t *>(data)->wstp_state;
  MLPutFunction(*mlp, "ByteArray", 1);
  MLPutInteger8List(*mlp, (unsigned char *)v_binary,
                    static_cast<int>(v_binary_len));
  return false;
}

/* normal field with deprecated "Undefined" BSON type */
bool _bson_as_wl_visit_undefined(const bson_iter_t *iter, const char *key,
                                 void *data) {
  return false;
}

bool _bson_as_wl_visit_oid(const bson_iter_t *iter, const char *key,
                           const bson_oid_t *v_oid, void *data) {
  MLINK *mlp = reinterpret_cast<bson_wl_state_t *>(data)->wstp_state;
  MLPutFunction(*mlp, "BSONObjectID", 1);
  MLPutFunction(*mlp, "ByteArray", 1);
  MLPutInteger8List(*mlp, (unsigned char *)(v_oid->bytes), 12);
  return false;
}

bool _bson_as_wl_visit_bool(const bson_iter_t *iter, const char *key,
                            bool v_bool, void *data) {
  MLINK *mlp = reinterpret_cast<bson_wl_state_t *>(data)->wstp_state;
  if (v_bool)
    MLPutSymbol(*mlp, "True");
  else
    MLPutSymbol(*mlp, "False");

  return false;
}

bool _bson_as_wl_visit_date_time(const bson_iter_t *iter, const char *key,
                                 int64_t msec_since_epoch, void *data) {
  MLINK *mlp = reinterpret_cast<bson_wl_state_t *>(data)->wstp_state;
  MLPutFunction(*mlp, "MongoLink`PackageScope`FromMillisecondUnixTime", 1);
  MLPutInteger64(*mlp, static_cast<mlint64>(msec_since_epoch));
  return false;
}

bool _bson_as_wl_visit_null(const bson_iter_t *iter, const char *key,
                            void *data) {
  MLINK *mlp = reinterpret_cast<bson_wl_state_t *>(data)->wstp_state;
  MLPutSymbol(*mlp, "Null");
  return false;
}

bool _bson_as_wl_visit_regex(const bson_iter_t *iter, const char *key,
                             const char *v_regex, const char *v_options,
                             void *data) {
  return false;
}

bool _bson_as_wl_visit_dbpointer(const bson_iter_t *iter, const char *key,
                                 size_t v_collection_len,
                                 const char *v_collection,
                                 const bson_oid_t *v_oid, void *data) {
  return false;
}

bool _bson_as_wl_visit_code(const bson_iter_t *iter, const char *key,
                            size_t v_code_len, const char *v_code, void *data) {
  return false;
}

bool _bson_as_wl_visit_symbol(const bson_iter_t *iter, const char *key,
                              size_t v_symbol_len, const char *v_symbol,
                              void *data) {
  MLINK *mlp = reinterpret_cast<bson_wl_state_t *>(data)->wstp_state;
  MLPutSymbol(*mlp, v_symbol);
  return false;
}

bool _bson_as_wl_visit_codewscope(const bson_iter_t *iter, const char *key,
                                  size_t v_code_len, const char *v_code,
                                  const bson_t *v_scope, void *data) {
  return false;
}

bool _bson_as_wl_visit_int32(const bson_iter_t *iter, const char *key,
                             int32_t v_int32, void *data) {
  MLINK *mlp = reinterpret_cast<bson_wl_state_t *>(data)->wstp_state;
  MLPutInteger32(*mlp, static_cast<int>(v_int32));
  return false;
}

bool _bson_as_wl_visit_timestamp(const bson_iter_t *iter, const char *key,
                                 uint32_t v_timestamp, uint32_t v_increment,
                                 void *data) {
  return false;
}

bool _bson_as_wl_visit_int64(const bson_iter_t *iter, const char *key,
                             int64_t v_int64, void *data) {
  MLINK *mlp = reinterpret_cast<bson_wl_state_t *>(data)->wstp_state;
  MLPutInteger64(*mlp, static_cast<mlint64>(v_int64));
  return false;
}

bool _bson_as_wl_visit_maxkey(const bson_iter_t *iter, const char *key,
                              void *data) {
  MLINK *mlp = reinterpret_cast<bson_wl_state_t *>(data)->wstp_state;
  MLPutSymbol(*mlp, "Infinity");
  return false;
}

bool _bson_as_wl_visit_minkey(const bson_iter_t *iter, const char *key,
                              void *data) {
  MLINK *mlp = reinterpret_cast<bson_wl_state_t *>(data)->wstp_state;
  MLPutFunction(*mlp, "Minus", 1);
  MLPutSymbol(*mlp, "Infinity");
  return false;
}

bool _bson_as_wl_visit_decimal128(const bson_iter_t *iter, const char *key,
                                  const bson_decimal128_t *v_decimal128,
                                  void *data) {
  std::cout << "asdjfioasdfoiasjdf" << std::endl;
  return false;
}

// See http://mongoc.org/libbson/current/bson_visitor_t.html
const bson_visitor_t bson_as_wl_visitors = {
    _bson_as_wl_visit_before,
    NULL, /* visit_after */
    NULL, /* visit_corrupt */
    _bson_as_wl_visit_double,
    _bson_as_wl_visit_utf8,
    _bson_as_wl_visit_document,
    _bson_as_wl_visit_array,
    _bson_as_wl_visit_binary,
    _bson_as_wl_visit_undefined,
    _bson_as_wl_visit_oid,
    _bson_as_wl_visit_bool,
    _bson_as_wl_visit_date_time,
    _bson_as_wl_visit_null,
    _bson_as_wl_visit_regex,
    _bson_as_wl_visit_dbpointer,
    _bson_as_wl_visit_code,
    _bson_as_wl_visit_symbol,
    _bson_as_wl_visit_codewscope,
    _bson_as_wl_visit_int32,
    _bson_as_wl_visit_timestamp,
    _bson_as_wl_visit_int64,
    _bson_as_wl_visit_maxkey,
    _bson_as_wl_visit_minkey,
    NULL, /* visit_unsupported_type */
    _bson_as_wl_visit_decimal128,
};

static bool _bson_as_wl_visit_document(const bson_iter_t *iter, const char *key,
                                       const bson_t *v_document, void *data) {
  bson_wl_state_t *state = reinterpret_cast<bson_wl_state_t *>(data);
  MLINK *mlp = reinterpret_cast<bson_wl_state_t *>(data)->wstp_state;
  bson_wl_state_t child_state = {0, true};
  bson_iter_t child;

  // should add check for max recursion

  if (bson_iter_init(&child, v_document)) {
    int num_initial_keys = static_cast<int>(bson_count_keys(v_document));
    MLPutFunction(*mlp, "Association", num_initial_keys);
    child_state.wstp_state = mlp;
    child_state.depth = state->depth + 1;
    bson_iter_visit_all(&child, &bson_as_wl_visitors, &child_state);
  }
  return false;
}

static bool _bson_as_wl_visit_array(const bson_iter_t *iter, const char *key,
                                    const bson_t *v_array, void *data) {
  bson_wl_state_t *state = reinterpret_cast<bson_wl_state_t *>(data);
  MLINK *mlp = reinterpret_cast<bson_wl_state_t *>(data)->wstp_state;
  bson_wl_state_t child_state = {0, false};
  bson_iter_t child;

  // should add check for max recursion

  if (bson_iter_init(&child, v_array)) {
    int num_initial_keys = static_cast<int>(bson_count_keys(v_array));
    MLPutFunction(*mlp, "List", num_initial_keys);
    child_state.wstp_state = mlp;
    child_state.depth = state->depth + 1;
    bson_iter_visit_all(&child, &bson_as_wl_visitors, &child_state);
  }

  return false;
}

EXTERN_C DLLEXPORT int WL_ParseBSON(WolframLibraryData libData, MLINK mlp) {
  // Load write concern handle
  int bson_handle;
  int len;
  if (!MLTestHead(mlp, "List", &len) || len != 1)
    return LIBRARY_FUNCTION_ERROR;
  if (!MLGetInteger(mlp, &bson_handle))
    return LIBRARY_FUNCTION_ERROR;
  bson_t *bson = bsonHandleMap[bson_handle];

  // Read bson into LinkObject
  if (!MLNewPacket(mlp))
    return LIBRARY_FUNCTION_ERROR;

  // check for empty bson, return empty assoc
  if (!bson || bson_empty(bson)) {
    if (!MLPutFunction(mlp, "Association", 0))
      return LIBRARY_FUNCTION_ERROR;
    return LIBRARY_NO_ERROR;
  }

  bson_iter_t iter;
  if (!bson_iter_init(&iter, bson)) {
    return LIBRARY_FUNCTION_ERROR;
  }

  bson_wl_state_t state;
  state.count = 0;
  state.keys = true;
  state.wstp_state = &mlp;
  state.depth = 0;

  int num_initial_keys = static_cast<int>(bson_count_keys(bson));
  MLPutFunction(mlp, "Association", num_initial_keys);

  if (bson_iter_visit_all(&iter, &bson_as_wl_visitors, &state) ||
      iter.err_off) {
    // We were prematurely exited due to corruption or failed visitor.
    return LIBRARY_FUNCTION_ERROR;
  }
  std::cout << "hello2" << std::endl;
  return LIBRARY_NO_ERROR;
}
