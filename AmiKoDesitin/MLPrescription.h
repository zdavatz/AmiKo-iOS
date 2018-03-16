//
//  MLPrescription.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 5 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLPatient.h"
#import "MLOperator.h"
#import "MLProduct.h"

#define KEY_AMK_HASH                @"prescription_hash"
#define KEY_AMK_PLACE_DATE          @"place_date"
#define KEY_AMK_PATIENT             @"patient"
#define KEY_AMK_OPERATOR            @"operator"
#define KEY_AMK_MEDICATIONS         @"medications"

@interface MLPrescription : NSObject

@property (atomic) NSString *hash;
@property (atomic) NSString *placeDate;
@property (atomic) MLOperator *doctor;
@property (atomic) MLPatient *patient;
@property (atomic) NSMutableArray *medications;

- (NSDictionary *) makePatientDictionary;
- (NSDictionary *) makeOperatorDictionary;
- (NSArray *) makeMedicationsArray;
- (void) importFromURL:(NSURL *)url;

@end
