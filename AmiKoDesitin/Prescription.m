//
//  Prescription.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 5 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "Prescription.h"
#import "LFCGzipUtility.h"
#import "EPrescription/EPrescription.h"
#import "MLConstants.h"

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
    bool secureFile = [url startAccessingSecurityScopedResource];
    NSData *encryptedData = [NSData dataWithContentsOfURL:url options:0 error:&error];
    if (secureFile) {
        [url stopAccessingSecurityScopedResource];
    }
    if (encryptedData == nil) {
        NSLog(@"Cannot get data from <%@>, %@", url, [error debugDescription]);
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
    return [self initWithAMKDictionary:receiptData];
}

- (instancetype)initWithAMKDictionary:(NSDictionary*)receiptData {
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
    [operatorDict setObject:[doctor title] ?: @""         forKey:KEY_AMK_DOC_TITLE];
    [operatorDict setObject:[doctor givenName] ?: @""     forKey:KEY_AMK_DOC_NAME];
    [operatorDict setObject:[doctor familyName] ?: @""    forKey:KEY_AMK_DOC_SURNAME];
    [operatorDict setObject:[doctor postalAddress] ?: @"" forKey:KEY_AMK_DOC_ADDRESS];
    [operatorDict setObject:[doctor city] ?: @""          forKey:KEY_AMK_DOC_CITY];
    [operatorDict setObject:[doctor zipCode] ?: @""       forKey:KEY_AMK_DOC_ZIP];
    [operatorDict setObject:[doctor phoneNumber] ?: @""   forKey:KEY_AMK_DOC_PHONE];
    [operatorDict setObject:[doctor emailAddress] ?: @""  forKey:KEY_AMK_DOC_EMAIL];
    [operatorDict setObject:[doctor signature] ?: @""     forKey:KEY_AMK_DOC_SIGNATURE];
    return operatorDict;
}

- (NSArray *) makeMedicationsArray;
{
    NSMutableArray *prescription = [NSMutableArray new];
    for (Product *item in medications) {
        NSMutableDictionary *dict = [NSMutableDictionary new];
        
        [dict setObject:item.title ?: @""       forKey:KEY_AMK_MED_PROD_NAME];
        [dict setObject:item.packageInfo ?: @"" forKey:KEY_AMK_MED_PACKAGE];
        if (item.comment)
            [dict setObject:item.comment forKey:KEY_AMK_MED_COMMENT];

        if (item.eanCode)
            [dict setObject:item.eanCode forKey:KEY_AMK_MED_EAN];
        
        
        [dict setObject:item.title ?: @""       forKey:KEY_AMK_MED_TITLE];
        [dict setObject:item.auth ?: @""        forKey:KEY_AMK_MED_OWNER];
        [dict setObject:item.regnrs ?: @""      forKey:KEY_AMK_MED_REGNRS];
        [dict setObject:item.atccode ?: @""     forKey:KEY_AMK_MED_ATC];
        
        [prescription addObject:dict];
    }
    
    return prescription;
}

- (NSData *)ePrescription {
    NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
    NSMutableArray *items = [NSMutableArray array];
    for (Product *item in self.medications) {
        [items addObject:@{
            @"Id": item.eanCode,
            @"IdType": @2, // GTIN
        }];
    }
    NSDictionary *jsonBody = @{
        @"Patient": @{
            @"FName": self.patient.givenName ?: @"",
            @"LName": self.patient.familyName ?: @"",
            @"BDt": [self formatBirthdayForEPrescription:self.patient.birthDate] ?: @"",
            @"Gender": [self.patient.gender isEqual:@"man"] ? @1 : [self.patient.gender isEqual:@"woman"] ? @2 : [NSNull null],
            @"Street": self.patient.postalAddress ?: @"",
            @"Zip": self.patient.zipCode ?: @"",
            @"City": self.patient.city ?: @"",
            @"Lng": [NSLocale systemLocale].localeIdentifier ?: @"",
            @"Phone": self.patient.phoneNumber ?: @"",
            @"Email": self.patient.emailAddress ?: @"",
        },
        @"Medicaments": items,
        @"MedType": @3, // Prescription
        @"Id": [[NSUUID UUID] UUIDString],
        @"Auth": self.doctor.gln ?: @"", // GLN of doctor
        @"Dt": [formatter stringFromDate:[NSDate date]],
    };
    NSError *error = nil;
    NSData *json = [NSJSONSerialization dataWithJSONObject:jsonBody
                                                   options:0
                                                     error:&error];
    NSLog(@"prescription json data %@", [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]);
    if (error != nil) {
        NSLog(@"json error %@", error);
        return nil;
    }
    NSData *gzipped = [LFCGzipUtility gzipData:json];
    NSData *base64 = [gzipped base64EncodedDataWithOptions:0];
    NSMutableData *prefixed = [NSMutableData dataWithCapacity:base64.length + 9];
    [prefixed appendData:[@"CHMED16A1" dataUsingEncoding:NSUTF8StringEncoding]];
    [prefixed appendData:base64];
    return prefixed;
}

