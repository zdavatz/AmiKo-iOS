//
//  MLPatientDBAdapter.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 5 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLPatientDBAdapter.h"
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
static NSString *DB_SCHEMA = nil;

@implementation MLPatientDBAdapter
{
    MLSQLiteDatabase *myPatientDb;
}

#pragma mark - Class functions

+ (void) initialize
{
    if (self == [MLPatientDBAdapter class])
    {
        if (QUERY_COLUMNS == nil) {
            QUERY_COLUMNS = [NSString stringWithFormat: @"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@",
                KEY_TIMESTAMP, KEY_UID, KEY_FAMILYNAME, KEY_GIVENNAME, KEY_BIRTHDATE, KEY_GENDER, KEY_WEIGHT_KG, KEY_HEIGHT_CM, KEY_ZIPCODE, KEY_CITY, KEY_COUNTRY, KEY_ADDRESS, KEY_PHONE, KEY_EMAIL];
        }
        
        // Schema
        if (DB_SCHEMA == nil) {
            DB_SCHEMA = [NSString stringWithFormat: @"(%@ INTEGER PRIMARY KEY, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT, %@ INTEGER, %@ INTEGER, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT)", KEY_ROWID, KEY_TIMESTAMP, KEY_UID, KEY_FAMILYNAME, KEY_GIVENNAME, KEY_BIRTHDATE, KEY_GENDER, KEY_WEIGHT_KG, KEY_HEIGHT_CM, KEY_ZIPCODE, KEY_CITY, KEY_COUNTRY, KEY_ADDRESS, KEY_PHONE, KEY_EMAIL];
        }
    }
}

#pragma mark - Instance functions

// Patients DB
- (BOOL) openDatabase:(NSString *)dbName
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    
    if (myPatientDb) {
#ifdef DEBUG
        NSLog(@"%s patient DB already opened", __FUNCTION__);
#endif
        return FALSE;
    }

    // Patient DB should be in the user's documents folder
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *documentsDir = [MLUtility documentsDirectory];
    NSString *filePath = [[documentsDir stringByAppendingPathComponent:dbName] stringByAppendingPathExtension:@"db"];

#ifdef DEBUG
    //NSLog(@"DB filePath:%@", filePath);
#endif

    if (!filePath)
        return FALSE;

    // Load database if it exists already
    if ([fileManager fileExistsAtPath:filePath]) {
        NSLog(@"Patient DB found in user's documents folder %@", filePath);
        myPatientDb = [[MLSQLiteDatabase alloc] initWithPath:filePath];
        return TRUE;
    }
    
    NSLog(@"Patient DB NOT found in user's documents folder %@", filePath);
    if ([[MLSQLiteDatabase alloc] createWithPath:filePath
                                        andTable:DB_TABLE_NAME
                                      andColumns:DB_SCHEMA])
    {
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

- (NSString *) addEntry:(MLPatient *)patient
{
    if (!myPatientDb)
        return nil;

    // Patient entry does not exist (yet)
    NSString *uuidStr = [patient generateUniqueID];    // e.g. 3466684318797166812
    NSString *timeStr = [MLUtility currentTime];
    NSString *columnStr = [NSString stringWithFormat:@"(%@)", QUERY_COLUMNS];
    NSString *valueStr = [NSString stringWithFormat:@"(\"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", %d, %d, \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\")",
                          timeStr,
                          uuidStr,
                          patient.familyName,
                          patient.givenName,
                          patient.birthDate,
                          patient.gender,
                          patient.weightKg,
                          patient.heightCm,
                          patient.zipCode,
                          patient.city,
                          patient.country,
                          patient.postalAddress,
                          patient.phoneNumber,
                          patient.emailAddress];

    // Insert new entry into DB
    [myPatientDb insertRowIntoTable:@"patients" forColumns:columnStr andValues:valueStr];
    return uuidStr;
}

- (NSString *) insertEntry:(MLPatient *)patient
{
    if (!myPatientDb)
        return nil;

    // If UUID exist re-use it!
    if (patient.uniqueId!=nil &&
        [patient.uniqueId length]>0)
    {
        NSString *expressions = [NSString stringWithFormat:@"%@=%d, %@=%d, %@=\"%@\", %@=\"%@\", %@=\"%@\", %@=\"%@\", %@=\"%@\", %@=\"%@\", %@=\"%@\"",
                                 KEY_WEIGHT_KG, patient.weightKg,
                                 KEY_HEIGHT_CM, patient.heightCm,
                                 KEY_ZIPCODE, patient.zipCode,
                                 KEY_CITY, patient.city,
                                 KEY_COUNTRY, patient.country,
                                 KEY_ADDRESS, patient.postalAddress,
                                 KEY_PHONE, patient.phoneNumber,
                                 KEY_EMAIL, patient.emailAddress,
                                 KEY_GENDER, patient.gender];
        NSString *conditions = [NSString stringWithFormat:@"%@=\"%@\"", KEY_UID, patient.uniqueId];

#ifdef DEBUG
        NSLog(@"Update existing entry, uniqueId: %@", patient.uniqueId);
#endif
        [myPatientDb updateRowIntoTable:@"patients" forExpressions:expressions andConditions:conditions];
        return patient.uniqueId;
    }
    else {
#ifdef DEBUG
        NSLog(@"Add entry, uniqueId: %@", patient.uniqueId);
#endif
        return [self addEntry:patient];
    }

    return nil;
}

- (BOOL) deleteEntry:(MLPatient *)patient
{
    if (myPatientDb) {
        [myPatientDb deleteRowFromTable:@"patients" withUId:patient.uniqueId];
        return TRUE;
    }
    return FALSE;
}

- (NSInteger) getNumPatients
{
    NSInteger numRecords = [myPatientDb numberRecordsForTable:DB_TABLE_NAME];
    return numRecords;
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

- (MLPatient *) getPatientWithUniqueID:(NSString *)uniqueID
{
    if (!uniqueID)
        return nil;

    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%@'",
                       QUERY_COLUMNS, DB_TABLE_NAME, KEY_UID, uniqueID];
    NSArray *results = [myPatientDb performQuery:query];
    if ([results count]>0) {
        for (NSArray *cursor in results) {
            return [self cursorToPatient:cursor];  // TODO: check
        }
    }

#ifdef DEBUG
    //NSLog(@"%s patient %@ not in DB", __FUNCTION__, uniqueID);
#endif
    return nil;
}

- (MLPatient *) cursorToPatient:(NSArray *)cursor
{
    MLPatient *patient = [[MLPatient alloc] init];
    
#ifdef DEBUG
    NSString *timeStamp =   (NSString *)[cursor objectAtIndex:0];
    //NSLog(@"timeStamp %@", timeStamp);
#endif

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
    //patient.databaseType = eLocal;  // TODO    
    
    return patient;
}

@end
