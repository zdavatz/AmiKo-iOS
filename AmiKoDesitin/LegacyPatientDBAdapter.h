//
//  PatientDBAdapter.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 5 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Patient.h"

/**
 * This class exists for backward compatibility (migration).
 * The real patient database is now depended on CoreData.
 */

@interface LegacyPatientDBAdapter : NSObject

- (BOOL) openDatabase;
- (void) closeDatabase;

- (NSString*)dbPath;
- (NSArray *) getAllPatients;
- (Patient *) cursorToPatient:(NSArray *)cursor;

@end
