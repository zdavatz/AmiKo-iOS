//
//  PatientDBAdapter.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 5 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "LegacyPatientDBAdapter.h"
#import "MLSQLiteDatabase.h"
#import "MLUtility.h"

static NSString *KEY_ROWID = @"_id";
static NSString *KEY_TIMESTAMP = @"time_stamp";
static NSString *KEY_UID = @"uid";
static NSString *KEY_FAMILYNAME = @"family_name";
static NSString *KEY_GIVENNAME = @"given_name";
static NSString *KEY_BIRTHDATE = @"birthdate";
static NSString *KEY_GENDER = @"gender";
static NSString *KEY_WEIGHT_KG = @"weight_kg";
static NSString *KEY_HEIGHT_CM = @"height_cm";
static NSString *KEY_ZIPCODE = @"zip";
static NSString *KEY_CITY = @"city";
static NSString *KEY_COUNTRY = @"country";
static NSString *KEY_ADDRESS = @"address";
static NSString *KEY_PHONE = @"phone";
static NSString *KEY_EMAIL = @"email";

static NSString *DB_TABLE_NAME = @"patients";

/** Table columns for fast queries
 */
static NSString *QUERY_COLUMNS = nil;

@implementation LegacyPatientDBAdapter
{
    MLSQLiteDatabase *myPatientDb;
}

#pragma mark - Class functions

+ (void) initialize
{
    if (self == [LegacyPatientDBAdapter class])
    {
        if (QUERY_COLUMNS == nil) {
            QUERY_COLUMNS = [NSString stringWithFormat: @"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@",
                KEY_TIMESTAMP, KEY_UID, KEY_FAMILYNAME, KEY_GIVENNAME, KEY_BIRTHDATE, KEY_GENDER, KEY_WEIGHT_KG, KEY_HEIGHT_CM, KEY_ZIPCODE, KEY_CITY, KEY_COUNTRY, KEY_ADDRESS, KEY_PHONE, KEY_EMAIL];
        }
    }
}

#pragma mark - Instance functions

- (NSString*)dbPath {
    NSString *dbName = @"patient_db";
    NSString *documentsDir = [MLUtility documentsDirectory];
    return [[documentsDir stringByAppendingPathComponent:dbName] stringByAppendingPathExtension:@"db"];
}

// Patients DB
- (BOOL) openDatabase
{
    if (myPatientDb) {
#ifdef DEBUG
        NSLog(@"%s patient DB already opened", __FUNCTION__);
#endif
        return FALSE;
    }

    // Patient DB should be in the user's documents folder
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [self dbPath];

    // Load database if it exists already
    if ([fileManager fileExistsAtPath:filePath]) {
        NSLog(@"Patient DB found in user's documents folder %@", filePath);
        myPatientDb = [[MLSQLiteDatabase alloc] initWithPath:filePath];
        return TRUE;
    }

    return FALSE;
}

- (void) closeDatabase
{
    // The database is open as long as the app is open
    if (myPatientDb)
        [myPatientDb close];
}

- (NSArray *) getAllPatients
{
    NSMutableArray *listOfPatients = [NSMutableArray array];
    
    NSString *query = [NSString stringWithFormat:@"select %@ from %@", QUERY_COLUMNS, DB_TABLE_NAME];
    NSArray *results = [myPatientDb performQuery:query];
    if ([results count]>0) {
        for (NSArray *cursor in results) {
            [listOfPatients addObject:[self cursorToPatient:cursor]];
        }

        // Sort alphabetically
        NSSortDescriptor *nameSort = [NSSortDescriptor sortDescriptorWithKey:@"familyName" ascending:YES];
        [listOfPatients sortUsingDescriptors:[NSArray arrayWithObject:nameSort]];
    }
    
    return listOfPatients;
}

- (Patient *) cursorToPatient:(NSArray *)cursor
{
    Patient *patient = [Patient new];

    NSUInteger idx = 1;
    patient.uniqueId =      (NSString *)[cursor objectAtIndex:idx++];
    patient.familyName =    (NSString *)[cursor objectAtIndex:idx++];
    patient.givenName =     (NSString *)[cursor objectAtIndex:idx++];
    patient.birthDate =     (NSString *)[cursor objectAtIndex:idx++];
    patient.gender =        (NSString *)[cursor objectAtIndex:idx++];
    patient.weightKg =                 [[cursor objectAtIndex:idx++] intValue];
    patient.heightCm =                 [[cursor objectAtIndex:idx++] intValue];
    patient.zipCode =       (NSString *)[cursor objectAtIndex:idx++];
    patient.city =          (NSString *)[cursor objectAtIndex:idx++];
    patient.country =       (NSString *)[cursor objectAtIndex:idx++];
    patient.postalAddress = (NSString *)[cursor objectAtIndex:idx++];
    patient.phoneNumber =   (NSString *)[cursor objectAtIndex:idx++];
    patient.emailAddress =  (NSString *)[cursor objectAtIndex:idx++];
    
    return patient;
}

@end
