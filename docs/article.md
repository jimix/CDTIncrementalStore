# Cloudant Sync and Core Data

So, you have an application that uses Apple's [Core Data], or perhaps
you are considering, and you [should][nshipster], using [Core Data] in
a project that doesn't use it yet.

[Core Data] is an extremely mature framework that enables you to
perform Object-relational Mapping (ORM) like activity on a persistent
store while integrating it further with Objective-C, Swift, and other
Cocoa frameworks. However, there has been no easy way to allow this
data to be replicated among different devices.

> ***Note***: Recently, Apple has made some [progress][icloud] in
> allowing Core Data to sync among iCloud-enabled devices. There are
> benefits and drawbacks to using iCloud, but this discussion is
> beyond the scope of this article.

[Cloudant Sync] gives your device a light weight persistent store that
is geared towards JSON data. The data can be indexed, queried, and,
most importantly, replicated to any device that implements the
replication protocol as defined by [Apache CouchDB][couchdb].

Once you have a remote replication data store, you can then have all
your devices use the remote as a synchronization point, sharing
updates and keeping everything in sync.

But first, let's get started with our [Core Data] application.

# Using Cloudant Sync with Core Data

There are several excellent tutorials available for how to use
[Core Data], and Apple has provided many examples. For our example we
will use the [iPhoneCoreDataRecipes][applerecipe] sample application.

> ***Note***: For convenience, you can find the results of this
> article in the following [git tree][recipe] on [GitHub]. The
> original version of the source is accessible via the `original` git
> tag. You can also use that tag to see the changes via `git diff -r
> original`.

## Getting started

After getting the original version of [Recipe][applerecipe], the first
thing we need to do is hook it up with [CocoaPods].

## Installing CocoaPods

[CocoaPods] is a dependency manager for Objective-C and Swift, which
automates and simplifies the process of using 3rd-party
libraries. CocoaPods is distributed as a ruby gem, and is installed by
running the following commands in Terminal.app:

```bash
$ sudo gem install cocoapods
$ pod setup
```

> Depending on your Ruby installation, you may not have to run as
> `sudo` to install the cocoapods gem.

## Setting up the Pods

We need to create a `Podfile`, which should have the following
contents:

```Podfile
source 'https://github.com/CocoaPods/Specs.git'

xcodeproj 'Recipes'

platform :ios, '7.0'
pod "CDTIncrementalStore"
```

