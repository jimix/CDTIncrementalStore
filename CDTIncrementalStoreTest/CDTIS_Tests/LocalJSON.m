//
//  LocalJSON.m
//  CDTIncrementalStoreTest
//
//  Created by Jimi Xenidis on 5/19/15.
//
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>

#import "Local.h"

static const BOOL sql = NO;

@interface LocalJSON : LocalTestCase

@end


@implementation LocalJSON

- (void)setUp {
    [super setUpForSQL:sql];
}

- (void)testCheckNumbers
{
    NSError *err = nil;
    // This will create the database
    NSManagedObjectContext *moc = self.managedObjectContext;
    XCTAssertNotNil(moc, @"could not create Context");

    // Increment this for every entry you make
    NSUInteger entries = 0;

    Entry *maxNums = MakeEntry(moc);
    ++entries;
    maxNums.text = @"maximums";
    maxNums.check = @YES;
    maxNums.fpDecimal = [NSDecimalNumber maximumDecimalNumber];
    maxNums.fpDouble = @(DBL_MAX);
    maxNums.fpFloat = @(FLT_MAX);
    maxNums.i16 = @INT16_MAX;
    maxNums.i32 = @INT32_MAX;
    maxNums.i64 = @INT64_MAX;

    Entry *minNums = MakeEntry(moc);
    ++entries;
    minNums.text = @"minimums";
    minNums.check = @NO;
    minNums.fpDecimal = [NSDecimalNumber minimumDecimalNumber];
    minNums.fpDouble = @(DBL_MIN);
    minNums.fpFloat = @(FLT_MIN);
    minNums.i16 = @INT16_MIN;
    minNums.i32 = @INT32_MIN;
    minNums.i64 = @INT64_MIN;

    Entry *infNums = MakeEntry(moc);
    ++entries;
    infNums.text = @"INFINITY";
    infNums.fpDouble = @(INFINITY);
    infNums.fpFloat = @(INFINITY);
    infNums.fpDecimal = (NSDecimalNumber *)[NSDecimalNumber numberWithDouble:INFINITY];

    Entry *ninfNums = MakeEntry(moc);
    ++entries;
    ninfNums.text = @"-INFINITY";
    ninfNums.fpFloat = @(-INFINITY);
    ninfNums.fpDouble = @(-INFINITY);
    ninfNums.fpDecimal = (NSDecimalNumber *)[NSDecimalNumber numberWithDouble:-INFINITY];

    Entry *nanNums = MakeEntry(moc);
    ++entries;
    nanNums.text = @"NaN";
    nanNums.fpDouble = @(NAN);
    nanNums.fpFloat = @(NAN);
    nanNums.fpDecimal = [NSDecimalNumber notANumber];

    XCTAssertTrue([moc save:&err], @"Save Failed: %@", err);

    // does this really cause everything to fault?
    [moc refreshObject:maxNums mergeChanges:NO];
    [moc refreshObject:minNums mergeChanges:NO];
    [moc refreshObject:infNums mergeChanges:NO];
    [moc refreshObject:nanNums mergeChanges:NO];

    XCTAssertTrue([maxNums.fpDouble isEqualToNumber:@(DBL_MAX)], @"Failed to retain double max");
    XCTAssertTrue([minNums.fpDouble isEqualToNumber:@(DBL_MIN)], @"Failed to retain double min");
    XCTAssertTrue([infNums.fpDouble isEqualToNumber:@(INFINITY)],
                  @"Failed to retain double infinity");

    XCTAssertTrue([maxNums.fpFloat isEqualToNumber:@(FLT_MAX)], @"Failed to retain float max");
    XCTAssertTrue([minNums.fpFloat isEqualToNumber:@(FLT_MIN)], @"Failed to retain float min");
    XCTAssertTrue([infNums.fpFloat isEqualToNumber:@(INFINITY)],
                  @"Failed to retain float infinity");

    if (sql) {
        // SQLite has no representation for NaN, so CoreData (and the rest fo the world use NULL
        XCTAssertNil(nanNums.fpDouble, @"Failed to retain double NaN");
        XCTAssertNil(nanNums.fpFloat, @"Failed to retain float NaN");
        // NSDecimalNumbers are too big for SQLite, so don't bother testing
    } else {
        XCTAssertTrue([nanNums.fpDouble isEqualToNumber:@(NAN)], @"Failed to retain double NaN");
        XCTAssertTrue([nanNums.fpFloat isEqualToNumber:@(NAN)], @"Failed to retain float NaN");
        XCTAssertTrue([maxNums.fpDecimal isEqual:[NSDecimalNumber maximumDecimalNumber]],
                      @"Failed to retain decimal max");
        XCTAssertTrue([minNums.fpDecimal isEqual:[NSDecimalNumber minimumDecimalNumber]],
                      @"Failed to retain decimal min");
        XCTAssertTrue([infNums.fpDecimal
                       isEqual:(NSDecimalNumber *)[NSDecimalNumber numberWithDouble:INFINITY]],
                      @"Failed to retain decimal infinity");
    }

    XCTAssertTrue([nanNums.fpDecimal isEqual:[NSDecimalNumber notANumber]],
                  @"Failed to retain decimal NaN");

    NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"Entry"];
    NSUInteger count = [moc countForFetchRequest:fr error:&err];

    XCTAssertTrue(count == entries, @"Count fails");
}
@end
