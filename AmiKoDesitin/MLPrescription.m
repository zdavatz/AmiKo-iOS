//
//  MLPrescription.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 5 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLPrescription.h"

@implementation MLPrescription

@synthesize placeDate;
@synthesize doctor;
@synthesize patient;
@synthesize medications;

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
    NSString *hash = [receiptData objectForKey:@"prescription_hash"];
    if (hash == nil ||
        [hash isEqual:[NSNull null]] ||
        [hash isEqualToString:@""])
    {
        NSLog(@"Error with prescription hash");
#ifdef DEBUG
        NSLog(@"JSON: %@\nEnd of JSON file", receiptData);
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
    
    placeDate = [receiptData objectForKey:@"place_date"];
    if (placeDate == nil)
        placeDate = [receiptData objectForKey:@"date"];
    
    NSDictionary *operatorDict = [receiptData objectForKey:@"operator"] ?: [NSNull null];
    if (operatorDict) {
        doctor = [[MLOperator alloc] init];
        [doctor importFromDict:operatorDict];
    }
    
    NSDictionary *patientDict = [receiptData objectForKey:@"patient"] ?: [NSNull null];
    if (patientDict) {
        patient = [[MLPatient alloc] init];
        [patient importFromDict:patientDict];
    }
    
    // medications aka products
    medications = [[NSMutableArray alloc] init];
    NSArray *medicationArray = [receiptData objectForKey:@"medications"];
    if (medicationArray)
        for (NSDictionary *medicationDict in medicationArray) {
            MLProduct *med = [MLProduct importFromDict:medicationDict];
            [medications addObject:med];
        }
    
#ifdef DEBUG
//    NSLog(@"medicationArray: %@", medicationArray);

//    for (MLProduct *med in medications)
//        NSLog(@"packageInfo: %@", med.packageInfo);
#endif
}

@end
