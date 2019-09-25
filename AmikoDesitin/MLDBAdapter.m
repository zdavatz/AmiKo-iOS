/*
 
 Copyright (c) 2013 Max Lungarella <cybrmx@gmail.com>
 
 Created on 11/08/2013.
 
 This file is part of AmiKoDesitin.
 
 AmiKoDesitin is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 
 ------------------------------------------------------------------------ */

#import "MLDBAdapter.h"

#import "MLSQLiteDatabase.h"
#import "MLConstants.h"

// Used for 'objectAtIndex:'
typedef NS_ENUM(NSInteger, ObjectIdx) {
    kMedId = 0, kTitle, kAuth, kAtcCode, kSubstances, kRegnrs, kAtcClass, kTherapy, kApplication, kIndications, kCustomerId, kPackInfo, kPackages, kAddInfo, kIdsStr, kSectionsStr, kContentStr, kStyleStr
};

static NSString *KEY_ROWID = @"_id";
static NSString *KEY_TITLE = @"title";
static NSString *KEY_AUTH = @"auth";
static NSString *KEY_ATCCODE = @"atc";
static NSString *KEY_SUBSTANCES = @"substances";
static NSString *KEY_REGNRS = @"regnrs";
static NSString *KEY_ATCCLASS = @"atc_class";
static NSString *KEY_THERAPY = @"tindex_str";
static NSString *KEY_APPLICATION = @"application_str";
static NSString *KEY_INDICATIONS = @"indications_str";
static NSString *KEY_CUSTOMER_ID = @"customer_id";
static NSString *KEY_PACK_INFO = @"pack_info_str";
static NSString *KEY_ADDINFO = @"add_info_str";
static NSString *KEY_IDS = @"ids_str";
static NSString *KEY_SECTIONS = @"titles_str";
static NSString *KEY_CONTENT = @"content";
static NSString *KEY_STYLE = @"style_str";
static NSString *KEY_PACKAGES = @"packages";

static NSString *DATABASE_TABLE = @"amikodb";

/** Table columns used for fast queries
 */
static NSString *SHORT_TABLE = nil;
static NSString *FULL_TABLE = nil;

@implementation MLDBAdapter
{
    MLSQLiteDatabase *mySqliteDb;
    NSMutableDictionary *myDrugInteractionMap;
}

#pragma mark - Class functions

+ (void) initialize
{
    //NSLog(@"%s %@", __FUNCTION__, self);  // Called first
    if (self == [MLDBAdapter class]) {
        if (SHORT_TABLE == nil) {
            SHORT_TABLE = [[NSString alloc] initWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@",
                           KEY_ROWID, KEY_TITLE, KEY_AUTH, KEY_ATCCODE, KEY_SUBSTANCES, KEY_REGNRS, KEY_ATCCLASS, KEY_THERAPY, KEY_APPLICATION, KEY_INDICATIONS, KEY_CUSTOMER_ID, KEY_PACK_INFO, KEY_PACKAGES];
        }
        if (FULL_TABLE == nil) {
            FULL_TABLE = [[NSString alloc] initWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@",
                          KEY_ROWID, KEY_TITLE, KEY_AUTH, KEY_ATCCODE, KEY_SUBSTANCES, KEY_REGNRS, KEY_ATCCLASS, KEY_THERAPY, KEY_APPLICATION, KEY_INDICATIONS, KEY_CUSTOMER_ID, KEY_PACK_INFO, KEY_PACKAGES, KEY_ADDINFO, KEY_IDS, KEY_SECTIONS, KEY_CONTENT, KEY_STYLE];
        }
    }
}

+ (MLDBAdapter *)sharedInstance
{
    //NSLog(@"%s", __FUNCTION__);
    __strong static id sharedObject = nil;
    
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedObject = [self new];
    });
    return sharedObject;
}

