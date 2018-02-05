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

static NSString *DATABASE_TABLE = @"patients";

/** Table columns for fast queries
 */
static NSString *ALL_COLUMNS = nil;
static NSString *DATABASE_COLUMNS = nil;

@implementation MLPatientDBAdapter
{
    MLSQLiteDatabase *myPatientDb;
}

- (BOOL) openDatabase:(NSString *)dbName
{
    if (myPatientDb == nil) {
        // Patient DB should be in the user's documents folder
        NSFileManager *fileManager = [NSFileManager defaultManager];
        // Get documents directory
        NSString *documentsDir = [MLUtility documentsDirectory];
        NSString *filePath = [[documentsDir stringByAppendingPathComponent:dbName] stringByAppendingPathExtension:@"db"];
        // Check if database exists
        if (filePath!=nil) {
            // Load database if it exists already
            if ([fileManager fileExistsAtPath:filePath]) {
                NSLog(@"Patient DB found in user's documents folder %@", filePath);
                myPatientDb = [[MLSQLiteDatabase alloc] initWithPath:filePath];
                return TRUE;
            } else {
                NSLog(@"Patient DB NOT found in user's documents folder %@", filePath);
                if ([[MLSQLiteDatabase alloc] createWithPath:filePath andTable:DATABASE_TABLE andColumns:DATABASE_COLUMNS]) {
                    myPatientDb = [[MLSQLiteDatabase alloc] initWithPath:filePath];
                    return TRUE;
                }
            }
        }
    }
    return FALSE;
}

- (void) closeDatabase
{
    // The database is open as long as the app is open
    if (myPatientDb)
        [myPatientDb close];
}

@end
