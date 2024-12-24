//
//  PatientModel+CoreDataClass.m
//  AmikoDesitin
//
//  Created by b123400 on 2020/03/19.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//
//

#import "PatientModel+CoreDataClass.h"

@implementation PatientModel

- (void)importFromPatient:(Patient *)p timestamp:(NSDate *)timestamp {
    self.uniqueId = p.uniqueId;
    self.timestamp = timestamp;
    self.familyName = p.familyName;
    self.givenName = p.givenName;
    self.birthDate = p.birthDate;
    self.gender = p.gender;
    self.weightKg = p.weightKg;
    self.heightCm = p.heightCm;
    self.zipCode = p.zipCode;
    self.city = p.city;
    self.country = p.country;
    self.postalAddress = p.postalAddress;
    self.phoneNumber = p.phoneNumber;
    self.emailAddress = p.emailAddress;
    self.healthCardNumber = p.healthCardNumber;
}

- (Patient *)toPatient {
    Patient *p = [[Patient alloc] init];
    p.uniqueId = self.uniqueId;
    p.familyName = self.familyName;
    p.givenName = self.givenName;
    p.birthDate = self.birthDate;
    p.gender = self.gender;
    p.weightKg = self.weightKg;
    p.heightCm = self.heightCm;
    p.zipCode = self.zipCode;
    p.city = self.city;
    p.country = self.country;
    p.postalAddress = self.postalAddress;
    p.phoneNumber = self.phoneNumber;
    p.emailAddress = self.emailAddress;
    p.timestamp = self.timestamp;
    p.healthCardNumber = self.healthCardNumber;
    return p;
}

@end
