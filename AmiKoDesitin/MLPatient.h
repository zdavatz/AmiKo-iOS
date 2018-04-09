//
//  MLPatient.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 26 Jan 2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

#define KEY_AMK_PAT_ID          @"patient_id"
#define KEY_AMK_PAT_NAME        @"given_name"
#define KEY_AMK_PAT_SURNAME     @"family_name"
#define KEY_AMK_PAT_BIRTHDATE   @"birth_date"
#define KEY_AMK_PAT_WEIGHT      @"weight_kg"
#define KEY_AMK_PAT_HEIGHT      @"height_cm"
#define KEY_AMK_PAT_GENDER      @"gender"
#define KEY_AMK_PAT_GENDER_M    @"man"
#define KEY_AMK_PAT_GENDER_F    @"woman"
#define KEY_AMK_PAT_ADDRESS     @"postal_address"
#define KEY_AMK_PAT_ZIP         @"zip_code"
#define KEY_AMK_PAT_CITY        @"city"
#define KEY_AMK_PAT_COUNTRY     @"country"
#define KEY_AMK_PAT_PHONE       @"phone_number"
#define KEY_AMK_PAT_EMAIL       @"email_address"

@interface MLPatient : NSObject

@property (atomic, copy) NSString *uniqueId;
@property (atomic, copy) NSString *familyName;
@property (atomic, copy) NSString *givenName;
@property (atomic, copy) NSString *birthDate;
@property (atomic, copy) NSString *gender;
@property (atomic, assign) int weightKg;
@property (atomic, assign) int heightCm;
@property (atomic, copy) NSString *zipCode;
@property (atomic, copy) NSString *city;
@property (atomic, copy) NSString *country;
@property (atomic, copy) NSString *postalAddress;
@property (atomic, copy) NSString *phoneNumber;
@property (atomic, copy) NSString *emailAddress;

- (void)importFromDict:(NSDictionary *)dict;
- (NSInteger)entriesCount;
- (NSString *) generateUniqueID;

@end
