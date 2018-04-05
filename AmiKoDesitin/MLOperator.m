//
//  MLOperator.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 26 Jan 2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLOperator.h"
#import "MLUtility.h"

@implementation MLOperator

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

- (void)importSignatureFromDict:(NSDictionary *)dict
{
    signature = [dict objectForKey:KEY_AMK_DOC_SIGNATURE];
}

- (BOOL)importSignatureFromFile
{
    NSString *documentsDirectory = [MLUtility documentsDirectory];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:DOC_SIGNATURE_FILENAME];
    if (!filePath)
        return FALSE;
    
    UIImage *signatureImg = [[UIImage alloc] initWithContentsOfFile:filePath];
    //NSLog(@"signatureImg %@", NSStringFromCGSize(signatureImg.size));
    NSData *imgData = UIImagePNGRepresentation(signatureImg);
    signature = [imgData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    return TRUE;
}

// Return number of lines of doctor information to be displayed in the prescription
- (NSInteger)entriesCount
{
    return 5; // TODO
}

- (UIImage *)thumbnailFromSignature:(CGSize) size
{
    if (self.signature == nil)
        return nil;

    NSData *data = [[NSData alloc]
                    initWithBase64EncodedString:self.signature
                    options:NSDataBase64DecodingIgnoreUnknownCharacters];
    // original image
    UIImage* image = [UIImage imageWithData:data];
#ifdef DEBUG
    //NSLog(@"signature image size %@", NSStringFromCGSize(image.size));
#endif
    
    // resize
    CGFloat width = size.width / image.size.width;
    CGFloat height = size.height / image.size.height;
    CGFloat ratio = MIN(width, height);
    
    CGRect rect = CGRectZero;
    rect.size.width = image.size.width * ratio;
    rect.size.height = image.size.height * ratio;
    rect.origin.x = (size.width - rect.size.width) / 2.0f;
    rect.origin.y = (size.height - rect.size.height) / 2.0f;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0 );
    [image drawInRect:rect];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
#ifdef DEBUG
    //NSLog(@"rescaled size %@", NSStringFromCGSize(scaledImage.size));
#endif
    
    return scaledImage;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ title:%@, name:%@, surname:%@",
            NSStringFromClass([self class]), self.title, self.givenName, self.familyName];
}

@end
