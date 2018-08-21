//
//  Patient.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 26 Jan 2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "Patient.h"

@implementation Patient

@synthesize uniqueId;
@synthesize familyName;
@synthesize givenName;
@synthesize birthDate;
@synthesize gender;
@synthesize weightKg;
@synthesize heightCm;
@synthesize zipCode;
@synthesize city;
@synthesize country;
@synthesize postalAddress;
@synthesize phoneNumber;
@synthesize emailAddress;

- (void)importFromDict:(NSDictionary *)dict
{
    uniqueId =      [dict objectForKey: KEY_AMK_PAT_ID];
    familyName =    [dict objectForKey: KEY_AMK_PAT_SURNAME];
    givenName =     [dict objectForKey: KEY_AMK_PAT_NAME];
    birthDate =     [dict objectForKey: KEY_AMK_PAT_BIRTHDATE];
    weightKg =      [[dict objectForKey:KEY_AMK_PAT_WEIGHT] intValue];
    heightCm =      [[dict objectForKey:KEY_AMK_PAT_HEIGHT] intValue];
    gender =        [dict objectForKey: KEY_AMK_PAT_GENDER];
    postalAddress = [dict objectForKey: KEY_AMK_PAT_ADDRESS];
    zipCode =       [dict objectForKey: KEY_AMK_PAT_ZIP];
    city =          [dict objectForKey: KEY_AMK_PAT_CITY];
    country =       [dict objectForKey: KEY_AMK_PAT_COUNTRY];
    phoneNumber =   [dict objectForKey: KEY_AMK_PAT_PHONE];
    emailAddress =  [dict objectForKey: KEY_AMK_PAT_EMAIL];
}

// Return number of lines of patient information to be displayed in the prescription
- (NSInteger)entriesCount
{
    return 6; // TODO
}

- (NSString *) generateUniqueID
{
    // The UUID should be unique and should be based on familyname, givenname, and birthday
    NSUInteger uniqueHash = [[NSString stringWithFormat:@"%@.%@.%@", familyName, givenName, birthDate] hash];
    return [NSString stringWithFormat:@"%lu", uniqueHash];    // e.g. 3466684318797166812
}

- (NSString *)getStringForPrescriptionPrinting
{
    NSString *s = @"";
    
    s = [s stringByAppendingString:[NSString stringWithFormat:@"%@ %@\n", givenName, familyName]];
    s = [s stringByAppendingString:[NSString stringWithFormat:@"%@\n", postalAddress]];
    s = [s stringByAppendingString:[NSString stringWithFormat:@"%@ %@\n", zipCode, city]];
    
    return s;
}

- (NSString *)getStringForLabelPrinting
{
    return [NSString stringWithFormat:@"%@ %@, %@ %@",
                              givenName,
                              familyName,
                              NSLocalizedString(@"born", nil),
                              birthDate];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ givenName:%@, familyName:%@, birthDate:%@, uniqueId:%@",
            NSStringFromClass([self class]), givenName, familyName, birthDate, uniqueId];
}

@end
