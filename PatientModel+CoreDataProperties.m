//
//  PatientModel+CoreDataProperties.m
//  AmikoDesitin
//
//  Created by b123400 on 2020/03/19.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//
//

#import "PatientModel+CoreDataProperties.h"

@implementation PatientModel (CoreDataProperties)

+ (NSFetchRequest<PatientModel *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Patient"];
}

@dynamic birthDate;
@dynamic city;
@dynamic country;
@dynamic emailAddress;
@dynamic familyName;
@dynamic gender;
@dynamic givenName;
@dynamic heightCm;
@dynamic phoneNumber;
@dynamic postalAddress;
@dynamic timestamp;
@dynamic uniqueId;
@dynamic weightKg;
@dynamic zipCode;
@dynamic healthCardNumber;
@dynamic insuranceGLN;

@end
