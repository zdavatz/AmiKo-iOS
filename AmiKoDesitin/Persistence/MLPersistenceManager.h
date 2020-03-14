//
//  MLPersistenceManager.h
//  AmiKoDesitin
//
//  Created by b123400 on 2020/03/14.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MLPersistenceSource) {
    MLPersistenceSourceLocal = 0,
    MLPersistenceSourceICloud = 1,
};

@interface MLPersistenceManager : NSObject

@property (nonatomic) MLPersistenceSource currentSource;

+ (instancetype) shared;
+ (BOOL)supportICloud;

- (void)saveDoctorDictionary:(NSDictionary *)dict;
- (NSDictionary *)doctorDictionary;

@end

NS_ASSUME_NONNULL_END
