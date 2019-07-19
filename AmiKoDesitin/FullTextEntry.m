//
//  FullTextEntry.m
//  AmiKoDesitin
//
//  Created by Alex Bettarini on 17 Jul 2019.
//  Copyright © 2019 Ywesee GmbH. All rights reserved.
//

#import "FullTextEntry.h"

@implementation FullTextEntry
{
    NSDictionary *regChaptersDict;
}

@synthesize hash;
@synthesize keyword;
@synthesize regnrs;

- (void) setRegChaptersDict:(NSMutableDictionary *)dict
{
    regChaptersDict = [NSDictionary dictionaryWithDictionary:dict];
}

- (NSDictionary *) getRegChaptersDict
{
    return regChaptersDict;
}

- (NSArray *) getRegnrsAsArray
{
    return [regChaptersDict allKeys];
}

- (unsigned long) numHits
{
    return [regChaptersDict count];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ keyword:<%@>, regnrs:<%@>, hash:<%@>",
            NSStringFromClass([self class]), keyword, regnrs, hash];
}

@end
