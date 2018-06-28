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

- (NSDictionary *) makePatientDictionary
{
    NSMutableDictionary *patientDict = [[NSMutableDictionary alloc] init];
    
    [patientDict setObject:[self.patient uniqueId] forKey:KEY_AMK_PAT_ID];
    [patientDict setObject:[self.patient givenName] forKey:KEY_AMK_PAT_NAME];
    [patientDict setObject:[self.patient familyName] forKey:KEY_AMK_PAT_SURNAME];
    [patientDict setObject:[self.patient birthDate] forKey:KEY_AMK_PAT_BIRTHDATE];
    [patientDict setObject:[NSString stringWithFormat:@"%d", patient.weightKg] forKey:KEY_AMK_PAT_WEIGHT];
    [patientDict setObject:[NSString stringWithFormat:@"%d", patient.heightCm] forKey:KEY_AMK_PAT_HEIGHT];
    [patientDict setObject:[self.patient gender] forKey:KEY_AMK_PAT_GENDER];
    [patientDict setObject:[self.patient postalAddress] forKey:KEY_AMK_PAT_ADDRESS];
    [patientDict setObject:[self.patient zipCode] forKey:KEY_AMK_PAT_ZIP];
    [patientDict setObject:[self.patient city] forKey:KEY_AMK_PAT_CITY];
    [patientDict setObject:[self.patient country] forKey:KEY_AMK_PAT_COUNTRY];
    [patientDict setObject:[self.patient phoneNumber] forKey:KEY_AMK_PAT_PHONE];
    [patientDict setObject:[self.patient emailAddress] forKey:KEY_AMK_PAT_EMAIL];
    return patientDict;
}

- (NSDictionary *) makeOperatorDictionary
{
    NSMutableDictionary *operatorDict = [[NSMutableDictionary alloc] init];

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
    NSMutableArray *prescription = [[NSMutableArray alloc] init];
    for (Product *item in medications) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        [dict setObject:item.title       forKey:KEY_AMK_MED_PROD_NAME];
        [dict setObject:item.packageInfo forKey:KEY_AMK_MED_PACKAGE];
        [dict setObject:item.comment     forKey:KEY_AMK_MED_COMMENT];
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

// see Generika importReceiptFromURL
// see AmiKo loadPrescriptionFromFile
- (void) importFromURL:(NSURL *)url
{
    NSError *error;
#ifdef DEBUG
    //NSLog(@"%s %@", __FUNCTION__, url);
#endif
    NSData *encryptedData = [NSData dataWithContentsOfURL:url];
    if (encryptedData == nil) {
        NSLog(@"Cannot get data from <%@>", url);
        return;
    }
    NSData *decryptedData = [encryptedData initWithBase64EncodedData:encryptedData
                                                             options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    // jsonDict
    NSDictionary *receiptData = [NSJSONSerialization JSONObjectWithData:decryptedData
                                                                options:NSJSONReadingAllowFragments
                                                                  error:&error];
    if (error) {
        NSLog(@"%@", error.localizedDescription);
        return;
    }

    // hashedKey (prescription_hash) is required
    hash = [receiptData objectForKey:KEY_AMK_HASH];
    if (hash == nil ||
        [hash isEqual:[NSNull null]] ||
        [hash isEqualToString:@""])
    {
        NSLog(@"Error with prescription hash");
#ifdef DEBUG
        //NSLog(@"JSON: %@\nEnd of JSON file", receiptData);
#endif
        placeDate = @"";
        doctor = nil;
        patient = nil;
        medications = nil;
        return;
    }
    
#if 0
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"hashedKey == %@", hash];
#ifdef DEBUG
    NSLog(@"predicate: %@", predicate);
#endif
//    NSArray *matched = [self.receipts filteredArrayUsingPredicate:predicate];
//    if ([matched count] > 0) {
//        // already imported
//        return;
//    }
#endif
    
    placeDate = [receiptData objectForKey:KEY_AMK_PLACE_DATE];
    if (placeDate == nil)
        placeDate = [receiptData objectForKey:@"date"];
    
    NSDictionary *operatorDict = [receiptData objectForKey:KEY_AMK_OPERATOR] ? : [NSNull null];
    if (operatorDict) {
        doctor = [[Operator alloc] init];
        [doctor importFromDict:operatorDict];
        [doctor importSignatureFromDict:operatorDict];
    }
    
    NSDictionary *patientDict = [receiptData objectForKey:KEY_AMK_PATIENT] ? : [NSNull null];
    if (patientDict) {
        patient = [[Patient alloc] init];
        [patient importFromDict:patientDict];
    }
    
    // medications aka products
    if (medications)
        [medications removeAllObjects];
    else
        medications = [[NSMutableArray alloc] init];

    NSArray *medicationArray = [receiptData objectForKey:KEY_AMK_MEDICATIONS];
    if (medicationArray)
        for (NSDictionary *medicationDict in medicationArray) {
            Product *med = [[Product alloc] initWithDict:medicationDict];
            [medications addObject:med];
        }
    
#ifdef DEBUG
//    NSLog(@"medicationArray: %@", medicationArray);

//    for (Product *med in medications)
//        NSLog(@"packageInfo: %@", med.packageInfo);
#endif
}

@end
