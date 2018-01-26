//
//  MLOperator.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 26 Jan 2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLOperator.h"

@implementation MLOperator

@synthesize title;
@synthesize familyName;
@synthesize givenName;
@synthesize postalAddress;
@synthesize zipCode;
@synthesize city;
@synthesize country;
@synthesize phoneNumber;
@synthesize emailAddress;

+ (id)importFromDict:(NSDictionary *)dict
{
    MLOperator *doctor = [[MLOperator alloc] init];
    
    doctor.title = [dict objectForKey:@"title"];
    doctor.familyName = [dict objectForKey:@"family_mame"];
    doctor.givenName = [dict objectForKey:@"given_name"];
    doctor.postalAddress = [dict objectForKey:@"postal_address"];
    doctor.zipCode = [dict objectForKey:@"zip_code"];
    doctor.city = [dict objectForKey:@"city"];
    doctor.country = @"";
    doctor.phoneNumber = [dict objectForKey:@"phone_number"];
    doctor.emailAddress = [dict objectForKey:@"email_address"];
    
    return doctor;
}

@end
