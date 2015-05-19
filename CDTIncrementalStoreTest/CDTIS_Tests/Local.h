//
//  Local.h
//  CDTIncrementalStoreTest
//
//  Created by Jimi Xenidis on 5/19/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <XCTest/XCTest.h>

#import <CDTIncrementalStore.h>

@interface LocalTestCase : XCTestCase

@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSURL *storeURL;


- (void)setUpForSQL:(BOOL)sql;

@end

/// Core data object definitions
@class File, SubEntry;

@interface Entry : NSManagedObject

@property (nonatomic, retain) NSNumber * check;
@property (nonatomic, retain) NSDate * created_at;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * text2;
@property (nonatomic, retain) NSNumber * i16;
@property (nonatomic, retain) NSNumber * i32;
@property (nonatomic, retain) NSNumber * i64;
@property (nonatomic, retain) NSDecimalNumber * fpDecimal;
@property (nonatomic, retain) NSNumber * fpDouble;
@property (nonatomic, retain) NSNumber * fpFloat;
@property (nonatomic, retain) NSData * binary;
@property (nonatomic, retain) id xform;
@property (nonatomic, retain) NSSet *subEntries;
@property (nonatomic, retain) NSSet *files;
@end

@interface Entry (CoreDataGeneratedAccessors)

- (void)addSubEntriesObject:(SubEntry *)value;
- (void)removeSubEntriesObject:(SubEntry *)value;
- (void)addSubEntries:(NSSet *)values;
- (void)removeSubEntries:(NSSet *)values;

- (void)addFilesObject:(File *)value;
- (void)removeFilesObject:(File *)value;
- (void)addFiles:(NSSet *)values;
- (void)removeFiles:(NSSet *)values;

@end

Entry *MakeEntry(NSManagedObjectContext *moc);

@interface File : NSManagedObject

@property (nonatomic, retain) NSString * fileName;
@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSManagedObject *entry;

@end

@interface SubEntry : NSManagedObject

@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSNumber * number;
@property (nonatomic, retain) NSManagedObject *entry;

@end
