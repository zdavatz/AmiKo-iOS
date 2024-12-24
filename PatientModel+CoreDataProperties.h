//
//  PatientModel+CoreDataProperties.h
//  AmikoDesitin
//
//  Created by b123400 on 2020/03/19.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//
//

#import "PatientModel+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface PatientModel (CoreDataProperties)

+ (NSFetchRequest<PatientModel *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *birthDate;
@property (nullable, nonatomic, copy) NSString *city;
@property (nullable, nonatomic, copy) NSString *country;
@property (nullable, nonatomic, copy) NSString *emailAddress;
@property (nullable, nonatomic, copy) NSString *familyName;
@property (nullable, nonatomic, copy) NSString *gender;
@property (nullable, nonatomic, copy) NSString *givenName;
@property (nonatomic) int64_t heightCm;
@property (nullable, nonatomic, copy) NSString *phoneNumber;
@property (nullable, nonatomic, copy) NSString *postalAddress;
@property (nullable, nonatomic, copy) NSDate *timestamp;
@property (nullable, nonatomic, copy) NSString *uniqueId;
@property (nonatomic) int64_t weightKg;
@property (nullable, nonatomic, copy) NSString *zipCode;
@property (nullable, nonatomic, copy) NSString *healthCardNumber;

@end

NS_ASSUME_NONNULL_END
