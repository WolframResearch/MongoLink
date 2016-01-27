# MongoDB Link
A WL link to the [MongoDB C driver.](https://docs.mongodb.org/ecosystem/drivers/c/)


## Building

* First, follow the installation instructions of Mongo C driver: http://api.mongodb.org/c/current/installing.html

* Run the build script: `mongolink/Libraries/build.nb`

* To use the examples, you need to install then run a MongoDB server on your local machine: https://docs.mongodb.org/manual/administration/install-community/

## Running

* See `mongolink/Notes/MongoDBLink.nb` for examples.
* To run this: either require GeneralUtilities checked out (it makes use of its new iterator framework), or a new 10.4 build. In either case, you need to set this correctly at the top of the `MongoDBLink.nb` notebook.
