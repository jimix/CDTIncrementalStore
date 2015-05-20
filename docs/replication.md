# Replication

## Accessing Your Store Object

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

If you have not already established the link when you added your
persistent store, you may do so by using `-linkReplicators:` and
`-linkReplicators`.

```objc
// link remote database
NSURL *linkURL = [NSURL URLWithString:databaseURI];
[myIS linkReplicators:linkURL];

// unlink current remote database
[myIS unlinkReplicators];
```

### Replication

The act of [replication] can be performed by the
`-pushToRemote:withProgress:` and
`-pullFromRemote:withProgress:`. These methods return immediately
reporting any initial error but do the actual work on another thread.
They employ [code blocks] to provide feedback to the application if
launched successfully.  Example use in iOS using `UIProgressView`:

```objc
NSError *err = nil;
UIProgressView * __weak weakProgress = // some UIProgressView object;
BOOL pull = [myIS pullFromRemote:&err
                    withProgress:^(BOOL end, NSInteger processed, NSInteger total, NSError *e) {
                        if (end) {
					        if (e) // ... deal with error
						    [weakProgress setProgress:1.0 animated:YES];
					    } else {
					        [weakProgress setProgress:(float)processed / (float)total animated:YES];
                        }
                    }];
if (!pull) // .. deal with error in `err`
```

> ***Note***: `withProgress` can be `nil`

Another example that just waits until the replicator is done:

```objc
NSError *err = nil;
NSError * __block pushErr = nil;
BOOL __block done = NO;
BOOL push = [is pushToRemote:&err withProgress:^(BOOL end, NSInteger processed, NSInteger total, NSError *e) {
    if (end) {
        if (e) pushErr = e;
        done = YES;
    } else {
        count = processed;
    }
}];

if (!push) // .. deal with error in `err`

while (!done) {
    [NSThread sleepForTimeInterval:1.0f];
}
```

Synchronization can be taken care of by some combination of push and
pull, see [replication] and [conflicts].

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