- (ZurRosePrescription *)toZurRosePrescription {
    ZurRosePrescription *prescription = [[ZurRosePrescription alloc] init];

    NSRange placeDateCommaRange = [self.placeDate rangeOfString:@","];
    if (placeDateCommaRange.location != NSNotFound) {
        NSString *dateString = [[self.placeDate substringFromIndex:NSMaxRange(placeDateCommaRange)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"dd.MM.yyyy (HH:mm:ss)";
        [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
        NSDate *date = [dateFormatter dateFromString:self.placeDate];
        prescription.issueDate = date;
    } else {
        prescription.issueDate = [NSDate date];
    }
    
    prescription.prescriptionNr = [NSString stringWithFormat:@"%09d", arc4random_uniform(1000000000)];
    prescription.remark = @"";
    prescription.validity = nil;

    prescription.user = @"";
    prescription.password = @"";
    prescription.deliveryType = ZurRosePrescriptionDeliveryTypePatient;
    prescription.ignoreInteractions = NO;
    prescription.interactionsWithOldPres = NO;
    
    ZurRosePrescriptorAddress *prescriptor = [[ZurRosePrescriptorAddress alloc] init];
    prescription.prescriptorAddress = prescriptor;
    prescriptor.zsrId = self.doctor.zsrNumber;
    prescriptor.firstName = self.doctor.givenName;
    prescriptor.lastName = self.doctor.familyName;
    prescriptor.eanId = self.doctor.gln;
    
    prescriptor.kanton = [EPrescription swissKantonFromZip:self.doctor.zipCode];
    prescriptor.email = self.doctor.emailAddress;
    prescriptor.phoneNrBusiness = self.doctor.phoneNumber;
    prescriptor.langCode = [[MLConstants databaseLanguage] isEqual:@"de"] ? 1 : 2;
    prescriptor.clientNrClustertec = @"888870";
    prescriptor.street = self.doctor.postalAddress;
    prescriptor.zipCode = self.doctor.zipCode;
    prescriptor.city = self.doctor.city;
    
    ZurRosePatientAddress *patient = [[ZurRosePatientAddress alloc] init];
    prescription.patientAddress = patient;
    patient.lastName = self.patient.familyName;
    patient.firstName = self.patient.givenName;
    patient.street = self.patient.postalAddress;
    patient.city = self.patient.city;
    patient.kanton = [EPrescription swissKantonFromZip:self.patient.zipCode];
    patient.zipCode = self.patient.zipCode;
    {
        NSDateFormatter *birthDateDateFormatter = [[NSDateFormatter alloc] init];
        birthDateDateFormatter.dateFormat = @"dd.MM.yyyy";
        patient.birthday = [birthDateDateFormatter dateFromString:self.patient.birthDate];
    }
    patient.sex = [self.patient.gender isEqual:KEY_AMK_PAT_GENDER_M] ? 1 : 2; // same, 1 = m, 2 = f
    patient.phoneNrHome = self.patient.phoneNumber;
    patient.email = self.patient.emailAddress;
    patient.langCode = [[MLConstants databaseLanguage] isEqual:@"de"] ? 1 : 2;
    patient.coverCardId = self.patient.healthCardNumber ?: @"";
    patient.patientNr = [self.patient.ahvNumber stringByReplacingOccurrencesOfString:@"." withString:@""];

    NSMutableArray<ZurRoseProduct*> *products = [NSMutableArray array];
    for (Product *m in self.medications) {
        ZurRoseProduct *product = [[ZurRoseProduct alloc] init];
        [products addObject:product];
        
        product.eanId = m.eanCode;
        product.quantity = 1;
        product.insuranceBillingType = 1;
        product.insuranceEanId = self.patient.insuranceGLN;
        product.repetition = NO;
        
        ZurRosePosology *pos = [[ZurRosePosology alloc] init];
        pos.posologyText = m.comment;
        pos.label = 1;
        product.posology = @[pos];
    }
    prescription.products = products;
    
    return prescription;
}


- (NSString *)formatBirthdayForEPrescription:(NSString *)birthday {
    // dd.mm.yyyy -> yyyy-mm-dd
    NSArray *parts = [birthday componentsSeparatedByString:@"."];
    if (parts.count != 3) return nil;
    return [NSString stringWithFormat:@"%@-%@-%@", parts[2], parts[1], parts[0]];
}

@end
