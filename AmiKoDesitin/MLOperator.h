//
//  MLOperator.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 26 Jan 2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DOCTOR_TN_H     45.0
#define DOCTOR_TN_W     90.0

#define KEY_AMK_DOC_TITLE       @"title"
#define KEY_AMK_DOC_NAME        @"given_name"
#define KEY_AMK_DOC_SURNAME     @"family_name"
#define KEY_AMK_DOC_ADDRESS     @"postal_address"
#define KEY_AMK_DOC_CITY        @"city"
#define KEY_AMK_DOC_ZIP         @"zip_code"
#define KEY_AMK_DOC_PHONE       @"phone_number"
#define KEY_AMK_DOC_EMAIL       @"email_address"

#define KEY_AMK_DOC_SIGNATURE   @"signature"
#define DOC_SIGNATURE_FILENAME  @"op_signature.png"

@interface MLOperator : NSObject

@property (atomic, copy) NSString *title;
@property (atomic, copy) NSString *givenName;
@property (atomic, copy) NSString *familyName;
@property (atomic, copy) NSString *postalAddress;
@property (atomic, copy) NSString *city;
@property (atomic, copy) NSString *zipCode;
@property (atomic, copy) NSString *phoneNumber;
@property (atomic, copy) NSString *emailAddress;

@property (nonatomic, strong, readwrite) NSString *signature;

- (void)importFromDict:(NSDictionary *)dict;
- (void)importSignatureFromDict:(NSDictionary *)dict;
- (BOOL)importSignature;

- (UIImage *)thumbnailFromSignature:(CGSize) size;
- (NSInteger)entriesCount;

@end