+ (void) removeFileInDocDir:(NSString*)name extension:(NSString*)ext
{
    NSString *dbName = [NSString stringWithFormat:@"%@%@", name, [MLConstants databaseLanguage]];

    // Get documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths lastObject];
    NSString *filePath = [[documentsDir stringByAppendingPathComponent:dbName] stringByAppendingPathExtension:ext];
    
    //NSLog(@"%s %d, trying to delete %@", __FUNCTION__, __LINE__, filePath);

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath]) {
        //NSLog(@"%s %d, file doesn't exist", __FUNCTION__, __LINE__); // DB has never been updated so far.
        return;
    }

    // File exists

    if (![[NSFileManager defaultManager] isDeletableFileAtPath:filePath]) {
        NSLog(@"ERROR: file not deletable");
        return;
    }

    NSError *error;
    BOOL success = [fileManager removeItemAtPath:filePath error:&error];
    if (!success)
        NSLog(@"Error removing file at path: %@", error.localizedDescription);
}

#pragma mark - Instance functions

- (void) listDirectoriesAtPath:(NSString*)dir
{
    // List files in directory
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *fileList = [manager contentsOfDirectoryAtPath:dir error:nil];
    for (NSString *s in fileList){
        NSLog(@"%@",s);
    }
}

- (BOOL) openInteractionsCsvFile:(NSString *)name
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths lastObject];

    // [self listDirectoriesAtPath:documentsDir];
    
    // ** A. Check first users documents folder
    NSString *filePath = [[documentsDir stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"csv"];
    // Check if database exists
    if (filePath!=nil) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:filePath]) {
#ifdef DEBUG
            NSLog(@"Using Drug interactions csv in documents folder - %@", filePath);
#endif
            return [self readDrugInteractionMap:filePath];
        }
    }
    
    // ** B. If no database is available, check if db is in app bundle
    filePath = [[NSBundle mainBundle] pathForResource:name ofType:@"csv"];
    if (filePath!=nil ) {
#ifdef DEBUG
        NSLog(@"Using Drug interactions csv in app bundle - %@", filePath);
#endif
        // Read drug interactions csv line after line
        return [self readDrugInteractionMap:filePath];
    }
    
    return FALSE;
}

- (void) closeInteractionsCsvFile
{
    if ([myDrugInteractionMap count]>0) {
        [myDrugInteractionMap removeAllObjects];
    }
}

- (BOOL) readDrugInteractionMap:(NSString *)filePath
{
    // Read drug interactions csv line after line
    NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSArray *rows = [content componentsSeparatedByString:@"\n"];
    myDrugInteractionMap = [NSMutableDictionary new];
    /*
     token[0]: ATC-Code1
     token[1]: ATC-Code2
     token[2]: Html
     */
    for (NSString *s in rows) {
        if (![s isEqualToString:@""]) {
            NSArray *token = [s componentsSeparatedByString:@"||"];
            NSString *key = [NSString stringWithFormat:@"%@-%@", token[0], token[1]];
            [myDrugInteractionMap setObject:token[2] forKey:key];
        }
    }
    return TRUE;
}

- (NSInteger) getNumInteractions
{
    if (myDrugInteractionMap)
        return [myDrugInteractionMap count];
    
    return 0;
}

- (NSString *) getInteractionHtmlBetween:(NSString *)atc1 and:(NSString *)atc2
{
    if ([myDrugInteractionMap count]>0) {
        NSString *key = [NSString stringWithFormat:@"%@-%@", atc1, atc2];
        return [myDrugInteractionMap valueForKey:key];
    }
    return @"";
}

- (void) openDatabase
{
    NSLog(@"%s", __FUNCTION__);

    NSString *filePath = nil;

    if ([APP_NAME isEqualToString:@"iAmiKo"] ||
        [APP_NAME isEqualToString:@"AmiKoDesitin"]) {
        filePath = [[NSBundle mainBundle] pathForResource:@"amiko_db_full_idx_de" ofType:@"db"];
    }
    else if ([APP_NAME isEqualToString:@"iCoMed"] ||
             [APP_NAME isEqualToString:@"CoMedDesitin"]) {
        filePath = [[NSBundle mainBundle] pathForResource:@"amiko_db_full_idx_fr" ofType:@"db"];
    }
    else {
       filePath = [[NSBundle mainBundle] pathForResource:@"amiko_db_full_idx_de" ofType:@"db"];
    }

    mySqliteDb = [[MLSQLiteDatabase alloc] initWithPath:filePath];
}

