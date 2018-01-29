//
//  MLProduct.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 29 Jan 2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MLProduct : NSObject

@property (atomic, copy) NSString *eanCode;                 // eancode
@property (atomic, copy) NSString *packageInfo;             // package
@property (atomic, copy) NSString *prodName; //*title;      // product_name
@property (atomic, copy) NSString *comment;                 // comment

+ (id)importFromDict:(NSDictionary *)dict;

@end
