//
//  DKObject.h
//  DataKit
//
//  Created by Erik Aigner on 23.02.12.
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DKObject;
@class DKPointer;

typedef void (^DKObjectResultBlock)(DKObject *object, NSError *error);

@interface DKObject : NSObject
@property (nonatomic, copy, readonly) NSString *entityName;
@property (nonatomic, readonly) NSString *objectId;
@property (nonatomic, readonly) NSDate *updatedAt;
@property (nonatomic, readonly) NSDate *createdAt;
@property (nonatomic, readonly) BOOL isNew;

+ (DKObject *)objectWithEntityName:(NSString *)entityName;
+ (BOOL)saveAll:(NSArray *)objects UNIMPLEMENTED;
+ (BOOL)saveAll:(NSArray *)objects error:(NSError **)error UNIMPLEMENTED;
+ (BOOL)saveAllInBackground:(NSArray *)objects UNIMPLEMENTED;
+ (BOOL)saveAllInBackground:(NSArray *)objects withBlock:(DKObjectResultBlock)block UNIMPLEMENTED;
+ (id)new UNAVAILABLE_ATTRIBUTE;

- (id)init UNAVAILABLE_ATTRIBUTE;
- (id)initWithEntityName:(NSString *)entityName;

- (BOOL)save;
- (BOOL)save:(NSError **)error;
- (void)saveInBackground;
- (void)saveInBackgroundWithBlock:(DKObjectResultBlock)block;
- (BOOL)refresh;
- (BOOL)refresh:(NSError **)error;
- (void)refreshInBackground;
- (void)refreshInBackgroundWithBlock:(DKObjectResultBlock)block;
- (BOOL)delete;
- (BOOL)delete:(NSError **)error;
- (void)deleteInBackground;
- (void)deleteInBackgroundWithBlock:(DKObjectResultBlock)block;
- (id)objectForKey:(NSString *)key;
- (void)objectForKey:(NSString *)key inBackgroundWithBlock:(DKObjectResultBlock)block UNIMPLEMENTED;
- (DKPointer *)pointerForKey:(NSString *)key UNIMPLEMENTED;
- (void)setObject:(id)object forKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;
- (void)incrementKey:(NSString *)key UNIMPLEMENTED;
- (void)incrementKey:(NSString *)key byAmount:(NSNumber *)amount UNIMPLEMENTED;

@end