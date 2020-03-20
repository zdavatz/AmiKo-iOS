//
//  Operator.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 26 Jan 2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "Operator.h"
#import "MLUtility.h"
#import "MLPersistenceManager.h"

@implementation Operator

@synthesize title;
@synthesize familyName;
@synthesize givenName;
@synthesize postalAddress;
@synthesize zipCode;
@synthesize city;
@synthesize phoneNumber;
@synthesize emailAddress;

@synthesize signature;

- (void)importFromDict:(NSDictionary *)dict
{
    title =         [dict objectForKey:KEY_AMK_DOC_TITLE];
    familyName =    [dict objectForKey:KEY_AMK_DOC_SURNAME];
    givenName =     [dict objectForKey:KEY_AMK_DOC_NAME];
    postalAddress = [dict objectForKey:KEY_AMK_DOC_ADDRESS];
    city =          [dict objectForKey:KEY_AMK_DOC_CITY];
    zipCode =       [dict objectForKey:KEY_AMK_DOC_ZIP];
    phoneNumber =   [dict objectForKey:KEY_AMK_DOC_PHONE];
    emailAddress =  [dict objectForKey:KEY_AMK_DOC_EMAIL];

    if (!title) title = @"";
    if (!familyName) familyName = @"";
    if (!givenName) givenName = @"";
}

- (NSDictionary *)toDictionary {
    // Set as default for prescriptions
    NSMutableDictionary *doctorDict = [NSMutableDictionary new];
    doctorDict[KEY_AMK_DOC_TITLE] = self.title;
    doctorDict[KEY_AMK_DOC_NAME] = self.givenName;
    doctorDict[KEY_AMK_DOC_SURNAME] = self.familyName;
    doctorDict[KEY_AMK_DOC_ADDRESS] = self.postalAddress;
    doctorDict[KEY_AMK_DOC_CITY] = self.city;
    doctorDict[KEY_AMK_DOC_ZIP] = self.zipCode;
    doctorDict[KEY_AMK_DOC_PHONE] = self.phoneNumber;
    doctorDict[KEY_AMK_DOC_EMAIL] = self.emailAddress;
    return doctorDict;
}

- (void)importSignatureFromDict:(NSDictionary *)dict
{
    signature = [dict objectForKey:KEY_AMK_DOC_SIGNATURE];
}

- (BOOL)importSignatureFromFile
{
    UIImage *signatureImg = [[MLPersistenceManager shared] doctorSignature];
    NSData *imgData = UIImagePNGRepresentation(signatureImg);
    signature = [imgData base64EncodedStringWithOptions:0];
    return TRUE;
}

// Return number of lines of doctor information to be displayed in the prescription
- (NSInteger)entriesCount
{
    return 5; // TODO
}

// If the aspect ratio of the signature doesn't match the aspect ratio of the
// desiredSize, empty margins will be included in the returned image.
- (UIImage *)thumbnailFromSignature:(CGSize) desiredSize
{
    if (self.signature == nil)
        return nil;

    NSData *data = [[NSData alloc]
                    initWithBase64EncodedString:self.signature
                    options:NSDataBase64DecodingIgnoreUnknownCharacters];
    // original image
    UIImage* image = [UIImage imageWithData:data];

    // resize
    CGFloat width = desiredSize.width / image.size.width;
    CGFloat height = desiredSize.height / image.size.height;
    CGFloat ratio = MIN(width, height);
    
    CGRect rect = CGRectZero;
    rect.size.width = image.size.width * ratio;
    rect.size.height = image.size.height * ratio;
    rect.origin.x = (desiredSize.width - rect.size.width) / 2.0f;
    rect.origin.y = (desiredSize.height - rect.size.height) / 2.0f;
    
    
    UIGraphicsBeginImageContextWithOptions(desiredSize, NO, 0 );
#ifdef DEBUG
    UIColor *bgColor = [UIColor secondaryLabelColor];
    [bgColor setFill];
    CGRect bgRect = {CGPointZero, desiredSize};
    UIRectFill(bgRect);
#endif
    [image drawInRect:rect];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

- (NSString *)getStringForPrescriptionPrinting
{
    NSString *s = @"";
    
    if (title.length > 0)
        s = [NSString stringWithFormat:@"%@ ", title];
    
    s = [s stringByAppendingString:[NSString stringWithFormat:@"%@ %@\n", givenName, familyName]];
    s = [s stringByAppendingString:[NSString stringWithFormat:@"%@\n", postalAddress]];
    s = [s stringByAppendingString:[NSString stringWithFormat:@"%@ %@\n", zipCode, city]];
    s = [s stringByAppendingString:[NSString stringWithFormat:@"%@", emailAddress]];

    return s;
}

- (NSString *)getStringForLabelPrinting
{
    NSString *s = @"";
    
    if (title.length > 0)
        s = [NSString stringWithFormat:@"%@ ", title];
    
    s = [s stringByAppendingString:[NSString stringWithFormat:@"%@ ", givenName]];
    s = [s stringByAppendingString:[NSString stringWithFormat:@"%@ - ", familyName]];
    s = [s stringByAppendingString:[NSString stringWithFormat:@"%@ ", zipCode]];
    //s = [s stringByAppendingString:[NSString stringWithFormat:@"%@ ", city]]; // included in placeDate
    
    return s;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ title:%@, name:%@, surname:%@",
            NSStringFromClass([self class]), self.title, self.givenName, self.familyName];
}

@end
