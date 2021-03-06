# MongoDB Link for the Wolfram Language

MongoLink is a package for interacting with MongoDB inside the [Wolfram Language](https://www.wolfram.com/language/). It interfaces to the [MongoDB C driver.](https://docs.mongodb.org/ecosystem/drivers/c/) via LibraryLink.

The design aims to follow the official Mongo API reference (https://docs.mongodb.com/manual/reference/), along with trying to use standard Wolfram Language conventions and options.

Not all functionality in MongoDB is exposed in MongoLink. If you want something that is missing, please request it in the Github Issues. Or better yet, make a PR!

### Installing the MongoLink release

The MongoLink release comes in the form of a `.paclet` file, which contains the entire package and its documentation. Download the latest release from the [Github repo's releases page](https://github.com/WolframResearch/MongoLink/releases). To install, run the following command in the Wolfram Language:
```
PacletInstall["/full/path/to/MongoLink.paclet"]
```
This will permanently install the MongoLink paclet. The Wolfram Language will always use the latest installed version of MongoLink. Installed versions can be enumerated using the command:
```
PacletFind["MongoLink"]
```
And all versions can be uninstalled using the command:
```
PacletUninstall["MongoLink"]
```

### Using MongoLink

To access the documentation, open the notebook interface help viewer, and search for `MongoLink`.

### Where did this come from?

MongoLink is a paclet started and maintained by Sebastian Bodenstein of Wolfram Research. It is used within Wolfram Research by the Machine Learning Group to manage large machine learning datasets.

### Acknowledgements

Much of the documentation was adapted and/or copied from the excellent [PyMongo](https://api.mongodb.com/python/current/) and [MongoDB C Driver](http://mongoc.org/libmongoc/current/index.html) documentation.

### More...

See the following files for more information:

* [COPYING.md](COPYING.md) - MongoLink license
* [CONTRIBUTING.md](CONTRIBUTING.md) - Guidelines for contributing to MongoLink
* [HowToBuild.md](HowToBuild.md) - Instructions for building MongoLink