//
//  EPrescription.m
//  Generika
//
//  Created by b123400 on 2024/11/21.
//  Copyright © 2024 ywesee GmbH. All rights reserved.
//

#import "EPrescription.h"
#import "NSData+GZIP.h"
#import "MLUtility.h"
#import "Patient.h"
#import "Prescription.h"
#import "Operator.h"

@implementation EPrescriptionPatientId
@end
@implementation EPrescriptionPField
@end
@implementation EPrescriptionTakingTime
@end
@implementation EPrescriptionPosology
@end
@implementation EPrescriptionMedicament
@end

@implementation EPrescription

- (instancetype)initWithCHMED16A1String:(NSString *)str {
    if ([str hasPrefix:@"https://eprescription.hin.ch"]) {
        NSRange range = [str rangeOfString:@"#"];
        if (range.location == NSNotFound) return nil;
        str = [str substringFromIndex:range.location + 1];
        range = [str rangeOfString:@"&"];
        if (range.location == NSNotFound) return nil;
        str = [str substringToIndex:range.location];
    }
    NSData *jsonData = nil;
    NSString *prefix = @"CHMED16A1";
    if ([str hasPrefix:prefix]) {
        str = [str substringFromIndex:[prefix length]];
        NSData *compressed = [[NSData alloc] initWithBase64EncodedString:str options:0];
        jsonData = [compressed gunzippedData];
    }
    prefix = @"CHMED16A0";
    if ([str hasPrefix:prefix]) {
        str = [str substringFromIndex:[prefix length]];
        jsonData = [str dataUsingEncoding:NSUTF8StringEncoding];
    }
    if (!jsonData) {
        return nil;
    }
    if (self = [super init]) {
        NSError *error = nil;
        NSDictionary *jsonObj = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        if (![jsonObj isKindOfClass:[NSDictionary class]]) {
            return nil;
        }
        
        self.auth = jsonObj[@"Auth"];
        self.date = [EPrescription parseDateString:jsonObj[@"Dt"]];
        self.prescriptionId = jsonObj[@"Id"];
        self.medType = jsonObj[@"MedType"];
        self.zsr = jsonObj[@"Zsr"];
        self.rmk = jsonObj[@"Rmk"];

        NSMutableArray<EPrescriptionPField *> *pfields = [NSMutableArray array];
        for (NSDictionary *pfield in jsonObj[@"PFields"]) {
            EPrescriptionPField *pf = [[EPrescriptionPField alloc] init];
            pf.nm = pfield[@"Nm"];
            pf.value = pfield[@"Val"];
            [pfields addObject:pf];
        }
        self.PFields = pfields;
        
        NSDictionary *patient = jsonObj[@"Patient"];
        self.patientBirthdate = [EPrescription parseDateString:patient[@"BDt"]];
        self.patientCity = patient[@"City"];
        self.patientFirstName = patient[@"FName"];
        self.patientLastName = patient[@"LName"];
        self.patientGender = patient[@"Gender"];
        self.patientPhone = patient[@"Phone"];
        self.patientStreet = patient[@"Street"];
        self.patientZip = patient[@"Zip"];
        self.patientEmail = patient[@"Email"];
        self.patientReceiverGLN = patient[@"Rcv"];
        self.patientLang = patient[@"Lng"];
        
        NSMutableArray<EPrescriptionPatientId *> *patientIds = [NSMutableArray array];
        for (NSDictionary *patientIdDict in patient[@"Ids"]) {
            EPrescriptionPatientId *pid = [[EPrescriptionPatientId alloc] init];
            pid.value = patientIdDict[@"Val"];
            pid.type = patientIdDict[@"Type"];
            [patientIds addObject:pid];
        }
        self.patientIds = patientIds;
        
        NSMutableArray<EPrescriptionPField *> *patientPFields = [NSMutableArray array];
        for (NSDictionary *patientPField in patient[@"PFields"]) {
            EPrescriptionPField *pf = [[EPrescriptionPField alloc] init];
            pf.nm = patientPField[@"Nm"];
            pf.value = patientPField[@"Val"];
            [patientPFields addObject:pf];
        }
        self.patientPFields = patientPFields;
        
        NSMutableArray<EPrescriptionMedicament *> *medicaments = [NSMutableArray array];
        for (NSDictionary *medicament in jsonObj[@"Medicaments"]) {
            EPrescriptionMedicament *m = [[EPrescriptionMedicament alloc] init];
            m.appInstr = medicament[@"AppInstr"];
            m.medicamentId = medicament[@"Id"];
            m.idType = medicament[@"IdType"];
            m.unit = medicament[@"Unit"];
            m.rep = medicament[@"rep"];
            m.nbPack = medicament[@"NbPack"];
            m.subs = medicament[@"Subs"];
            
            NSMutableArray<EPrescriptionPosology*> *pos = [NSMutableArray array];
            for (NSDictionary *posDict in medicament[@"Pos"]) {
                EPrescriptionPosology *p = [[EPrescriptionPosology alloc] init];
                
                p.dtFrom = [EPrescription parseDateString:posDict[@"DtFrom"]];
                p.dtTo = [EPrescription parseDateString:posDict[@"DtTo"]];
                p.cyDu = posDict[@"CyDu"];
                p.inRes = posDict[@"InRes"];
                
                p.d = posDict[@"D"];
                
                NSMutableArray<EPrescriptionTakingTime*>* tts = [NSMutableArray array];
                for (NSDictionary *ttDict in posDict[@"TT"]) {
                    EPrescriptionTakingTime *tt = [[EPrescriptionTakingTime alloc] init];
                    tt.off = ttDict[@"Off"];
                    tt.du = ttDict[@"Du"];
                    tt.doFrom = ttDict[@"DoFrom"];
                    tt.doTo = ttDict[@"DoTo"];
                    tt.a = ttDict[@"A"];
                    tt.ma = ttDict[@"MA"];
                    [tts addObject:tt];
                }
                p.tt = tts;
                
                [pos addObject:p];
            }
            m.pos = pos;
            
            [medicaments addObject:m];
        }
        self.medicaments = medicaments;
    }
    return self;
}

