//
//  Local.m
//  CDTIncrementalStoreTest
//
//  Created by Jimi Xenidis on 5/19/15.
//
//

#import "Local.h"

static NSString *CDTISDBString = @"cdtis_test";

@interface LocalTestCase ()

@property (nonatomic) BOOL sql;

@end

@implementation LocalTestCase

- (void)setUpForSQL:(BOOL)sql {
    [super setUp];
    
    NSFileManager *fm = [NSFileManager defaultManager];

    NSURL *docDir = [[fm URLsForDirectory:NSDocumentDirectory
                                inDomains:NSUserDomainMask] lastObject];
    NSURL *storeURL = [docDir URLByAppendingPathComponent:CDTISDBString];
    if (sql) {
        storeURL = [self.storeURL URLByAppendingPathExtension:@"sqlite"];
    }

    self.storeURL = storeURL;

    // kill the old one
    NSError *err;
    if (![fm removeItemAtURL:self.storeURL error:&err]) {
        if (err.code != NSFileNoSuchFileError) {
            XCTAssertNil(err, @"%@", err);
        }
    }
    self.sql = sql;
}

- (void)tearDown {

    self.managedObjectContext = nil;
    self.persistentStoreCoordinator = nil;

    [super tearDown];
}

- (void)setUp {
    [self setUpForSQL:NO];
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *url = [bundle URLForResource:@"Local" withExtension:@"momd"];
    XCTAssertNotNil(url, @"could not find Local Core Data Model file");

    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
    XCTAssertTrue(([[_managedObjectModel entities] count] > 0), @"no entities");

    return _managedObjectModel;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }

    _managedObjectContext = [NSManagedObjectContext new];
    NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
    if (coordinator != nil) {
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    _persistentStoreCoordinator =
    [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    NSError *err = nil;
    NSString *storeType;

    if (self.sql) {
        storeType = NSSQLiteStoreType;
    } else {
        storeType = [CDTIncrementalStore type];
    }

    NSPersistentStore *theStore = [_persistentStoreCoordinator addPersistentStoreWithType:storeType
                                                                            configuration:nil
                                                                                      URL:self.storeURL
                                                                                  options:nil
                                                                                    error:&err];
    XCTAssertNotNil(theStore, @"could not get theStore: %@", err);

    return _persistentStoreCoordinator;
}

@end

@implementation Entry

@dynamic check;
@dynamic created_at;
@dynamic text, text2;
@dynamic i16, i32, i64;
@dynamic fpDecimal, fpDouble, fpFloat;
@dynamic binary, xform;
@dynamic subEntries, files;

@end

Entry *MakeEntry(NSManagedObjectContext *moc)
{
    return
    [NSEntityDescription insertNewObjectForEntityForName:@"Entry" inManagedObjectContext:moc];
}


@implementation File

@dynamic fileName, data, entry;

@end

@implementation SubEntry

@dynamic text, number, entry;

@end
