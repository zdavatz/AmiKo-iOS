//
//  FullTextDBAdapter.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 17/07/2019.
//  Copyright © 2019 Ywesee GmbH. All rights reserved.
//

#import "FullTextDBAdapter.h"
#import "FullTextEntry.h"
#import "MLSQLiteDatabase.h"
#import "MLUtility.h"

enum {
    kRowId = 0,
    kKeyword,
    kRegnrs
};

static NSString *KEY_KEYWORD = @"keyword";
static NSString *DATABASE_TABLE = @"frequency";

@implementation FullTextDBAdapter
{
    MLSQLiteDatabase *myFullTextDb;
}

#pragma mark -

- (BOOL) openDatabase:(NSString *)dbName
{
    // A. Check first users documents folder
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsDir = [MLUtility documentsDirectory];
    NSString *filePath = [[documentsDir stringByAppendingPathComponent:dbName] stringByAppendingPathExtension:@"db"];
    // Check if database exists
    if (filePath!=nil) {
        if ([fileManager fileExistsAtPath:filePath]) {
            NSLog(@"Fulltext DB found documents folder - %@", filePath);
            myFullTextDb = [[MLSQLiteDatabase alloc] initReadOnlyWithPath:filePath];
            return true;
        }
    }
    
    // B. If no database is available, check if db is in app bundle
    filePath = [[NSBundle mainBundle] pathForResource:dbName ofType:@"db"];
    if (filePath!=nil ) {
        myFullTextDb = [[MLSQLiteDatabase alloc] initReadOnlyWithPath:filePath];
        NSLog(@"Fulltext DB found in app bundle - %@", filePath);
        return true;
    }
    
    return false;
}

- (void) closeDatabase
{
    if (myFullTextDb)
        [myFullTextDb close];
}

- (NSInteger) getNumRecords
{
    return [myFullTextDb numberRecordsForTable:DATABASE_TABLE];
}

/** Search fulltext containing keyword
 */
- (NSArray *) searchKeyword:(NSString *)keyword
{
#ifdef DEBUG
    NSLog(@"%s %d", __FUNCTION__, __LINE__);
#endif
    NSString *query = [NSString stringWithFormat:@"select * from %@ where %@ like '%@%%'", DATABASE_TABLE, KEY_KEYWORD, keyword];
    NSArray *results = [myFullTextDb performQuery:query];
#ifdef DEBUG
    NSLog(@"%s %d, results count:%lu", __FUNCTION__, __LINE__, (unsigned long)[results count]);
#endif
    
    return [self extractFullTextEntryFrom:results];
}

- (NSArray *) extractFullTextEntryFrom:(NSArray *)results
{
    NSMutableArray *entryList = [NSMutableArray array];
    
    for (NSArray *cursor in results) {
        
        assert(cursor!=nil);
        
        FullTextEntry *entry = [[FullTextEntry alloc] init];
        [entry setHash:(NSString *)[cursor objectAtIndex:kRowId]];
        [entry setKeyword:(NSString *)[cursor objectAtIndex:kKeyword]];
        NSString *regnrsAndChapters = (NSString *)[cursor objectAtIndex:kRegnrs];
        if (regnrsAndChapters!=nil) {
            NSMutableDictionary *dict = [self regChapterDict:regnrsAndChapters];
            [entry setRegChaptersDict:dict];
        }
        [entry setRegnrs:regnrsAndChapters];
        
        [entryList addObject:entry];
    }
    
    return entryList;
}

- (NSMutableDictionary *) regChapterDict:(NSString *)regChapterStr
{
    NSMutableString *regnr = [[NSMutableString alloc] init];
    NSMutableString *chapters = [[NSMutableString alloc] init];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];   // regnr -> set of chapters
    // Format: 65000(13)|65001(14)|...
    NSArray *rac = [regChapterStr componentsSeparatedByString:@"|"];
    NSMutableSet *set = [NSMutableSet setWithArray:rac];
    // Loop through all regnr-chapter pairs
    for (NSString *r in set) {
        // Extract chapters located between parentheses
        NSArray *str1 = [r componentsSeparatedByString:@"("];
        if (str1!=nil) {
            regnr = [str1 objectAtIndex:0];
            if ([str1 count]>1) {
                NSArray *str2 = [[str1 objectAtIndex:1] componentsSeparatedByString:@")"];
                chapters = [str2 objectAtIndex:0];
            }
            NSMutableSet *chaptersSet = [[NSMutableSet alloc] init];
            if ([dict objectForKey:regnr]!=nil) {
                chaptersSet = [dict objectForKey:regnr];
            }
            // Split chapters listed as comma-separated string
            NSArray *c = [chapters componentsSeparatedByString:@","];
            for (NSString *chapter in c) {
                [chaptersSet addObject:chapter];
            }
            // Update dictionary
            dict[regnr] = chaptersSet;
        } else {
            // No chapters for this regnr -> do nothing
        }
    }
    return dict;
}

@end