+ (NSDate *)parseDateString:(NSString *)str {
    if (!str || ![str isKindOfClass:[NSString class]]) return nil;
    static dispatch_once_t onceToken;
    static NSDateFormatter *isoFormatter = nil;
    static NSDateFormatter *isoDateFormatter = nil;
    // The specification says it's ISO8601, but I got a non-standard date as the sample input
    static NSDateFormatter *ePrescriptionFormatter = nil;
    dispatch_once(&onceToken, ^{
        isoFormatter = [[NSISO8601DateFormatter alloc] init];
        isoDateFormatter = [[NSDateFormatter alloc] init];
        isoDateFormatter.dateFormat = @"yyyy-MM-dd";
        ePrescriptionFormatter = [[NSDateFormatter alloc] init];
        ePrescriptionFormatter.dateFormat = @"yyyy-MM-ddHH:mm:ssZ";
    });
    NSDate *date = [isoFormatter dateFromString:str];
    if (date) return date;
    
    date = [isoDateFormatter dateFromString:str];
    if (date) return date;
    
    date = [ePrescriptionFormatter dateFromString:str];
    if (date) return date;
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([\\+|\\-])([0-9]{1,2}):?([0-9]{1,2})$"
                                                                           options:0
                                                                             error:&error];
    NSTextCheckingResult *result = [regex firstMatchInString:str options:0 range:NSMakeRange(0, str.length)];
    NSString *timeZoneOffsetMark = [str substringWithRange:[result rangeAtIndex:1]];
    NSString *timeZoneOffsetHour = [str substringWithRange:[result rangeAtIndex:2]];
    NSString *timeZoneOffsetMinutes = [str substringWithRange:[result rangeAtIndex:3]];
    
    NSString *newDateString = [NSString stringWithFormat:@"%@%@%02d:%02d",
                               [str substringToIndex:[result range].location],
                               timeZoneOffsetMark,
                               [timeZoneOffsetHour intValue],
                               [timeZoneOffsetMinutes intValue]
    ];
    
    date = [ePrescriptionFormatter dateFromString:newDateString];
    return date;
}

