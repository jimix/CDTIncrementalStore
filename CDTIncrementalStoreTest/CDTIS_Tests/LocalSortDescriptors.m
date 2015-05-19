//
//  LocalSortDescriptors.m
//  CDTIncrementalStoreTest
//
//  Created by Jimi Xenidis on 5/20/15.
//
//


#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>

#import "Local.h"

@interface LocalSortDescriptors: LocalTestCase

@end


@implementation LocalSortDescriptors

- (void)testSortDescriptors
{
    int num_entries = 20;

    NSError *err = nil;
    // This will create the database
    NSManagedObjectContext *moc = self.managedObjectContext;
    XCTAssertNotNil(moc, @"could not create Context");

    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-num_entries];

    for (int i = 0; i < num_entries; i++) {
        Entry *e = MakeEntry(moc);
        // check will indicate if value is an even number
        e.check = (i % 2) ? @NO : @YES;
        e.created_at = [startDate dateByAddingTimeInterval:(NSTimeInterval)((i / 4) * 4)];
        e.i64 = @(i);
        e.fpFloat = @(((float)(M_PI)) * (float)i);
        e.text = [NSString stringWithFormat:@"%u", (num_entries * 10) + i];
    }

    // push it out
    XCTAssertTrue([moc save:&err], @"Save Failed: %@", err);

    NSArray *results;
    /**
     *  Fetch checked items sorted by created_at
     */
    {
        NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"Entry"];
        fr.predicate = [NSPredicate predicateWithFormat:@"check == YES"];
        fr.sortDescriptors =
        @[ [NSSortDescriptor sortDescriptorWithKey:@"created_at" ascending:YES] ];
        fr.shouldRefreshRefetchedObjects = YES;

        results = [moc executeFetchRequest:fr error:&err];
        XCTAssertNil(err, @"Expected no error but got: %@", err);

        XCTAssertTrue([results count] == (num_entries / 2), @"results count should be %d is %@",
                      num_entries / 2, @([results count]));

        NSDate *prevDate = ((Entry *)results.firstObject).created_at;
        for (Entry *e in results) {
            XCTAssertTrue([e.created_at timeIntervalSinceDate:prevDate] >= 0,
                          @"dates are out of order");
            prevDate = e.created_at;
        }
    }

    NSLog(@"Success");
}

- (void)testMultipleSortDescriptors
{
    int num_entries = 20;

    NSError *err = nil;
    // This will create the database
    NSManagedObjectContext *moc = self.managedObjectContext;
    XCTAssertNotNil(moc, @"could not create Context");

    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-num_entries];

    for (int i = 0; i < num_entries; i++) {
        Entry *e = MakeEntry(moc);
        // check will indicate if value is an even number
        e.check = (i % 2) ? @NO : @YES;
        e.created_at = [startDate dateByAddingTimeInterval:(NSTimeInterval)((i / 4) * 4)];
        e.i64 = @(i);
        e.fpFloat = @(((float)(M_PI)) * (float)i);
        e.text = [NSString stringWithFormat:@"%u", (num_entries * 10) + i];
    }

    // push it out
    XCTAssertTrue([moc save:&err], @"Save Failed: %@", err);

    NSArray *results;
    /**
     *  Fetch unchecked items sorted by created_at (decending) and by i64 (ascending)
     */
    {
        NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"Entry"];
        fr.predicate = [NSPredicate predicateWithFormat:@"check == YES"];
        fr.sortDescriptors = @[
                               [NSSortDescriptor sortDescriptorWithKey:@"created_at" ascending:NO],
                               [NSSortDescriptor sortDescriptorWithKey:@"i64" ascending:YES]
                               ];
        fr.shouldRefreshRefetchedObjects = YES;

        results = [moc executeFetchRequest:fr error:&err];
        XCTAssertNil(err, @"Expected no error but got: %@", err);

        XCTAssertTrue([results count] == (num_entries / 2), @"results count should be %d is %@",
                      num_entries / 2, @([results count]));

        NSDate *prevDate = ((Entry *)results.firstObject).created_at;
        NSNumber *prevNum = ((Entry *)results.firstObject).i64;
        for (Entry *e in [results subarrayWithRange:NSMakeRange(1, [results count] - 1)]) {
            XCTAssertTrue([prevDate compare:e.created_at] != NSOrderedAscending,
                          @"dates are out of order");
            if ([prevDate compare:e.created_at] == NSOrderedSame) {
                XCTAssertTrue([prevNum compare:e.i64] != NSOrderedDescending,
                              @"Numbers are out of order");
            }
            prevDate = e.created_at;
            prevNum = e.i64;
        }
    }
    
    NSLog(@"Success");
}

@end

