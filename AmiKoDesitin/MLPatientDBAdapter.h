//
//  MLPatientDBAdapter.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 5 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLPatient.h"

@interface MLPatientDBAdapter : NSObject

- (BOOL) openDatabase:(NSString *)dbName;
- (void) closeDatabase;
- (NSString *) addEntry:(MLPatient *)patient;
- (NSString *) insertEntry:(MLPatient *)patient;
- (BOOL) deleteEntry:(MLPatient *)patient;

- (NSArray *) getAllPatients;
- (MLPatient *) getPatientWithUniqueID:(NSString *)uniqueID;
- (MLPatient *) cursorToPatient:(NSArray *)cursor;

@end
