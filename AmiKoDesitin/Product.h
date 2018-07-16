//
//  Product.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 29 Jan 2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLMedication.h"

#define KEY_AMK_MED_EAN             @"eancode"
#define KEY_AMK_MED_PACKAGE         @"package"
#define KEY_AMK_MED_PROD_NAME       @"product_name"
#define KEY_AMK_MED_COMMENT         @"comment"

#define KEY_AMK_MED_TITLE           @"title"
#define KEY_AMK_MED_OWNER           @"owner"
#define KEY_AMK_MED_REGNRS          @"regnrs"
#define KEY_AMK_MED_ATC             @"atccode"

#define INDEX_EAN_CODE_IN_PACK   9

@interface Product : NSObject

@property (atomic, copy) NSString *eanCode;                 // eancode
@property (atomic, copy) NSString *packageInfo;             // package
@property (atomic, copy) NSString *prodName; //*title;      // product_name
@property (atomic, copy) NSString *comment;                 // comment

// AmiKo OSX uses MLMedication for the following
@property (atomic, copy) NSString *title;                   // title
@property (atomic, copy) NSString *auth;                    // owner
@property (atomic, copy) NSString *regnrs;                  // regnrs
@property (atomic, copy) NSString *atccode;                 // atccode

- (id) initWithMedication:(MLMedication *)m  :(NSInteger)packageIndex;
- (id) initWithDict:(NSDictionary *)dict;

@end
