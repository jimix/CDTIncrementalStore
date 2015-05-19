//
//  LocalBatch.m
//  CDTIncrementalStoreTest
//
//  Created by Jimi Xenidis on 5/20/15.
//
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>

#import "Local.h"

@interface LocalBatch : LocalTestCase

@end


@implementation LocalBatch

- (void)testBatchUpdates
{
    int num_entries = 100;
    const double TIME_PRECISION = 0.000001;  // one microsecond

    XCTAssertTrue((num_entries % 4) == 0, @"Test assumes num_entries is mod 4: %d", num_entries);

    NSError *err = nil;
    // This will create the database
    NSManagedObjectContext *moc = self.managedObjectContext;
    XCTAssertNotNil(moc, @"could not create Context");

    moc.stalenessInterval = 0;  // no staleness acceptable

    NSDate *now = [NSDate date];

    for (int i = 0; i < num_entries; i++) {
        Entry *e = MakeEntry(moc);
        e.created_at = [now dateByAddingTimeInterval:(NSTimeInterval)(-num_entries + i)];
        e.text = NSStringFromSelector(_cmd);
        e.check = (i % 2) ? @NO : @YES;
        e.i64 = @(i);
    }

    // push it out
    XCTAssertTrue([moc save:&err], @"Save Failed: %@", err);

    NSArray *results;
    /**
     *  Fetch checked entries
     */
    NSPredicate *checked = [NSPredicate predicateWithFormat:@"check == YES"];

    NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"Entry"];
    fr.shouldRefreshRefetchedObjects = YES;
    fr.predicate = checked;

    err = nil;
    results = [moc executeFetchRequest:fr error:&err];
    XCTAssertNotNil(results, @"Expected results: %@", err);

    XCTAssertTrue([results count] == (num_entries / 2), @"results count should be %d is %lu",
                  num_entries / 2, (unsigned long)[results count]);

    for (Entry *e in results) {
        XCTAssertTrue([e.check boolValue], @"not even?");

        long long val = [e.i64 longLongValue];
        XCTAssertTrue((val % 2) == 0, @"entry.i64 should be even");
    }

    /**
     *  Batch update all objects 50 or higher (should remove 25 checks)
     */
    {
        NSBatchUpdateRequest *req = [[NSBatchUpdateRequest alloc] initWithEntityName:@"Entry"];
        req.predicate = [NSPredicate predicateWithFormat:@"i64>=%d", num_entries / 2];
        req.propertiesToUpdate = @{ @"check" : @(NO) };
        req.resultType = NSUpdatedObjectsCountResultType;
        NSBatchUpdateResult *res = (NSBatchUpdateResult *)[moc executeRequest:req error:&err];

        XCTAssertNotNil(res, @"Expected results: %@", err);
        NSLog(@"%@ objects updated", res.result);

        /**
         *  Fetch checked entries
         */
        fr.predicate = checked;
        results = [moc executeFetchRequest:fr error:&err];
        XCTAssertNotNil(results, @"Expected results: %@", err);

        XCTAssertTrue([results count] == (num_entries / 4), @"results count should be %d is %lu",
                      (num_entries / 4), (unsigned long)[results count]);
    }

    /**
     *  Batch update date, string, integer, and float attributes
     *  Request objectIDs to be returned
     */
    {
        NSBatchUpdateRequest *req = [[NSBatchUpdateRequest alloc] initWithEntityName:@"Entry"];
        req.predicate = [NSPredicate predicateWithFormat:@"check == YES"];
        req.propertiesToUpdate = @{
                                   @"created_at" : now,
                                   @"text" : @"foobar",
                                   @"i16" : @(32),
                                   @"fpFloat" : @(M_PI_2),
                                   @"fpDouble" : @(M_PI)
                                   };
        req.resultType = NSUpdatedObjectIDsResultType;
        NSBatchUpdateResult *res = (NSBatchUpdateResult *)[moc executeRequest:req error:&err];

        XCTAssertNotNil(res, @"Expected results: %@", err);

        XCTAssertTrue([res.result count] == (num_entries / 4), @"results count should be %d is %lu",
                      (num_entries / 4), (unsigned long)[res.result count]);

        [res.result enumerateObjectsUsingBlock:^(NSManagedObjectID *objID, NSUInteger idx,
                                                 BOOL *stop) {
            Entry *e = (Entry *)[moc objectWithID:objID];
            if (![e isFault]) {
                [moc refreshObject:e mergeChanges:YES];
                XCTAssertTrue(fabs([e.created_at timeIntervalSinceDate:now]) < TIME_PRECISION,
                              @"created_at field not updated");
                XCTAssertTrue([e.text isEqualToString:@"foobar"], @"text field not updated");
                XCTAssertTrue([e.i16 intValue] == 32, @"i16 field not updated");
                XCTAssertTrue([e.fpFloat floatValue] == (float)M_PI_2, @"fpDouble field not updated");
                XCTAssertTrue([e.fpDouble doubleValue] == (double)M_PI,
                              @"fpDouble field not updated");
            }
        }];

        /**
         *  Fetch checked entries
         */
        fr.predicate = [NSPredicate predicateWithFormat:@"text == 'foobar'"];
        results = [moc executeFetchRequest:fr error:&err];
        XCTAssertNotNil(results, @"Expected results: %@", err);

        XCTAssertTrue([res.result count] == (num_entries / 4), @"results count should be %d is %lu",
                      (num_entries / 4), (unsigned long)[res.result count]);
    }

    /**
     *  Batch update error case: update specifies field not in managed object
     */
    {
        NSBatchUpdateRequest *req = [[NSBatchUpdateRequest alloc] initWithEntityName:@"Entry"];
        req.predicate = [NSPredicate predicateWithFormat:@"i64>=%d", num_entries / 2];
        req.propertiesToUpdate = @{ @"foobar" : @(NO) };
        req.resultType = NSUpdatedObjectsCountResultType;
        
        XCTAssertThrowsSpecificNamed([moc executeRequest:req error:&err], NSException,
                                     NSInvalidArgumentException, @"Expected Exception");
    }
}


@end
