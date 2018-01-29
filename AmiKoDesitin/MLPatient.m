//
//  MLPatient.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 26 Jan 2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLPatient.h"

@implementation MLPatient

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
    uniqueId = [dict objectForKey:@"patient_id"];
    familyName = [dict objectForKey:@"family_name"];
    givenName = [dict objectForKey:@"given_name"];
    birthDate = [dict objectForKey:@"birth_date"];
    weightKg = [[dict objectForKey:@"weight_kg"] intValue];
    heightCm = [[dict objectForKey:@"height_cm"] intValue];
    gender = [dict objectForKey:@"gender"];
    postalAddress = [dict objectForKey:@"postal_address"];
    zipCode = [dict objectForKey:@"zip_code"];
    city = [dict objectForKey:@"city"];
    country = [dict objectForKey:@"country"];
    phoneNumber = [dict objectForKey:@"phone_number"];
    emailAddress = [dict objectForKey:@"email_address"];
}

- (NSInteger)entriesCount
{
    return 6; // TODO
}

@end
