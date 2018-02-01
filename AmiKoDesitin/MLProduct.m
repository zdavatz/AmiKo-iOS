//
//  MLProduct.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 1/29/18.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLProduct.h"

@implementation MLProduct

@synthesize eanCode;
@synthesize packageInfo;
@synthesize prodName;
@synthesize comment;

+ (id)importFromDict:(NSDictionary *)dict
{
    MLProduct *med = [[MLProduct alloc] init];
    
    med.eanCode = [dict objectForKey:@"eancode"];
    med.packageInfo = [dict objectForKey:@"package"];
    med.prodName = [dict objectForKey:@"product_name"];
    med.comment = [dict objectForKey:@"comment"];
    
//    med.title = [dict objectForKey:@"title"];
//    med.auth = [dict objectForKey:@"owner"];
//    med.regnrs = [dict objectForKey:@"regnrs"];
//    med.atccode = [dict objectForKey:@"atccode"];
    
    return med;
}


@end
