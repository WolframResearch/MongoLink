## How to build MongoLink

MongoLink has two buildable components: the documentation, and a shared library component which is loaded via LibraryLink.  This document covers only how to build and run the shared library component.

#### Building the Mongo C Driver
Follow the instructions on the Mongo Driver page (http://mongoc.org/libmongoc/current/installing.html). Both build and install the driver. 

#### Building MongoLink
Let `$PacletDir` be the MongoLink base directory. Then:
```
Get@FileNameJoin[{$PacletDir, "Libraries", "Build.wl"}]
BuildMongoLink[]
```
will build MongoLink, and create a folder `LibraryResources` which will contain the built library. 

Equivalently, open the `Notes\LocalBuild.nb` notebook follow the instructions.

`BuildMongoLink[]` assumes you have build the Mongo C Driver and installed it in the default location, (`C:\mongo-c-driver` for Windows). It will fail if the built Mongo C Driver is not in this location.

#### Using the local build of MongoLink
Evaluate the following:
```
PacletDirectoryAdd[{$PacletDir}];
<<MongoLink`
```
You can verify that you are using your own local checkout of MongoLink by running:
```
PacletInformation["MongoLink"]
```