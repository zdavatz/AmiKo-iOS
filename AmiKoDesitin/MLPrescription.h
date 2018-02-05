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

@interface MLPrescription : NSObject

@property (atomic) NSString *placeDate;
@property (atomic) MLOperator *doctor;
@property (atomic) MLPatient *patient;
@property (atomic) NSMutableArray *medications;

- (void) importFromURL:(NSURL *)url;

@end