- (ZurRosePrescription *)toZurRosePrescription {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    ZurRosePrescription *prescription = [[ZurRosePrescription alloc] init];

    prescription.issueDate = self.date;
    prescription.prescriptionNr = [NSString stringWithFormat:@"%09d", arc4random_uniform(1000000000)];
    prescription.remark = self.rmk;
    prescription.validity = self.valDt; // ???

    prescription.user = @"";
    prescription.password = @"";
    prescription.deliveryType = ZurRosePrescriptionDeliveryTypePatient;
    prescription.ignoreInteractions = NO;
    prescription.interactionsWithOldPres = NO;
    
    ZurRosePrescriptorAddress *prescriptor = [[ZurRosePrescriptorAddress alloc] init];
    prescription.prescriptorAddress = prescriptor;
    prescriptor.zsrId = self.zsr;
    prescriptor.lastName = self.auth; // ???
    
    prescriptor.langCode = 1;
    prescriptor.clientNrClustertec = @"888870";
    prescriptor.street = @"";
    prescriptor.zipCode = @"";
    prescriptor.city = @"";

    NSString *insuranceEan = nil;
    NSString *coverCardId = nil;
    for (EPrescriptionPatientId *pid in self.patientIds) {
        if ([pid.type isEqual:@(1)]) {
            if (pid.value.length == 13) {
                insuranceEan = pid.value;
            } else if (pid.value.length == 20 || [pid.value containsString:@"."]) {
                coverCardId = pid.value;
            }
        }
    }
    
    ZurRosePatientAddress *patient = [[ZurRosePatientAddress alloc] init];
    prescription.patientAddress = patient;
    patient.lastName = self.patientLastName;
    patient.firstName = self.patientFirstName;
    patient.street = self.patientStreet;
    patient.city = self.patientCity;
    patient.kanton = [EPrescription swissKantonFromZip:self.patientZip];
    patient.zipCode = self.patientZip;
    patient.birthday = self.patientBirthdate;
    patient.sex = [self.patientGender intValue]; // same, 1 = m, 2 = f
    patient.phoneNrHome = self.patientPhone;
    patient.email = self.patientEmail;
    patient.langCode = [self.patientLang.lowercaseString hasPrefix:@"de"] ? 1
        : [self.patientLang.lowercaseString hasPrefix:@"fr"] ? 2
        : [self.patientLang.lowercaseString hasPrefix:@"it"] ? 3
        : 1;
    patient.coverCardId = coverCardId ?: @"";
    patient.patientNr = @"0";
    
    NSMutableArray<ZurRoseProduct*> *products = [NSMutableArray array];
    for (EPrescriptionMedicament *medi in self.medicaments) {
        ZurRoseProduct *product = [[ZurRoseProduct alloc] init];
        [products addObject:product];
        
        switch (medi.idType.intValue) {
            case 2:
                // GTIN
                product.eanId = medi.medicamentId;
                break;
            case 3:
                // Pharmacode
                product.pharmacode = medi.medicamentId;
                break;
        }
        product.quantity = medi.nbPack.intValue; // ???
        product.remark = medi.appInstr;
        product.insuranceBillingType = 1;
        product.insuranceEanId = insuranceEan;
        
        BOOL repetition = NO;
        NSDate *validityRepetition = nil;
        NSMutableArray<ZurRosePosology *> *poses = [NSMutableArray array];
        ZurRosePosology *pos = [[ZurRosePosology alloc] init];
        [poses addObject:pos];
        for (EPrescriptionPosology *mediPos in medi.pos) {
            if (mediPos.d.count) {
                pos.qtyMorning = mediPos.d[0].intValue;
                pos.qtyMidday = mediPos.d[1].intValue;
                pos.qtyEvening = mediPos.d[2].intValue;
                pos.qtyNight = mediPos.d[3].intValue;
                pos.posologyText = medi.appInstr;
            }
            if (mediPos.dtTo) {
                repetition = YES;
                validityRepetition = mediPos.dtTo;
            }
        }
        product.validityRepetition = [dateFormatter stringFromDate:validityRepetition];
        product.repetition = repetition;
        product.posology = poses;
    }
    prescription.products = products;
    
    return prescription;
}

