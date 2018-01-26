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

+ (id)importFromDict:(NSDictionary *)dict
{
    MLPatient *patient = [[MLPatient alloc] init];

    patient.uniqueId = [dict objectForKey:@"patient_id"];
    patient.familyName = [dict objectForKey:@"family_name"];
    patient.givenName = [dict objectForKey:@"given_name"];
    patient.birthDate = [dict objectForKey:@"birth_date"];
    patient.weightKg = [[dict objectForKey:@"weight_kg"] intValue];
    patient.heightCm = [[dict objectForKey:@"height_cm"] intValue];
    patient.gender = [dict objectForKey:@"gender"];
    patient.postalAddress = [dict objectForKey:@"postal_address"];
    patient.zipCode = [dict objectForKey:@"zip_code"];
    patient.city = [dict objectForKey:@"city"];
    patient.country = [dict objectForKey:@"country"];
    patient.phoneNumber = [dict objectForKey:@"phone_number"];
    patient.emailAddress = [dict objectForKey:@"email_address"];
    
    return patient;
}

@end