// Drugs database
- (BOOL) openDatabase: (NSString *)dbName
{
    // Check first users documents folder
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Get documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths lastObject];
    NSString *filePath = [[documentsDir stringByAppendingPathComponent:dbName] stringByAppendingPathExtension:@"db"];
    
    // Check if database exists
    if (filePath) {
        if ([fileManager fileExistsAtPath:filePath]) {
            mySqliteDb = [[MLSQLiteDatabase alloc] initWithPath:filePath];
#ifdef DEBUG
            NSLog(@"Using DB in documents folder - %@", filePath);
#endif
            return TRUE;
        }
    }
    
    // B. If no database is available, check if db is in app bundle
    filePath = [[NSBundle mainBundle] pathForResource:dbName ofType:@"db"];
    if (filePath) {
        mySqliteDb = [[MLSQLiteDatabase alloc] initWithPath:filePath];
#ifdef DEBUG
        NSLog(@"Using DB in app bundle - %@", filePath);
#endif
        return TRUE;
    }
    
    return FALSE;
}

- (void) closeDatabase
{
    if (mySqliteDb)
        [mySqliteDb close];
}

- (NSInteger) getNumRecords
{
    NSInteger numRecords = [mySqliteDb numberRecordsForTable:DATABASE_TABLE];
    
    return numRecords;
}

- (NSInteger) getNumProducts
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@", KEY_PACK_INFO, DATABASE_TABLE];
    NSArray *results = [mySqliteDb performQuery:query];
    NSInteger numProducts = 0;
    for (NSArray *cursor in results)  {
        numProducts += [[[cursor firstObject] componentsSeparatedByString:@"\n"] count];
    }
    
    return numProducts;
}

- (NSArray *) getRecord: (long)rowId
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@=%ld",
                       FULL_TABLE, DATABASE_TABLE, KEY_ROWID, rowId];
    //NSArray *results = [mySqliteDb performQuery:query];
    
    return [mySqliteDb performQuery:query];
}

- (MLMedication *) searchId: (long)rowId
{
#ifdef DEBUG
    NSLog(@"%s %d, rowId %ld", __FUNCTION__, __LINE__, rowId);
#endif
    // getRecord returns an NSArray* hence the objectAtIndex  
    return [self cursorToFullMedInfo:[[self getRecord:rowId] objectAtIndex:0]];
}

- (MLMedication *) getMediWithRegnr:(NSString *)regnr
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%%, %@%%' or %@ like '%@%%'", FULL_TABLE, DATABASE_TABLE, KEY_REGNRS, regnr, KEY_REGNRS, regnr];
    NSArray *cursor = [[mySqliteDb performQuery:query] firstObject];
    
    return [self cursorToFullMedInfo:cursor];
}

- (NSArray *) searchWithQuery: (NSString *)query;
{
    return [mySqliteDb performQuery:query];
}

- (NSArray *) searchEan: (NSString *)ean
{
    NSString *resultColumns = @"title, auth, atc, regnrs, pack_info_str, packages";
    NSString *searchColumn = @"packages";
    NSString *tableName = @"amikodb";
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%%%@%%'",
                       resultColumns, tableName, searchColumn, ean];
    //NSLog(@"%s query <%@>", __FUNCTION__, query);

    NSArray *results = [mySqliteDb performQuery:query];
    return results;
}

/** Search Präparat
 */
- (NSArray *) searchTitle: (NSString *)title
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%@%%'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_TITLE, title];
    NSArray *results = [mySqliteDb performQuery:query];
    
    return [self extractShortMedInfoFrom:results];
}

/** Search Inhaber
 */
- (NSArray *) searchAuthor: (NSString *)author
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%@%%'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_AUTH, author];
    NSArray *results = [mySqliteDb performQuery:query];
    
    return [self extractShortMedInfoFrom:results];
}

