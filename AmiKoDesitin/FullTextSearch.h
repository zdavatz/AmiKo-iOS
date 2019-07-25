//
//  FullTextSearch.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 17/07/2019.
//  Copyright © 2019 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FullTextSearch : NSObject

@property (atomic) NSArray *listOfSectionIds;
@property (atomic) NSArray *listOfSectionTitles;

- (NSString *) tableWithArticles:(nullable NSArray *)listOfArticles
              andRegChaptersDict:(nullable NSDictionary *)dict
                       andFilter:(NSString *)filter;

@end

NS_ASSUME_NONNULL_END
