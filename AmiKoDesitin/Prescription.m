//
//  Prescription.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 5 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "Prescription.h"

@implementation Prescription

@synthesize hash, placeDate;
@synthesize doctor;
@synthesize patient;
@synthesize medications;

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if (!self) {
        return nil;
    }
    NSError *error;
    NSData *encryptedData = [NSData dataWithContentsOfURL:url];
    if (encryptedData == nil) {
        NSLog(@"Cannot get data from <%@>", url);
        return nil;
    }
    NSData *decryptedData = [encryptedData initWithBase64EncodedData:encryptedData
                                                             options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    // jsonDict
    NSDictionary *receiptData = [NSJSONSerialization JSONObjectWithData:decryptedData
                                                                options:NSJSONReadingAllowFragments
                                                                  error:&error];
    if (error) {
        NSLog(@"%@", error.localizedDescription);
        return nil;
    }

    // hashedKey (prescription_hash) is required
    hash = [receiptData objectForKey:KEY_AMK_HASH];
    if (hash == nil ||
        [hash isEqual:[NSNull null]] ||
        [hash isEqualToString:@""])
    {
        NSLog(@"Error with prescription hash");
        placeDate = @"";
        doctor = nil;
        patient = nil;
        medications = nil;
        return nil;
    }
    
    placeDate = [receiptData objectForKey:KEY_AMK_PLACE_DATE];
    if (placeDate == nil)
        placeDate = [receiptData objectForKey:@"date"];
    
    NSDictionary *operatorDict = [receiptData objectForKey:KEY_AMK_OPERATOR] ? : [NSNull null];
    if (operatorDict) {
        doctor = [Operator new];
        [doctor importFromDict:operatorDict];
        [doctor importSignatureFromDict:operatorDict];
    }
    
    NSDictionary *patientDict = [receiptData objectForKey:KEY_AMK_PATIENT] ? : [NSNull null];
    if (patientDict) {
        patient = [Patient new];
        [patient importFromDict:patientDict];
    }

    medications = [NSMutableArray new];
    NSArray *medicationArray = [receiptData objectForKey:KEY_AMK_MEDICATIONS];
    if (medicationArray) {
        for (NSDictionary *medicationDict in medicationArray) {
            Product *med = [[Product alloc] initWithDict:medicationDict];
            [medications addObject:med];
        }
    }
    return self;
}

- (NSDictionary *) makePatientDictionary
{
    return [self.patient dictionaryRepresentation];
}

- (NSDictionary *) makeOperatorDictionary
{
    NSMutableDictionary *operatorDict = [NSMutableDictionary new];

    if ([doctor title])  // optional field
        [operatorDict setObject:[doctor title] forKey:KEY_AMK_DOC_TITLE];
    else
        [operatorDict setObject:@"" forKey:KEY_AMK_DOC_TITLE];
    
    [operatorDict setObject:[doctor givenName]      forKey:KEY_AMK_DOC_NAME];
    [operatorDict setObject:[doctor familyName]     forKey:KEY_AMK_DOC_SURNAME];
    [operatorDict setObject:[doctor postalAddress]  forKey:KEY_AMK_DOC_ADDRESS];
    [operatorDict setObject:[doctor city]           forKey:KEY_AMK_DOC_CITY];
    [operatorDict setObject:[doctor zipCode]        forKey:KEY_AMK_DOC_ZIP];
    [operatorDict setObject:[doctor phoneNumber]    forKey:KEY_AMK_DOC_PHONE];
    [operatorDict setObject:[doctor emailAddress]   forKey:KEY_AMK_DOC_EMAIL];
    [operatorDict setObject:[doctor signature]      forKey:KEY_AMK_DOC_SIGNATURE];
    return operatorDict;
}

- (NSArray *) makeMedicationsArray;
{
    NSMutableArray *prescription = [NSMutableArray new];
    for (Product *item in medications) {
        NSMutableDictionary *dict = [NSMutableDictionary new];
        
        [dict setObject:item.title       forKey:KEY_AMK_MED_PROD_NAME];
        [dict setObject:item.packageInfo forKey:KEY_AMK_MED_PACKAGE];
        if (item.comment)
            [dict setObject:item.comment forKey:KEY_AMK_MED_COMMENT];

        if (item.eanCode)
            [dict setObject:item.eanCode forKey:KEY_AMK_MED_EAN];
        
        
        [dict setObject:item.title       forKey:KEY_AMK_MED_TITLE];
        [dict setObject:item.auth        forKey:KEY_AMK_MED_OWNER];
        [dict setObject:item.regnrs      forKey:KEY_AMK_MED_REGNRS];
        [dict setObject:item.atccode     forKey:KEY_AMK_MED_ATC];
        
        [prescription addObject:dict];
    }
    
    return prescription;
}

@end
