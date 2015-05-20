# Replication

## Accessing Your Data Store Object

At any time during your application you may decide to access the
remote `CDTDatastore`.  In order to do this from a [Core Data]
application, you need to access the `CDTIncrementalStore` object
instance you require.  Since [Core Data] can have multiple active
stores *and* even several `CDTIncrementalStore` objects, we can use
`+storesFromCoordinator:coordinator` to obtain these objects. If there
is only one `CDTIncrementalStore` object then this is simply:

```objc
// Get our stores
NSArray *stores = [CDTIncrementalStore storesFromCoordinator:psc];
// We know there is only one
CDTIncrementalStore *myIS = [stores firstObject];
```
If there is more than one `CDTIncrementalStore` in `stores` then you
can iterate over stores and compare the URL property.  Example:

```objc
CDTIncrementalStore *myIS;
for (CDTIncrementalStore *mis in stores) {
    if ([storeURL isEqual:mis.URL]) {
        myIS = mis;
        break;
    }
}
```

### Replication

The act of [replication] can be performed by the using the
CloudantSync replication interfaces described in [Replication].

In order to perform a _push_ or a _pull_ you need to obtain a
`CDTISReplicator` that performs the operation. These are provided by
`-replicatorThatPushesToURL:withError:` and
`-replicatorThatPullsFromURL:withError:`.  This object not only
contains a `CDTReplicator` object called `replicator` that is capable
of performing the [replication], it also contains additional methods
to help with merge conflict particularly after a _pull_, these will be
described in detail below.

Once you have a `CDTReplicator` you can use it as instructed in
[Replication], including setting a delegate.

A simple example:

```objc
NSError *err = nil;
CDTIncrementalStore *myIS = <# See: Accessing Your Data Store Object #>
CDTISReplicator *pullerManager = [myIS replicatorThatPullsFromURL:self.remoteURL withError:&err];
CDTReplicator *puller = pullerManager.replicator;

if (![puller startWithError:&err]) {
    [self reportIssue:@"Pull Failed with error: %@", err];
    self.syncButton.enabled = self.serverVerified;
} else {
    while (puller.isActive) {
        [NSThread sleepForTimeInterval:1.0f];
    }
}
```

Synchronization can be taken care of by some combination of _push_ and
_pull_, see the CloudantSync [replication] documents for more
information.

### Conflict Management
Since _pushing_ and _pulling_ happen at the CloudantSync "Datastore"
level, a mechanism to present possible conflicts in a way that is
familiar to the [Core Data] developer is necessary.

Normally, such conflicts are discovered upon saving an
`NSManagedObjectContext` as described in Apple's [Change Management]
documentation.  Ultimately, the programmer is presented with an
`NSArray` of `NSMergeConflict` objects.  These [merge conflict]
objects describe how the managed object has changed between the cached
state at the persistent store coordinator and the external store in
the backing store.

In order to allow these conflicts to be resolved immediately after a
_pull_ has completed, the `CDTISReplicator` object has introduced a
method called `-processConflictsWithContext:error:` which returns the
same `NSArray` of `NSMergeConflict` objects.

This array can be used by the standard [merge policies] provided by
`NSMergePolicyClass` as any [Core Data] application would use.  An
example of using the policy that selects the ones that were _pull_ed in,
over the objects that were active before the _pull_ is as follows:

```objc
// After a successful pull
NSManagedObjectContext *moc =  <# Any active context #>;
NSArray *mergeConflicts = [puller processConflictsWithContext:moc error:nil];
NSMergePolicy *mp = [[NSMergePolicy alloc] initWithMergeType:NSMergeByPropertyStoreTrumpMergePolicyType];
if (![mp resolveConflicts:conflicts error:nil]) {
    // conflict resolution failure
}
```

### Best Practices

1. Save all `NSManagedObjectContext` objects before any replication activity
1. Do not _push_ a Datastore that has conflicts in it.
1. Resolve conflicts immediately after a _pull_.

<!-- refs -->

[core data]: https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CoreData/cdProgrammingGuide.html "Introduction to Core Data Programming Guide"

[replication]:  https://github.com/cloudant/CDTDatastore/blob/master/doc/replication.md "Replicating Data Between Many Devices"

[conflicts]: https://github.com/cloudant/CDTDatastore/blob/master/doc/conflicts.md "Handling conflicts"


<!--  LocalWords:  CDTDatastore CDTIncrementalStore objc NSArray psc
 -->
<!--  LocalWords:  storesFromCoordinator myIS firstObject NSURL iOS
 -->
<!--  LocalWords:  linkReplicators linkURL URLWithString databaseURI
 -->
<!--  LocalWords:  unlink unlinkReplicators pushToRemote withProgress
 -->
<!--  LocalWords:  pullFromRemote UIProgressView NSError weakProgress
 -->
<!--  LocalWords:  BOOL NSInteger setProgress pushErr NSThread
 -->
