//
//  LocalFetch.m
//  CDTIncrementalStoreTest
//
//  Created by Jimi Xenidis on 5/20/15.
//
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>

#import "Local.h"


@interface LocalFetch: LocalTestCase

@end


@implementation LocalFetch

static void *ISContextProgress = &ISContextProgress;
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == ISContextProgress) {
        NSProgress *progress = object;
        NSLog(@"Progress: %@ / %@", @(progress.completedUnitCount), @(progress.totalUnitCount));
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)testAsyncFetch
{
    int max = 5000;
    NSUInteger __block completed = 0;

    NSError *err = nil;
    // This will create the database and wire everything up
    NSManagedObjectContext *moc = self.managedObjectContext;
    XCTAssertNotNil(moc, @"could not create Context");

    for (int i = 0; i < max; i++) {
        Entry *e = MakeEntry(moc);
        // check will indicate if value is an even number
        e.check = (i % 2) ? @NO : @YES;
        e.i64 = @(i);
        e.fpFloat = @(((float)(M_PI)) * (float)i);
        e.text = [NSString stringWithFormat:@"%u", (max * 10) + i];

        if ((i % (max / 10)) == 0) {
            NSLog(@"Saving %u of %u", i, max);
            XCTAssertTrue([moc save:&err], @"Save Failed: %@", err);
        }
    }
    NSLog(@"Saving %u of %u", max, max);
    XCTAssertTrue([moc save:&err], @"Save Failed: %@", err);

    // create other context that will fetch from our store
    NSManagedObjectContext *otherMOC =
    [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    XCTAssertNotNil(otherMOC, @"could not create Context");
    [otherMOC setPersistentStoreCoordinator:self.persistentStoreCoordinator];

    NSPredicate *even = [NSPredicate predicateWithFormat:@"check == YES"];
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"i64" ascending:YES];
    NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"Entry"];
    fr.shouldRefreshRefetchedObjects = YES;
    fr.predicate = even;
    fr.sortDescriptors = @[ sd ];
    // this does not do anything, but maybe it will one day
    fr.fetchBatchSize = 10;

    NSAsynchronousFetchRequest *asyncFetch = [[NSAsynchronousFetchRequest alloc]
                                              initWithFetchRequest:fr
                                              completionBlock:^(NSAsynchronousFetchResult *result) {
                                                  NSLog(@"Final: %@", @(result.finalResult.count));
                                                  [result.progress removeObserver:self
                                                                       forKeyPath:@"completedUnitCount"
                                                                          context:ISContextProgress];
                                                  [result.progress removeObserver:self
                                                                       forKeyPath:@"totalUnitCount"
                                                                          context:ISContextProgress];
                                                  completed = result.finalResult.count;
                                              }];

    [otherMOC performBlock:^{
        // Create Progress
        NSProgress *progress = [NSProgress progressWithTotalUnitCount:1];

        // Become Current
        [progress becomeCurrentWithPendingUnitCount:1];

        // Execute Asynchronous Fetch Request
        NSError *err = nil;
        NSAsynchronousFetchResult *asyncFetchResult =
        (NSAsynchronousFetchResult *)[otherMOC executeRequest:asyncFetch error:&err];

        if (err) {
            NSLog(@"Unable to execute asynchronous fetch result: %@", err);
        }

        // Add Observer
        [asyncFetchResult.progress addObserver:self
                                    forKeyPath:@"completedUnitCount"
                                       options:NSKeyValueObservingOptionNew
                                       context:ISContextProgress];
        [asyncFetchResult.progress addObserver:self
                                    forKeyPath:@"totalUnitCount"
                                       options:NSKeyValueObservingOptionNew
                                       context:ISContextProgress];
        // Resign Current
        [progress resignCurrent];
        
    }];
    
    while (completed == 0) {
        [NSThread sleepForTimeInterval:1.0f];
    }
    XCTAssertTrue(completed == max / 2, @"completed should be %@ is %@", @(completed), @(max));
}

- (void)testFetchConstraints
{
    int max = 100;
    int limit = 10;
    int offset = 50;

    XCTAssertTrue(offset + limit <= max && offset - limit >= 0,
                  @"test parameters out of legal range");

    NSError *err = nil;
    // This will create the database
    NSManagedObjectContext *moc = self.managedObjectContext;
    XCTAssertNotNil(moc, @"could not create Context");

    for (int i = 0; i < max; i++) {
        Entry *e = MakeEntry(moc);
        e.i64 = @(i);
        e.text = [NSString stringWithFormat:@"%u", (max * 10) + i];
    }

    // push it out
    XCTAssertTrue([moc save:&err], @"Save Failed: %@", err);

    NSArray *results;
    /**
     *  We will sort by number first
     */
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"i64" ascending:YES];

    NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"Entry"];
    fr.shouldRefreshRefetchedObjects = YES;
    fr.sortDescriptors = @[ sd ];
    fr.fetchLimit = limit;
    fr.fetchOffset = offset;

    results = [moc executeFetchRequest:fr error:&err];
    XCTAssertNotNil(results, @"Expected results: %@", err);

    XCTAssertTrue([results count] == limit, @"results count should be %d is %@", limit,
                  @([results count]));
    long long last = offset - 1;
    for (Entry *e in results) {
        long long val = [e.i64 longLongValue];
        XCTAssertTrue(val >= offset && val < offset + limit,
                      @"entry is out of range [%d, %d): %lld", offset, offset + limit, val);
        XCTAssertTrue(val == last + 1, @"unexpected entry %@: %@", @(val), e);
        ++last;
    }

    /**
     *  now by string, descending just for fun
     */
    sd = [NSSortDescriptor sortDescriptorWithKey:@"text" ascending:NO];

    fr.sortDescriptors = @[ sd ];
    results = [moc executeFetchRequest:fr error:&err];
    XCTAssertNotNil(results, @"Expected results: %@", err);

    XCTAssertTrue([results count] == limit, @"results count should be %d is %@", limit,
                  @([results count]));
    last = offset;
    for (Entry *e in results) {
        long long val = [e.i64 longLongValue];
        XCTAssertTrue(val >= offset - limit && val < offset,
                      @"entry is out of range [%d, %d): %lld", offset - limit, offset, val);
        XCTAssertTrue(val == last - 1, @"unexpected entry %@: %@", @(val), e);
        --last;
    }
}


@end