/** Search ATC Code
 */
- (NSArray *) searchATCCode: (NSString *)atccode
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%%;%@%%' or %@ like '%@%%' or %@ like '%% %@%%' or %@ like '%%%@%%' or %@ like '%%;%%%@%%'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_ATCCODE, atccode, KEY_ATCCODE, atccode, KEY_ATCCODE, atccode, KEY_ATCCLASS, atccode, KEY_ATCCLASS, atccode];
    NSArray *results = [mySqliteDb performQuery:query];
    
    return [self extractShortMedInfoFrom:results];
}

/** Search Reg. Nr.
 */
- (NSArray *) searchIngredients: (NSString *)ingredients
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%%, %@%%' or %@ like '%@%%' or %@ like '%%-%@%%'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_SUBSTANCES, ingredients, KEY_SUBSTANCES, ingredients, KEY_SUBSTANCES, ingredients];
    NSArray *results = [mySqliteDb performQuery:query];
    
    return [self extractShortMedInfoFrom:results];
}

/** Search Wirkstoff
 */
- (NSArray *) searchRegNr: (NSString *)regnr
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%%, %@%%' or %@ like '%@%%'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_REGNRS, regnr, KEY_REGNRS, regnr];
    NSArray *results = [mySqliteDb performQuery:query];
    
    return [self extractShortMedInfoFrom:results];
}

/** Search Therapie
 */
- (NSArray *) searchTherapy: (NSString *)therapy
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%%, %@%%' or %@ like '%@%%' or %@ like '%% %@%%'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_THERAPY, therapy, KEY_THERAPY, therapy, KEY_THERAPY, therapy];
    NSArray *results = [mySqliteDb performQuery:query];

    return [self extractShortMedInfoFrom:results];
}

/** Search Application
 */
- (NSArray *) searchApplication: (NSString *)application
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%%, %@%%' or %@ like '%@%%' or %@ like '%% %@%%' or %@ like '%%;%@%%' or %@ like '%@%%' or %@ like '%%;%@%%'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_APPLICATION, application, KEY_APPLICATION, application, KEY_APPLICATION, application, KEY_APPLICATION, application, KEY_INDICATIONS, application, KEY_INDICATIONS, application];
    NSArray *results = [mySqliteDb performQuery:query];
    
    return [self extractShortMedInfoFrom:results];
}

/** Search Reg. Nrs. given a list of reg. nr.
 */
- (NSArray *) searchRegnrsFromList:(NSArray *)listOfRegnrs
{
    const unsigned int N = 40;
    NSMutableArray *listOfMedis = [NSMutableArray new];
    
    NSUInteger C = [listOfRegnrs count];    // E.g. 100
    NSUInteger capacityA = (C / N) * N;     // E.g. 100/40 * 40 = 80
    NSUInteger capacityB = C - capacityA;   // 100 - 80 = 20
    NSMutableArray *listA = [NSMutableArray arrayWithCapacity:capacityA];
    NSMutableArray *listB = [NSMutableArray arrayWithCapacity:capacityB];
    
    [listOfRegnrs enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
        NSMutableArray *output = (index < capacityA) ? listA : listB;
        [output addObject:object];
    }];
    
    NSString *subQuery = @"";
    int count = 0;
    // Loop through first (long) list
    for (NSString *reg in listA) {
        subQuery = [subQuery stringByAppendingString:[NSString stringWithFormat:@"%@ like '%%, %@%%' or %@ like '%@%%'", KEY_REGNRS, reg, KEY_REGNRS, reg]];
        count++;
        if (count % N == 0) {
            NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@", FULL_TABLE, DATABASE_TABLE, subQuery];
            NSArray *results = [mySqliteDb performQuery:query];
            for (NSArray *cursor in results) {
                MLMedication *m = [self cursorToVeryShortMedInfo:cursor];
                [listOfMedis addObject:m];
            }
            subQuery = @"";
        }
        else {
            subQuery = [subQuery stringByAppendingString:@" or "];
        }
    }
    // Loop through second (short) list
    for (NSString *reg in listB) {
        subQuery = [subQuery stringByAppendingString:[NSString stringWithFormat:@"%@ like '%%, %@%%' or %@ like '%@%%' or ", KEY_REGNRS, reg, KEY_REGNRS, reg]];
    }
    if ([subQuery length] > 4) {
        subQuery = [subQuery substringWithRange:NSMakeRange(0, [subQuery length]-4)];   // Remove last 'or'
        NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@", FULL_TABLE, DATABASE_TABLE, subQuery];
        NSArray *results = [mySqliteDb performQuery:query];
        for (NSArray *cursor in results) {
            MLMedication *m = [self cursorToVeryShortMedInfo:cursor];
            [listOfMedis addObject:m];
        }
    }
    
    return listOfMedis;
}

