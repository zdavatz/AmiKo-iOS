//
//  Product.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 1/29/18.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "Product.h"

@implementation Product

@synthesize eanCode;
@synthesize packageInfo;
@synthesize prodName;
@synthesize comment;

@synthesize title, auth, regnrs, atccode;

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ ean:%@, regnrs:%@ <%@>",
            NSStringFromClass([self class]), self.eanCode, self.regnrs, self.title];
}

- (instancetype)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        eanCode     = [dict objectForKey:KEY_AMK_MED_EAN];
        packageInfo = [dict objectForKey:KEY_AMK_MED_PACKAGE];
        prodName    = [dict objectForKey:KEY_AMK_MED_PROD_NAME];
        comment     = [dict objectForKey:KEY_AMK_MED_COMMENT];
        
        title       = [dict objectForKey:KEY_AMK_MED_TITLE];
        auth        = [dict objectForKey:KEY_AMK_MED_OWNER];
        regnrs      = [dict objectForKey:KEY_AMK_MED_REGNRS];
        atccode     = [dict objectForKey:KEY_AMK_MED_ATC];
    }
    return self;
}

- (instancetype)initWithMedication:(MLMedication *)m :(NSInteger)packageIndex
{
#ifdef DEBUG
    NSLog(@"%s idx:%ld", __FUNCTION__, packageIndex);
#endif
    self = [super init];
    if (self) {
        NSArray *listOfPacks = [m.packages componentsSeparatedByString:@"\n"];
        if (packageIndex < [listOfPacks count])
        {
            NSArray *p = [listOfPacks[packageIndex] componentsSeparatedByString:@"|"];
            if ([p count] > INDEX_EAN_CODE_IN_PACK)
                self.eanCode = [p objectAtIndex:INDEX_EAN_CODE_IN_PACK];  // 2nd line in prescription view
        }
        
        NSArray *listOfPackInfos = [m.packInfo componentsSeparatedByString:@"\n"];
        if (packageIndex < [listOfPackInfos count]) {
            self.packageInfo = listOfPackInfos[packageIndex]; // 1st line in prescription view
        }
        
        self.prodName = @"";    // TODO
        self.comment = @"";     // TODO

        self.title = m.title;
        self.auth = m.auth;
        self.atccode = m.atccode;
        self.regnrs = m.regnrs;
        
        self.medication = m;
    }

    return self;
}

@end
