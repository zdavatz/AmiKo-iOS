//
//  FullTextEntry.h
//  AmiKoDesitin
//
//  Created by Alex Bettarini on 17 Jul 2019.
//  Copyright © 2019 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FullTextEntry : NSObject

@property (nonatomic, copy) NSString *hash;
@property (nonatomic, copy) NSString *keyword;
@property (nonatomic, copy) NSString *regnrs;

- (void) setRegChaptersDict:(NSMutableDictionary *)dict;
- (NSDictionary *) getRegChaptersDict;

- (NSArray *) getRegnrsAsArray;
- (unsigned long) numHits;

@end

NS_ASSUME_NONNULL_END