- (MLMedication *) cursorToVeryShortMedInfo:(NSArray *)cursor
{
    MLMedication *medi = [MLMedication new];
    
    [medi setMedId:[(NSString *)[cursor objectAtIndex:kMedId] longLongValue]];
    [medi setTitle:(NSString *)[cursor objectAtIndex:kTitle]];
    [medi setAuth:(NSString *)[cursor objectAtIndex:kAuth]];
    [medi setRegnrs:(NSString *)[cursor objectAtIndex:kRegnrs]];
    [medi setSectionIds:(NSString *)[cursor objectAtIndex:kIdsStr]];
    [medi setSectionTitles:(NSString *)[cursor objectAtIndex:kSectionsStr]];
    
    return medi;
}

- (MLMedication *) cursorToShortMedInfo: (NSArray *)cursor
{
    MLMedication *m = [MLMedication new];
        
    [m setMedId:[(NSString *)[cursor objectAtIndex:kMedId] longLongValue]];
    [m setTitle:(NSString *)[cursor objectAtIndex:kTitle]];
    [m setAuth:(NSString *)[cursor objectAtIndex:kAuth]];
    [m setAtccode:(NSString *)[cursor objectAtIndex:kAtcCode]];
    [m setSubstances:(NSString *)[cursor objectAtIndex:kSubstances]];
    [m setRegnrs:(NSString *)[cursor objectAtIndex:kRegnrs]];
    [m setAtcClass:(NSString *)[cursor objectAtIndex:kAtcClass]];
    [m setTherapy:(NSString *)[cursor objectAtIndex:kTherapy]];
    [m setApplication:(NSString *)[cursor objectAtIndex:kApplication]];
    [m setIndications:(NSString *)[cursor objectAtIndex:kIndications]];
    [m setCustomerId:[(NSString *)[cursor objectAtIndex:kCustomerId] intValue]];
    [m setPackInfo:(NSString *)[cursor objectAtIndex:kPackInfo]];
    
    return m;
}

- (MLMedication *) cursorToFullMedInfo: (NSArray *)cursor
{
    MLMedication *m = [MLMedication new];
    
    [m setMedId:[(NSString *)[cursor objectAtIndex:kMedId] longLongValue]];
    [m setTitle:(NSString *)[cursor objectAtIndex:kTitle]];
    [m setAuth:(NSString *)[cursor objectAtIndex:kAuth]];
    [m setAtccode:(NSString *)[cursor objectAtIndex:kAtcCode]];
    [m setSubstances:(NSString *)[cursor objectAtIndex:kSubstances]];
    [m setRegnrs:(NSString *)[cursor objectAtIndex:kRegnrs]];
    [m setAtcClass:(NSString *)[cursor objectAtIndex:kAtcClass]];
    [m setTherapy:(NSString *)[cursor objectAtIndex:kTherapy]];
    [m setApplication:(NSString *)[cursor objectAtIndex:kApplication]];
    [m setIndications:(NSString *)[cursor objectAtIndex:kIndications]];
    [m setCustomerId:[(NSString *)[cursor objectAtIndex:kCustomerId] intValue]];
    [m setPackInfo:(NSString *)[cursor objectAtIndex:kPackInfo]];
    [m setPackages:(NSString *)[cursor objectAtIndex:kPackages]];

    [m setAddInfo:(NSString *)[cursor objectAtIndex:kAddInfo]];
    [m setSectionIds:(NSString *)[cursor objectAtIndex:kIdsStr]];
    [m setSectionTitles:(NSString *)[cursor objectAtIndex:kSectionsStr]];
    [m setContentStr:(NSString *)[cursor objectAtIndex:kContentStr]];
    [m setStyleStr:(NSString *)[cursor objectAtIndex:kStyleStr]];
    
    return m;
}

