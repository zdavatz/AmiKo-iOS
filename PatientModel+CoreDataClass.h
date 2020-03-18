//
//  PatientModel+CoreDataClass.h
//  AmikoDesitin
//
//  Created by b123400 on 2020/03/19.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Patient.h"

NS_ASSUME_NONNULL_BEGIN

@interface PatientModel : NSManagedObject

- (void)importFromPatient:(Patient *)p timestamp:(NSDate *)timestamp;
- (Patient *)toPatient;

@end

NS_ASSUME_NONNULL_END

#import "PatientModel+CoreDataProperties.h"
