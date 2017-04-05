//
//  NSManagedObject+Sugar.h

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface NSManagedObject (Sugar)

// create objects
+ (instancetype)managedObject;
+ (NSArray *)managedObjectArrayWithLength:(NSUInteger)length;

// fetch existing objects
+ (NSArray *)allObjects;
+ (NSArray *)objectsMatching:(NSString *)predicateFormat, ...;
+ (NSArray *)objectsMatching:(NSString *)predicateFormat arguments:(va_list)args;
+ (NSArray *)objectsSortedBy:(NSString *)key ascending:(BOOL)ascending;
+ (NSArray *)objectsSortedBy:(NSString *)key ascending:(BOOL)ascending offset:(NSUInteger)offset limit:(NSUInteger)lim;
+ (NSArray *)fetchObjects:(NSFetchRequest *)request;

// count existing objects
+ (NSUInteger)countAllObjects;
+ (NSUInteger)countObjectsMatching:(NSString *)predicateFormat, ...;
+ (NSUInteger)countObjectsMatching:(NSString *)predicateFormat arguments:(va_list)args;
+ (NSUInteger)countObjects:(NSFetchRequest *)request;

// delete objects
+ (NSUInteger)deleteObjects:(NSArray *)objects;

// call this before any NSManagedObject+Sugar methods to use a concurrency type other than NSMainQueueConcurrencyType
+ (void)setConcurrencyType:(NSManagedObjectContextConcurrencyType)type;

// set the fetchBatchSize to use when fetching objects, default is 100
+ (void)setFetchBatchSize:(NSUInteger)fetchBatchSize;

// returns the managed object context for the application, or if the context doesn't already exist, creates it and binds
// it to the persistent store coordinator for the application
+ (NSManagedObjectContext *)context;

// sets a different context for NSManagedObject+Sugar methods to use for this type of entity
+ (void)setContext:(NSManagedObjectContext *)context;

+ (void)saveContext; // persists changes (this is called automatically for the main context when the app terminates)

+ (NSString *)entityName; // override this if entity name differs from class name
+ (NSFetchRequest *)fetchReq;
+ (NSFetchedResultsController *)fetchedResultsController:(NSFetchRequest *)request;

- (id)objectForKeyedSubscript:(id<NSCopying>)key; // id value = entity[@"key"]; thread safe valueForKey:
- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key; // entity[@"key"] = value; thread safe setValue:forKey:
- (void)deleteObject;

@end
