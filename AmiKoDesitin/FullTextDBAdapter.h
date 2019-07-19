//
//  FullTextDBAdapter.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 17/07/2019.
//  Copyright © 2019 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FullTextEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface FullTextDBAdapter : NSObject

- (BOOL) openDatabase: (NSString *)dbName;
- (void) closeDatabase;
- (NSInteger) getNumRecords;
- (FullTextEntry *) searchHash:(NSString *)hash;
- (NSArray *) searchKeyword: (NSString *)keyword;
- (NSArray *) extractFullTextEntryFrom:(NSArray *)results;

@end

NS_ASSUME_NONNULL_END
