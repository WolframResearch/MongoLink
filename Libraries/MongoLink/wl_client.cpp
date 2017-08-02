////////////////////////////////////////////////////////////////////////////////
// Client-level functions
////////////////////////////////////////////////////////////////////////////////

#include "wl_common.h"

/*----------------------------------------------------------------------------*/

EXTERN_C DLLEXPORT int WL_ClientHandleCreate(WolframLibraryData libData,
                                             mint Argc, MArgument *Args,
                                             MArgument Res) {
  int client_handle_key = MArgument_getInteger(Args[0]);
  URI_GET(uri, 1)

  auto client = mongoc_client_new_from_uri(uri);
  if (!client) {
    errorString = "Invalid URI. Cannot connect to client.";
    return LIBRARY_FUNCTION_ERROR;
  }
  // If connection was successful, add to clientHandleMap
  clientHandleMap[client_handle_key] = client;
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_ClientSetSSL(WolframLibraryData libData, mint Argc,
                                       MArgument *Args, MArgument Res) {
  CLIENT_GET(client, 0)
  char *pem_file = MArgument_getUTF8String(Args[1]);
  char *pem_pwd = MArgument_getUTF8String(Args[2]);
  char *ca_file = MArgument_getUTF8String(Args[3]);
  char *ca_dir = MArgument_getUTF8String(Args[4]);
  char *crl_file = MArgument_getUTF8String(Args[5]);
  bool weak_cert = static_cast<bool>(MArgument_getInteger(Args[6]));
  bool inv_hostname = static_cast<bool>(MArgument_getInteger(Args[7]));

  mongoc_ssl_opt_t ssl_opts = {0};

  ssl_opts.weak_cert_validation = weak_cert;
  ssl_opts.allow_invalid_hostname = inv_hostname;

  // if string length is not zero, set values.
  if (strlen(pem_file) > 0)
    ssl_opts.pem_file = pem_file;

  if (strlen(pem_pwd) > 0)
    ssl_opts.pem_pwd = pem_pwd;

  if (strlen(ca_file) > 0)
    ssl_opts.ca_file = ca_file;

  if (strlen(ca_dir) > 0)
    ssl_opts.ca_dir = ca_dir;

  if (strlen(crl_file) > 0)
    ssl_opts.crl_file = crl_file;

  // Note: "As of 1.4.0, the mongoc_client_pool_set_ssl_opts() and
  // mongoc_client_set_ssl_opts() will not only shallow copy the struct, but
  // will also copy the const char*. It is therefore no longer needed to make
  // sure the values remain valid after setting them."
  // ~ http://mongoc.org/libmongoc/current/mongoc_ssl_opt_t.html
  mongoc_client_set_ssl_opts(client, &ssl_opts);

  // Free strings
  libData->UTF8String_disown(pem_file);
  libData->UTF8String_disown(pem_pwd);
  libData->UTF8String_disown(ca_file);
  libData->UTF8String_disown(ca_dir);
  libData->UTF8String_disown(crl_file);

  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_GetDatabaseNames(WolframLibraryData libData,
                                           MLINK mlp) {
  // Load database handle
  int client_handle;
  int len;
  if (!MLTestHead(mlp, "List", &len) || len != 1)
    return LIBRARY_FUNCTION_ERROR;
  if (!MLGetInteger(mlp, &client_handle))
    return LIBRARY_FUNCTION_ERROR;
  auto client = clientHandleMap[client_handle];

  // Create new output packet
  if (!MLNewPacket(mlp))
    return LIBRARY_FUNCTION_ERROR;

  // Get collection names
  bson_error_t error;
  char **strv;
  int length = 0;
  if ((strv = mongoc_client_get_database_names(client, &error))) {
    for (int i = 0; strv[i]; i++) {
      ++length; // need to know length to initialize output list
    }
  } else {
    errorString = error.message;
    return LIBRARY_FUNCTION_ERROR;
  }

  // If success, loop over string array:
  if (!MLPutFunction(mlp, "List", length))
    return LIBRARY_FUNCTION_ERROR;

  for (int i = 0; i < length; i++)
    if (!MLPutString(mlp, strv[i]))
      return LIBRARY_FUNCTION_ERROR;

  // Free string array
  bson_strfreev(strv);
  // Return
  return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int WL_ClientGetCollection(WolframLibraryData libData,
                                              mint Argc, MArgument *Args,
                                              MArgument Res) {
  CLIENT_GET(client, 0)
  int collection_handle_key = MArgument_getInteger(Args[1]);
  char *databaseName = MArgument_getUTF8String(Args[2]);
  char *collectionName = MArgument_getUTF8String(Args[3]);

  // Create collection handle, append to collectionHandleMap if successfully
  // created.
  // API: http://api.mongodb.org/c/current/mongoc_client_get_collection.html
  auto collection =
      mongoc_client_get_collection(client, databaseName, collectionName);

  if (!collection) {
    errorString = "Cannot connect to collection.";
    return LIBRARY_FUNCTION_ERROR;
  }
  collectionHandleMap[collection_handle_key] = collection;

  // Disown strings
  libData->UTF8String_disown(databaseName);
  libData->UTF8String_disown(collectionName);
  return LIBRARY_NO_ERROR;
}
