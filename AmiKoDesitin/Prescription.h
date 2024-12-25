//
//  Prescription.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 5 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Patient.h"
#import "Operator.h"
#import "Product.h"
#import "ZurRosePrescription.h"

#define KEY_AMK_HASH                @"prescription_hash"
#define KEY_AMK_PLACE_DATE          @"place_date"
#define KEY_AMK_PATIENT             @"patient"
#define KEY_AMK_OPERATOR            @"operator"
#define KEY_AMK_MEDICATIONS         @"medications"

@interface Prescription : NSObject

@property (atomic) NSString *hash;
@property (atomic) NSString *placeDate;
@property (atomic) Operator *doctor;
@property (atomic) Patient *patient;
@property (atomic) NSMutableArray<Product *> *medications;

- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithAMKDictionary:(NSDictionary*)receiptData;
- (NSDictionary *) makePatientDictionary;
- (NSDictionary *) makeOperatorDictionary;
- (NSArray *) makeMedicationsArray;

- (NSData *)ePrescription;
- (ZurRosePrescription *)toZurRosePrescription;

@end
