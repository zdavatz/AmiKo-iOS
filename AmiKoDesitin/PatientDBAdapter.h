//
//  PatientDBAdapter.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 5 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Patient.h"

@interface PatientDBAdapter : NSObject

- (BOOL) openDatabase:(NSString *)dbName;
- (void) closeDatabase;
- (NSString *) addEntry:(Patient *)patient;
- (NSString *) insertEntry:(Patient *)patient;
- (BOOL) deleteEntry:(Patient *)patient;
- (NSInteger) getNumPatients;

- (NSArray *) getAllPatients;
- (Patient *) getPatientWithUniqueID:(NSString *)uniqueID;
- (Patient *) cursorToPatient:(NSArray *)cursor;

@end
