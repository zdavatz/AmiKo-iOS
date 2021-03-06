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

static NSString *KEY_ROWID = @"id";
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
#ifdef DEBUG
            NSLog(@"Fulltext DB found documents folder - %@", filePath);
#endif
            myFullTextDb = [[MLSQLiteDatabase alloc] initReadOnlyWithPath:filePath];
            return true;
        }
    }
    
    // B. If no database is available, check if db is in app bundle
    filePath = [[NSBundle mainBundle] pathForResource:dbName ofType:@"db"];
    if (filePath!=nil ) {
        myFullTextDb = [[MLSQLiteDatabase alloc] initReadOnlyWithPath:filePath];
#ifdef DEBUG
        NSLog(@"Fulltext DB found in app bundle - %@", filePath);
#endif
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

/** Get full text from hash
 */
- (FullTextEntry *) searchHash:(NSString *)hash
{
    NSString *query = [NSString stringWithFormat:@"select * from %@ where %@ like '%@'", DATABASE_TABLE, KEY_ROWID, hash];
    NSArray *results = [myFullTextDb performQuery:query];
    
    return [self cursorToFullTextEntry:[results firstObject]];
}

/** Search fulltext containing keyword
 */
- (NSArray *) searchKeyword:(NSString *)keyword
{
    NSString *query = [NSString stringWithFormat:@"select * from %@ where %@ like '%@%%'", DATABASE_TABLE, KEY_KEYWORD, keyword];
    NSArray *results = [myFullTextDb performQuery:query];
    
    return [self extractFullTextEntryFrom:results];
}

- (FullTextEntry *) cursorToFullTextEntry:(NSArray *)cursor
{
    FullTextEntry *entry = [FullTextEntry new];
    
    [entry setHash:(NSString *)[cursor objectAtIndex:kRowId]];
    [entry setKeyword:(NSString *)[cursor objectAtIndex:kKeyword]];
    NSString *regnrsAndChapters = (NSString *)[cursor objectAtIndex:kRegnrs];
    if (regnrsAndChapters!=nil) {
        NSMutableDictionary *dict = [self regChapterDict:regnrsAndChapters];
        [entry setRegChaptersDict:dict];
    }
    [entry setRegnrs:regnrsAndChapters];
    
    return entry;
}

- (NSArray *) extractFullTextEntryFrom:(NSArray *)results
{
    NSMutableArray *entryList = [NSMutableArray array];
    
    for (NSArray *cursor in results) {
        
        assert(cursor!=nil);
        
        FullTextEntry *entry = [FullTextEntry new];
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
    NSMutableString *regnr = [NSMutableString new];
    NSMutableString *chapters = [NSMutableString new];
    NSMutableDictionary *dict = [NSMutableDictionary new];   // regnr -> set of chapters
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
            NSMutableSet *chaptersSet = [NSMutableSet new];
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
        }
        else {
            // No chapters for this regnr -> do nothing
        }
    }
    return dict;
}

@end