- (NSArray *) extractShortMedInfoFrom: (NSArray *)results
{
    NSMutableArray *medList = [NSMutableArray array];

    for (NSArray *cursor in results) {
        MLMedication *m = [MLMedication new];
        
        [m setMedId:[(NSString *)[cursor objectAtIndex:kMedId] longLongValue]];
        [m setTitle:(NSString *)[cursor objectAtIndex:kTitle]];
        [m setAuth:(NSString *)[cursor objectAtIndex:kAuth]];
        [m setAtccode:(NSString *)[cursor objectAtIndex:kAtcCode]];
        [m setSubstances:(NSString *)[cursor objectAtIndex:kSubstances]];
        [m setRegnrs:(NSString *)[cursor objectAtIndex:kRegnrs]];
        [m setAtcClass:(NSString *)[cursor objectAtIndex:kAtcClass]];
        [m setTherapy:(NSString *)[cursor objectAtIndex:kTherapy]];
        [m setApplication:(NSString *)[cursor objectAtIndex:kApplication]];
        [m setIndications:(NSString *)[cursor objectAtIndex:kIndications]];
        [m setCustomerId:[(NSString *)[cursor objectAtIndex:kCustomerId] intValue]];
        [m setPackInfo:(NSString *)[cursor objectAtIndex:kPackInfo]];
        [m setPackages:(NSString *)[cursor objectAtIndex:kPackages]];
        
        [medList addObject:m];
    }
    
    return medList;
}

- (NSArray *) extractFullMedInfoFrom: (NSArray *)results;
{
    NSMutableArray *medList = [NSMutableArray array];
    
    for (NSArray *cursor in results) {
        MLMedication *m = [MLMedication new];
        
        [m setMedId:[(NSString *)[cursor objectAtIndex:kMedId] longLongValue]];
        [m setTitle:(NSString *)[cursor objectAtIndex:kTitle]];
        [m setAuth:(NSString *)[cursor objectAtIndex:kAuth]];
        [m setAtccode:(NSString *)[cursor objectAtIndex:kAtcCode]];
        [m setSubstances:(NSString *)[cursor objectAtIndex:kSubstances]];
        [m setRegnrs:(NSString *)[cursor objectAtIndex:kRegnrs]];
        [m setAtcClass:(NSString *)[cursor objectAtIndex:kAtcClass]];
        [m setTherapy:(NSString *)[cursor objectAtIndex:kTherapy]];
        [m setApplication:(NSString *)[cursor objectAtIndex:kApplication]];
        [m setIndications:(NSString *)[cursor objectAtIndex:kIndications]];        
        [m setCustomerId:[(NSString *)[cursor objectAtIndex:kCustomerId] intValue]];
        [m setPackInfo:(NSString *)[cursor objectAtIndex:kPackInfo]];
        [m setPackages:(NSString *)[cursor objectAtIndex:kPackages]];

        [m setAddInfo:(NSString *)[cursor objectAtIndex:kAddInfo]];
        [m setSectionIds:(NSString *)[cursor objectAtIndex:kIdsStr]];
        [m setSectionTitles:(NSString *)[cursor objectAtIndex:kSectionsStr]];
        [m setContentStr:(NSString *)[cursor objectAtIndex:kContentStr]];
        [m setStyleStr:(NSString *)[cursor objectAtIndex:kStyleStr]];
        
        [medList addObject:m];
    }
    
    return medList;
}

@end
