//
//  FullTextSearch.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 17/07/2019.
//  Copyright © 2019 Ywesee GmbH. All rights reserved.
//

#import "FullTextSearch.h"
#import "MLMedication.h"

@implementation FullTextSearch
{
    NSArray *mListOfArticles;
    NSDictionary *mDict;
}

@synthesize listOfSectionIds;
@synthesize listOfSectionTitles;

- (NSString *) tableWithArticles:(NSArray *)listOfArticles
              andRegChaptersDict:(NSDictionary *)dict
                       andFilter:(NSString *)filter
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif

    int rows = 0;
    NSMutableDictionary *chaptersCountDict = [[NSMutableDictionary alloc] init];
    NSString *htmlStr = @"<ul>";
    
    // Assign list and dictionaries only if != nil
    if (listOfArticles!=nil) {
        mListOfArticles = listOfArticles;
        // Sort alphabetically (this is pretty neat!)
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
        mListOfArticles = [mListOfArticles sortedArrayUsingDescriptors:@[sort]];
    }

#ifdef DEBUG
    NSLog(@"%s %d, mListOfArticles count: %lu", __FUNCTION__, __LINE__, (unsigned long)[mListOfArticles count]);
#endif

    if (dict)
        mDict = dict;
    
    // Loop through all articles
    for (MLMedication *m in mListOfArticles) {
        BOOL filtered = true;
        NSString *contentStyle;
        
        if (rows % 2 == 0)
            contentStyle = [NSString stringWithFormat:@"<li style=\"background-color:var(--background-color-gray);\" id=\"{firstLetter}\">"];
        else
            contentStyle = [NSString stringWithFormat:@"<li style=\"background-color:transparent;\" id=\"{firstLetter}\">"];
        
        NSString *contentTitle = [NSString stringWithFormat:@"<a onclick=\"displayFachinfo('%@','{anchor}')\"><span style=\"font-size:0.8em\"><b>%@</b></span></a> <span style=\"font-size:0.7em\"> | %@</span><br>", m.regnrs, m.title, m.auth];
        
        NSString *contentChapters = @"";
        NSArray *regnrs = [m.regnrs componentsSeparatedByString:@","];
        NSDictionary *indexToTitlesDict = [m indexToTitlesDict];    // id -> chapter title

        // List of chapters
        if ([regnrs count] > 0) {
            NSString *r = [regnrs objectAtIndex:0];
            if ([mDict objectForKey:r]) {
                NSSet *chapters = mDict[r];
                for (NSString *c in chapters) {
                    if ([indexToTitlesDict objectForKey:c]) {
                        NSString *cStr = indexToTitlesDict[c];
                        NSString *sectionNamePrefix;
                        if ([c intValue] > 100)
                            sectionNamePrefix = @"Section";
                        else
                            sectionNamePrefix = @"section";
                        
                        NSString *anchor = [NSString stringWithFormat:@"%@%@", sectionNamePrefix, c];
                        
                        int count = 0;
                        if ([chaptersCountDict objectForKey:cStr])
                            count = [chaptersCountDict[cStr] intValue];

                        chaptersCountDict[cStr] = [NSNumber numberWithInt:count+1];
                        if ([filter length]==0 || [filter isEqualToString:cStr]) {
                            contentChapters = [contentChapters stringByAppendingFormat:@"<span style=\"font-size:0.75em; color:#0088BB\"> <a onclick=\"displayFachinfo('%@','%@')\">%@</a></span><br>", m.regnrs, anchor, cStr];
                            filtered = false;
                        }
                    }
                }
            }
        }

        if (!filtered) {
            htmlStr = [htmlStr stringByAppendingFormat:@"%@%@%@</li>", contentStyle, contentTitle, contentChapters];
            rows++;
        }
    }
    
    htmlStr = [htmlStr stringByAppendingFormat:@"</ul>"];
    
    NSMutableArray *listOfIds = [[NSMutableArray alloc] init];
    NSMutableArray *listOfTitles = [[NSMutableArray alloc] init];
    for (NSString *cStr in chaptersCountDict) {
        [listOfIds addObject:cStr];
        [listOfTitles addObject:[NSString stringWithFormat:@"%@ (%@)", cStr, chaptersCountDict[cStr]]];
    }

    // Update section ids (anchors)
    listOfSectionIds = [NSArray arrayWithArray:listOfIds];

    // Update section titles
    listOfSectionTitles = [NSArray arrayWithArray:listOfTitles];
    
    return htmlStr;
}

@end