You can also just download it from
[here](https://raw.githubusercontent.com/jimix/iPhoneCoreDataRecipes/master/Podfile).

## Installing the Pods

To install the necessary pods, run the following command:

```bash
$ pod install
```
This creates a workspace directory `Recipe.xcworkspace` that you can
use to start Xcode. From now on, be sure to always open the generated
Xcode workspace instead of the project file when building your
project:

```bash
$ open Recipe.xcworkspace
```

# Code Changes to use CDTIncrementalStore

In order to have the recipe app switch over to `CDTIncrementalStore`
we simply need to migrate the existing data store. We only need to
touch one file `Classes/RecipesAppDelegate.m` and one method
`-persistentStoreCoordinator` to achieve our goal.

You can see this change in
[diff form](https://github.com/jimix/iPhoneCoreDataRecipes/commit/79e9f5d2/?diff=unified)
but we will also walk through the change in detail here.

## 1. Adding the header
At the top of `Classes/RecipesAppDelegate.m` we need to add our header
near the top of the file. I made it the first import.

```objc
#import <CDTIncrementalStore/CDTIncrementalStore.h>
```

## 2. Modify the function
In order to make the change readable while keeping the original
function, I renamed the original `-persistentStoreCoordinator` to be
called `-persistentStoreCoordinatorOriginal` so I could now define a
new version of the function.  Here is the function in its entirety.

```objc
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {

    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
```

Since the method is a "getter" we should all be familiar with the
pattern above.

```objc
    /**
     * Check to see if the CDTIncrementalStore actually exists.  The extension is just for clarification.
     */
    NSString *documentsStorePath =
    [[[self applicationDocumentsDirectory] path] stringByAppendingPathComponent:@"Recipes.cdtis"];

```

We expect to find our [Cloudant Sync] data store at this location. It
can placed anywhere the application is allowed to put it, and this is
the directory that the original application uses.

> ***Note***: the `.cdtis` extension is not necessary in anyway.

We check to see if there is indeed anything at this path, if not, then
we use Core Data to migrate the cooked SQLite Data Store into our
[Cloudant Sync] Data Store. The code comments describe the necessary
steps.

```objc
    // if the expected store doesn't exist, migrate the default store
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentsStorePath]) {
        /**
         *  The application comes with a pre-populated SQLite database with some recipes.
         *  The original version of this function would copy this "cooked" database file and
         *  then add it to the persistent store.  In our new version, we will use Core Data
         *  to migrate the contents into a Cloudant Sync Data Store via the CDTIncrementalStore.
         */
        NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:@"Recipes" ofType:@"sqlite"];
        NSURL *defaultStoreURL = [NSURL fileURLWithPath:defaultStorePath];

        /**
         *  Create an NSPersistentStoreCoordinator for the sole purpose of migrating from SQLite to Cloudant Sync.
         */

        NSPersistentStoreCoordinator *migrationPSC =
        [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

        NSError *error;
        NSPersistentStore *defaultStore =
        [migrationPSC addPersistentStoreWithType:NSSQLiteStoreType
                                   configuration:nil
                                             URL:defaultStoreURL
                                         options:nil
                                           error:&error];
        if (!defaultStore) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }

        /**
         *  Note the `withType:[CDTIncrementalStore type]`.  This is a class method that returns
         *  an NSString that will request that Core Data use CDTIncrementalStore as a backing store.
         */
        NSURL *documentsStoreURL = [NSURL fileURLWithPath:documentsStorePath];
        if (![migrationPSC migratePersistentStore:defaultStore
                                            toURL:documentsStoreURL
                                          options:nil
                                         withType:[CDTIncrementalStore type]
                                            error:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
```

At this point, we know our Cloudant Sync Database exists and we create
a new `NSPersistentStoreCoordinator` to use it.

```objc
    _persistentStoreCoordinator =
    [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];


    // add the default store to our coordinator
    NSError *error;
    NSURL *defaultStoreURL = [NSURL fileURLWithPath:documentsStorePath];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:[CDTIncrementalStore type]
                                                   configuration:nil
                                                             URL:defaultStoreURL
                                                         options:nil
                                                           error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    /**
     *  It is important to note that the original code uses two Persistent Stores, one that holds
     *  the original set and another store for the user's personal recipes.  We skip this step
     *  for simplicity.
     */

    return _persistentStoreCoordinator;
}
```

This is all that was necessary to convert the Recipes app to use the
Cloudant Sync Data Store.  In the next section we will describe how to
use replication to get several devices sharing the same recipes.

## Extra Credit

The Recipes app uses a transformable object to keep images of the
food.  Core Data requires a class to be defined as an extension to
`NSValueTransformer` that is responsible for converting an object
instance to something that can be stored into the Data Store.  The
Recipes app defines `ImageToDataTransformer` to do this.

When using `CDTIncrementalStore` these objects are stored as
attachments to the data store. There are various reasons to do this
which is beyond the scope of our discussion here, however it is
advantageous to associate a MIME type to these objects if it is
known. To do this we can add a static method called `+MIMEType` to the
implementation of `ImageToDataTransformer`, like so:

```objc
@implementation ImageToDataTransformer

+ (NSString *)MIMEType {
    return @"image/png";
}
```

# The Remote Data Store

There are a few options for creating a remote data store. You may
choose to deploy an instance of [CouchDB] on your local machine or a
server your devices will have access to. Documents on installing and
configuring this server for your platform of choice can be found at
the [Apache Site](http://docs.couchdb.org/en/latest/).

For the remainder of this article we will use IBM's
[Cloudant Hosting Service][cloudant] which allows for customers to
create Cloudant Databases that are compatible with [CouchDB] but can
offer so much more. IBM also offers a rich developer program that make
it easy, and with little risk (***free!***), to try out their service.

# Getting Started with Cloudant

You can sign up for a [Cloudant] service at their site. Once you have
registered and have launched into the dashboard, you will be given the
opportunity to add a new database.

<!-- references -->

[core data]: https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CoreData/cdProgrammingGuide.html "Introduction to Core Data Programming Guide"
[nshipster]: http://nshipster.com/core-data-libraries-and-utilities/ "Core Data Libraries & Utilities"
[cloudant sync]: https://github.com/cloudant/CDTDatastore "Cloudant Sync iOS datastore library"
[icloud]: https://developer.apple.com/library/ios/documentation/DataManagement/Conceptual/UsingCoreDataWithiCloudPG/Introduction/Introduction.html "About Using iCloud with Core Data"
[couchdb]: http://couchdb.apache.org/
[applerecipe]: https://developer.apple.com/library/ios/samplecode/iPhoneCoreDataRecipes/Introduction/Intro.html "iPhoneCoreDataRecipes"
[github]: https://github.com "GitHub"
[recipe]: https://github.com/jimix/iPhoneCoreDataRecipes
[cocoapods]: http://cocoapods.org "CocoaPods"
[cloudant]: https://cloudant.com/

<!--  LocalWords:  Cloudant nshipster ORM icloud iCloud JSON CouchDB
 -->
<!--  LocalWords:  couchdb iPhoneCoreDataRecipes applerecipe GitHub
 -->
<!--  LocalWords:  CocoaPods sudo cocoapods Podfile xcodeproj ios pre
 -->
<!--  LocalWords:  CDTIncrementalStore workspace xcworkspace Xcode
 -->
<!--  LocalWords:  persistentStoreCoordinator objc getter NSString
 -->
<!--  LocalWords:  persistentStoreCoordinatorOriginal cdtis SQLite
 -->
<!--  LocalWords:  NSPersistentStoreCoordinator documentsStorePath
 -->
<!--  LocalWords:  applicationDocumentsDirectory NSFileManager ofType
 -->
<!--  LocalWords:  stringByAppendingPathComponent defaultManager png
 -->
<!--  LocalWords:  fileExistsAtPath defaultStorePath NSBundle sqlite
 -->
<!--  LocalWords:  mainBundle pathForResource NSURL defaultStoreURL
 -->
<!--  LocalWords:  fileURLWithPath migrationPSC alloc NSError NSLog
 -->
<!--  LocalWords:  initWithManagedObjectModel managedObjectModel iOS
 -->
<!--  LocalWords:  NSPersistentStore defaultStore NSSQLiteStoreType
 -->
<!--  LocalWords:  addPersistentStoreWithType userInfo withType toURL
 -->
<!--  LocalWords:  documentsStoreURL migratePersistentStore MIMEType
 -->
<!--  LocalWords:  NSValueTransformer ImageToDataTransformer cloudant
 -->
<!--  LocalWords:  debugmagic NSHipster datastore github
 -->