+ (NSString *)swissKantonFromZip:(NSString *)zip {
    if (!zip.length) return nil;
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"swiss-zip-to-kanton" withExtension:@"json"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSError *error = nil;
    NSDictionary *parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    return parsed[zip];
}

- (NSString *)generatePatientUniqueID
{
    NSString *birthDateString = @"";
    
    if (self.patientBirthdate) {
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:self.patientBirthdate];
        birthDateString = [NSString stringWithFormat:@"%ld.%ld.%ld", (long)components.day, (long)components.month, (long)components.year];
    }

    // The UUID should be unique and should be based on familyname, givenname, and birthday
    NSString *str = [NSString stringWithFormat:@"%@.%@.%@", [self.patientLastName lowercaseString] , [self.patientFirstName lowercaseString], birthDateString];
    NSString *hashed = [MLUtility sha256:str];
    return hashed;
}

- (NSDictionary *)amkDict {
    NSDateFormatter *birthDateDateFormatter = [[NSDateFormatter alloc] init];
    birthDateDateFormatter.dateFormat = @"dd.MM.yyyy";
    
    NSDateFormatter *placeDateFormatter = [[NSDateFormatter alloc] init];
    placeDateFormatter.dateFormat = @"dd.MM.yyyy (HH:mm:ss)";
    [placeDateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    
    NSMutableArray<NSDictionary*> *mediDicts = [NSMutableArray array];
    
    for (EPrescriptionMedicament *medi in self.medicaments) {
        [mediDicts addObject:@{
            @"eancode": medi.medicamentId,
        }];
    }
    
    NSString *firstPatientId = self.patientIds.firstObject.value ?: self.patientReceiverGLN;
    NSString *coverCardId = nil;
    NSString *insuranceGLN = nil;
    if (firstPatientId.length == 13) {
        insuranceGLN = firstPatientId;
    } else if (firstPatientId.length == 20 || [firstPatientId containsString:@"."]) {
        coverCardId = firstPatientId;
    }
    
    NSDictionary *amkDict = @{
        KEY_AMK_HASH: [[NSUUID UUID] UUIDString],
        // Normally place_date is composed with doctor's name or city,
        // however it's not available in ePrescription, instead we put the ZSR nummber here
        KEY_AMK_PLACE_DATE: [NSString stringWithFormat:@"%@,%@", self.zsr ?: @"", [placeDateFormatter stringFromDate:self.date ?: [NSDate date]]],
        KEY_AMK_OPERATOR: @{
            KEY_AMK_DOC_GLN: self.auth ?: @"",
            KEY_AMK_DOC_ZSR_NUMBER: self.zsr ?: @"",
        },
        KEY_AMK_PATIENT: @{
            KEY_AMK_PAT_ID: [self generatePatientUniqueID],
            KEY_AMK_PAT_NAME: self.patientFirstName ?: @"",
            KEY_AMK_PAT_SURNAME: self.patientLastName ?: @"",
            KEY_AMK_PAT_BIRTHDATE: self.patientBirthdate ? [birthDateDateFormatter stringFromDate:self.patientBirthdate] : @"",
            KEY_AMK_PAT_GENDER: self.patientGender.intValue == 1 ? KEY_AMK_PAT_GENDER_M : KEY_AMK_PAT_GENDER_F,
            KEY_AMK_PAT_EMAIL: self.patientEmail ?: @"",
            KEY_AMK_PAT_PHONE: self.patientPhone ?: @"",
            KEY_AMK_PAT_ADDRESS: self.patientStreet ?: @"",
            KEY_AMK_PAT_CITY: self.patientCity ?: @"",
            KEY_AMK_PAT_ZIP: self.patientZip ?: @"",
            KEY_AMK_PAT_INSURANCE_GLN: insuranceGLN ?: @"",
            KEY_AMK_PAT_HEALTH_CARD_NUMBER: coverCardId ?: @"",
        },
        KEY_AMK_MEDICATIONS: mediDicts,
    };
    return amkDict;
}

@end
