//
//  MLOperator.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 26 Jan 2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLOperator.h"

@implementation MLOperator

@synthesize title;
@synthesize familyName;
@synthesize givenName;
@synthesize postalAddress;
@synthesize zipCode;
@synthesize city;
@synthesize country;
@synthesize phoneNumber;
@synthesize emailAddress;

@synthesize signature;

- (void)importFromDict:(NSDictionary *)dict
{
    title = [dict objectForKey:@"title"];
    familyName = [dict objectForKey:@"family_mame"];
    givenName = [dict objectForKey:@"given_name"];
    postalAddress = [dict objectForKey:@"postal_address"];
    zipCode = [dict objectForKey:@"zip_code"];
    city = [dict objectForKey:@"city"];
    country = @"";
    phoneNumber = [dict objectForKey:@"phone_number"];
    emailAddress = [dict objectForKey:@"email_address"];

    if (!title) title = @"";
    if (!familyName) familyName = @"";
    if (!givenName) givenName = @"";

    signature = [dict objectForKey:@"signature"];
}

// Return number of lines of doctor information to be displayed in the prescription
- (NSInteger)entriesCount
{
    return 5; // TODO
}

- (UIImage *)signatureThumbnail
{
    if (self.signature == nil) {
        return nil;
    }
    NSData *data = [[NSData alloc]
                    initWithBase64EncodedString:self.signature
                    options:NSDataBase64DecodingIgnoreUnknownCharacters];
    // original image
    UIImage* image = [UIImage imageWithData:data];
    
    // resize
    CGSize size = CGSizeMake(DOCTOR_TN_W, DOCTOR_TN_H);
    CGRect rect = CGRectZero;
    
    CGFloat width = size.width / image.size.width;
    CGFloat height = size.height / image.size.height;
    CGFloat ratio = MIN(width, height);
    
    rect.size.width = image.size.width * ratio;
    rect.size.height = image.size.height * ratio;
    rect.origin.x = (size.width - rect.size.width) / 2.0f;
    rect.origin.y = (size.height - rect.size.height) / 2.0f;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0 );
    [image drawInRect:rect];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

@end
