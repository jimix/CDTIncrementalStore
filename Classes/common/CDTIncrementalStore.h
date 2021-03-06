//
//  CDTIncrementalStore.h
//  CDTIncrementalStore
//
//  Created by Jimi Xenidis on 11/18/14.
//
//  Copyright (c) 2015 IBM. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.
//

#import <CoreData/CoreData.h>
#import <CloudantSync.h>

#include <Availability.h>

#import "CDTISReplicator.h"

extern NSString *const CDTISErrorDomain;
extern NSString *const CDTISException;

/**
 * Feature Tests
 */

#if (__MAC_OS_X_VERSION_MAX_ALLOWED >= 101000) || (__IPHONE_OS_VERSION_MAX_ALLOWED >= 80100)

#define HAS_NSAsynchronousFetchRequest 1
#define HAS_NSBatchUpdateRequest 1

#endif


/**
 * CDTIncrementalStore is an abstract superclass defining the API through which
 * an application can use CDTDatastore as a persistent store for a Core Data
 * application.
 */
@interface CDTIncrementalStore : NSIncrementalStore

/**
 *  Returns the string that was used to register this incremental store
 *
 *  @return NSString
 */
+ (NSString *)type;

/**
 *  Returns an array of @ref CDTIncrementalStore objects associated with a
 *  @ref NSPersistentStoreCoordinator
 *
 *  @param coordinator The coordinator
 *
 *  @return the array
 */
+ (NSArray *)storesFromCoordinator:(NSPersistentStoreCoordinator *)coordinator;

typedef NS_ENUM(NSInteger, CDTIncrementalStoreErrors) {
    CDTISErrorBadURL = 1,
    CDTISErrorBadPath,
    CDTISErrorNilObject,
    CDTISErrorUndefinedAttributeType,
    CDTISErrorObjectIDAttributeType,
    CDTISErrorNaN,
    CDTISErrorRevisionIDMismatch,
    CDTISErrorExectueRequestTypeUnkown,
    CDTISErrorExectueRequestFetchTypeUnkown,
    CDTISErrorMetaDataMismatch,
    CDTISErrorNoRemoteDB,
    CDTISErrorSyncBusy,
    CDTISErrorReplicationFactory,
    CDTISErrorNotSupported
};

/**
 *  The databaseName is exposed in order to be able to identify the different
 *  CDTIncrementalStore objects. @see +storesFromCoordinator:coordinator
 */
@property (nonatomic, strong) NSString *databaseName;

/**
 *  Create a dictionary of values from the Document Body and Blob Store
 *
 *  @param body      body of document
 *  @param blobStore blobStore attachement dictionary
 *  @param context   context from Core Data
 *  @param version   version
 *
 *  @return dictionary
 */
- (NSDictionary *)valuesFromDocumentBody:(NSDictionary *)body
                           withBlobStore:(NSDictionary *)blobStore
                             withContext:(NSManagedObjectContext *)context
                              versionPtr:(uint64_t *)version;

/**
 *  Internal
 */
- (NSManagedObject *)managedObjectForEntityName:(NSString *)name
                                referenceObject:(NSString *)ref
                                        context:(NSManagedObjectContext *)context;

/**
 * Create a CDTReplicator object set up to replicate changes from the
 * local datastore to a remote database.
 *
 *  @param remoteURL the remote server URL to which the data is replicated.
 *  @param error     report error information
 *
 *  @return a CDTReplicator instance which can be used to start and
 *  stop the replication itself, or `nil` on error.
 */
- (CDTISReplicator *)replicatorThatPushesToURL:(NSURL *)remoteURL withError:(NSError **)error;

/**
 * Create a CDTReplicator object set up from replicate changes from a remote database to the
 * local datastore.
 *
 *  @param remoteURL the remote server URL to which the data is replicated.
 *  @param error     report error information
 *
 *  @return a CDTReplicator instance which can be used to start and
 *  stop the replication itself, or `nil` on error.
*/
- (CDTISReplicator *)replicatorThatPullsFromURL:(NSURL *)remoteURL withError:(NSError **)error;

@end
