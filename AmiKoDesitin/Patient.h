//
//  Patient.h
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
#define KEY_AMK_PAT_HEALTH_CARD_NUMBER @"health_card_number"
#define KEY_AMK_PAT_INSURANCE_GLN @"insurance_gln"
#define KEY_AMK_PAT_INSURANCE_AHV_NUMBER @"ahv_number"

@interface Patient : NSObject

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
@property (atomic, copy) NSString *healthCardNumber;
@property (atomic, copy) NSString *insuranceGLN;
@property (atomic, copy) NSString *ahvNumber;

// Only available when patient is read from database
@property (nonatomic, strong, nullable) NSDate *timestamp;

- (void)importFromDict:(NSDictionary *)dict;
- (NSDictionary <NSString *, NSString *> *)dictionaryRepresentation;
- (NSInteger)entriesCount;
- (NSString *) generateUniqueID;

- (NSString *)getStringForPrescriptionPrinting;
- (NSString *)getStringForLabelPrinting;

@end
