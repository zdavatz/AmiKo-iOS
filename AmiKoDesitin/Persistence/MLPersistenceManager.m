//
//  MLPersistenceManager.m
//  AmiKoDesitin
//
//  Created by b123400 on 2020/03/14.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//

#import "MLPersistenceManager.h"
#import "MLConstants.h"
#import "MLUtility.h"
#import "Operator.h"
#import "Prescription.h"
#import "PatientModel+CoreDataClass.h"
#import "LegacyPatientDBAdapter.h"
#import "MLiCloudToLocalMigration.h"

#define KEY_PERSISTENCE_SOURCE @"KEY_PERSISTENCE_SOURCE"

@interface MLPersistenceManager () <MLiCloudToLocalMigrationDelegate>

@property (nonatomic, strong) MLiCloudToLocalMigration *iCloudToLocalMigration;

- (void)migrateToICloud;
- (void)migrateToLocal:(BOOL)deleteFilesOnICloud;

- (NSURL *)amkBaseDirectory;
- (PatientModel *)getPatientModelWithUniqueID:(NSString *)uniqueID;

@property NSPersistentCloudKitContainer *coreDataContainer;

@end

@implementation MLPersistenceManager

+ (instancetype)shared {
    __strong static id sharedObject = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObject = [[MLPersistenceManager alloc] init];
    });
    
    return sharedObject;
}

- (instancetype)init {
    if (self = [super init]) {
        self.coreDataContainer = [[NSPersistentCloudKitContainer alloc] initWithName:@"Model"];

        if (self.currentSource == MLPersistenceSourceICloud) {
            NSPersistentStoreDescription *description = [[self.coreDataContainer persistentStoreDescriptions] firstObject];
            NSPersistentCloudKitContainerOptions *options = [[NSPersistentCloudKitContainerOptions alloc] initWithContainerIdentifier:[MLConstants iCloudContainerIdentifier]];
            description.cloudKitContainerOptions = options;
        }

        [self.coreDataContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull desc, NSError * _Nullable error) {
            if (error != nil) {
                NSLog(@"Coredata error %@", error);
                return;
            }
            [self.coreDataContainer viewContext].automaticallyMergesChangesFromParent = YES;
            [self migratePatientSqliteToCoreData];
        }];
        
        [self migrateFromOldFile];
    }
    return self;
}

+ (BOOL)supportICloud {
    return [[NSFileManager defaultManager] ubiquityIdentityToken] != nil;
}

- (void)setCurrentSourceToLocalWithDeleteICloud:(BOOL)deleteFilesOnICloud {
    if (self.currentSource == MLPersistenceSourceLocal) return;
    [self migrateToLocal:deleteFilesOnICloud];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:MLPersistenceSourceLocal forKey:KEY_PERSISTENCE_SOURCE];
    [defaults synchronize];
}
- (void)setCurrentSourceToICloud {
    if (self.currentSource == MLPersistenceSourceICloud || ![MLPersistenceManager supportICloud]) {
        return;
    }
    [self migrateToICloud];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:MLPersistenceSourceICloud forKey:KEY_PERSISTENCE_SOURCE];
    [defaults synchronize];
}

- (MLPersistenceSource)currentSource {
    MLPersistenceSource source = [[NSUserDefaults standardUserDefaults] integerForKey:KEY_PERSISTENCE_SOURCE];
    if (source == MLPersistenceSourceICloud && [MLPersistenceManager supportICloud]) {
        return MLPersistenceSourceICloud;
    }
    return MLPersistenceSourceLocal;
}

- (NSURL *)iCloudDocumentDirectory {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSURL *rootDir = [manager URLForUbiquityContainerIdentifier:[MLConstants iCloudContainerIdentifier]];
    NSURL *docUrl = [rootDir URLByAppendingPathComponent:@"Documents"];
    if (![manager fileExistsAtPath:[docUrl path]]) {
        [manager createDirectoryAtURL:docUrl
          withIntermediateDirectories:YES
                           attributes:nil
                                error:nil];
    }
    return docUrl;
}

- (NSURL *)documentDirectory {
    if (self.currentSource == MLPersistenceSourceICloud) {
        return [self iCloudDocumentDirectory];
    }
    return [NSURL fileURLWithPath:[MLUtility documentsDirectory]];
}

- (NSManagedObjectContext *)managedViewContext {
    return self.coreDataContainer.viewContext;
}

# pragma mark - Migration Local -> iCloud

- (void)migrateToICloud {
    if (self.currentSource == MLPersistenceSourceICloud) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSPersistentStoreDescription *description = [[self.coreDataContainer persistentStoreDescriptions] firstObject];
        NSPersistentCloudKitContainerOptions *options = [[NSPersistentCloudKitContainerOptions alloc] initWithContainerIdentifier:[MLConstants iCloudContainerIdentifier]];
        description.cloudKitContainerOptions = options;

        [self doctorDictionary]; // Migrate to file based doctor storage
        NSURL *localDocument = [NSURL fileURLWithPath:[MLUtility documentsDirectory]];
        NSURL *remoteDocument = [self iCloudDocumentDirectory];

        [MLUtility moveFile:[localDocument URLByAppendingPathComponent:@"doctor.plist"]
                      toURL:[remoteDocument URLByAppendingPathComponent:@"doctor.plist"]
   overwriteIfExisting:NO];
        [MLUtility moveFile:[localDocument URLByAppendingPathComponent:DOC_SIGNATURE_FILENAME]
                      toURL:[remoteDocument URLByAppendingPathComponent:DOC_SIGNATURE_FILENAME]
        overwriteIfExisting:YES];
        [MLUtility moveFile:[localDocument URLByAppendingPathComponent:@"favourites"]
                      toURL:[remoteDocument URLByAppendingPathComponent:@"favourites"]
        overwriteIfExisting:YES];
        [MLUtility mergeFolderRecursively:[localDocument URLByAppendingPathComponent:@"amk" isDirectory:YES]
                                       to:[remoteDocument URLByAppendingPathComponent:@"amk" isDirectory:YES]
                           deleteOriginal:YES];
    });
}

# pragma mark - Migrate to local

- (void)migrateToLocal:(BOOL)deleteFilesOnICloud {
    if (self.currentSource == MLPersistenceSourceLocal) {
        return;
    }
    NSPersistentStoreDescription *description = [[self.coreDataContainer persistentStoreDescriptions] firstObject];
    description.cloudKitContainerOptions = nil;

    MLiCloudToLocalMigration *migration = [[MLiCloudToLocalMigration alloc] init];
    migration.delegate = self;
    migration.deleteFilesOnICloud = deleteFilesOnICloud;
    [migration start];
    self.iCloudToLocalMigration = migration;
}

- (void)didFinishedICloudToLocalMigration:(id)sender {
    self.iCloudToLocalMigration = nil;
    NSLog(@"Migration is done");
}

# pragma mark - Doctor

- (NSURL *)doctorDictionaryURL {
    return [[self documentDirectory] URLByAppendingPathComponent:@"doctor.plist"];
}

- (void)setDoctorDictionary:(NSDictionary *)dict {
    [dict writeToURL:self.doctorDictionaryURL
          atomically:YES];
}

- (NSDictionary *)doctorDictionary {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *doctorDictionary = [defaults dictionaryForKey:@"currentDoctor"];
    if (doctorDictionary != nil) {
        // Migrate to use document file
        [self setDoctorDictionary:doctorDictionary];
        [defaults removeObjectForKey:@"currentDoctor"];
        [defaults synchronize];
    } else {
        doctorDictionary = [NSDictionary dictionaryWithContentsOfURL:self.doctorDictionaryURL];
    }
    return doctorDictionary;
}

- (void)setDoctorSignature:(UIImage *)image {
    NSString *filePath = [[[self documentDirectory] URLByAppendingPathComponent:DOC_SIGNATURE_FILENAME] path];
    [UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];
}

- (UIImage*)doctorSignature {
    NSString *filePath = [[[self documentDirectory] URLByAppendingPathComponent:DOC_SIGNATURE_FILENAME] path];
    return [[UIImage alloc] initWithContentsOfFile:filePath];
}

# pragma mark - Prescription

- (NSURL *)amkBaseDirectory {
    if (self.currentSource == MLPersistenceSourceICloud) {
        NSURL *url = [[self documentDirectory] URLByAppendingPathComponent:@"amk"];
        [[NSFileManager defaultManager] createDirectoryAtURL:url
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:nil];
        return url;
    }
    return [NSURL fileURLWithPath:[self localAmkBaseDirectory]];
}

- (NSURL *)amkDirectory {
    // If the current patient is defined in the defaults,
    // return his/her subdirectory
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *patientId = [defaults stringForKey:@"currentPatient"];
    if (patientId)
        return [self amkDirectoryForPatient:patientId];
    return [self amkBaseDirectory];
}

- (NSURL *)amkDirectoryForPatient:(NSString*)uid {
    NSURL *amk = [self amkBaseDirectory];
    NSURL *patientAmk = [amk URLByAppendingPathComponent:uid];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[patientAmk path]])
    {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:[patientAmk path]
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) {
            NSLog(@"error creating directory: %@", error.localizedDescription);
            patientAmk = nil;
        } else {
            NSLog(@"Created patient directory: %@", patientAmk);
        }
    }
    
    return patientAmk;
}


// Create the directory if it doesn't exist
- (NSString *) localAmkBaseDirectory
{
    NSString *amk = [[MLUtility documentsDirectory] stringByAppendingPathComponent:@"amk"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:amk])
    {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:amk
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) {
            NSLog(@"error creating directory: %@", error.localizedDescription);
            amk = nil;
        }
    }
    return amk;
}

- (NSURL *)savePrescription:(Prescription *)prescription {
    NSURL *amkDir;
    NSString *uid = [prescription.patient uniqueId];
    if (uid)
        amkDir = [self amkDirectoryForPatient:uid];
    else
        amkDir = [self amkDirectory];
    
    NSError *error;

    prescription.placeDate = [NSString stringWithFormat:@"%@, %@",
                              prescription.doctor.city,
                              [MLUtility prettyTime]];

    NSMutableDictionary *prescriptionDict = [NSMutableDictionary new];
    [prescriptionDict setObject:prescription.hash forKey:KEY_AMK_HASH];
    [prescriptionDict setObject:prescription.placeDate forKey:KEY_AMK_PLACE_DATE];
    [prescriptionDict setObject:[prescription makePatientDictionary] forKey:KEY_AMK_PATIENT];
    [prescriptionDict setObject:[prescription makeOperatorDictionary] forKey:KEY_AMK_OPERATOR];
    [prescriptionDict setObject:[prescription makeMedicationsArray] forKey:KEY_AMK_MEDICATIONS];
    NSData *jsonObject = [NSJSONSerialization dataWithJSONObject:prescriptionDict
                                                         options:NSJSONWritingPrettyPrinted
                                                           error:&error];
    
    NSString *jsonStr = [[NSString alloc] initWithData:jsonObject encoding:NSUTF8StringEncoding];
    NSString *base64Str = [MLUtility encodeStringToBase64:jsonStr];

    // Prescription file name like AmiKo
    NSString *currentTime = [[MLUtility currentTime] stringByReplacingOccurrencesOfString:@":" withString:@""];
    currentTime = [currentTime stringByReplacingOccurrencesOfString:@"." withString:@""];
    NSString *amkFile = [NSString stringWithFormat:@"RZ_%@.amk", currentTime];
    NSURL *amkFileURL = [amkDir URLByAppendingPathComponent:amkFile];
    
    BOOL saved = [base64Str writeToURL:amkFileURL
                            atomically:YES
                              encoding:NSUTF8StringEncoding
                                 error:&error];
    if (saved) {
        return amkFileURL;
    }
    return nil;
}

# pragma mark - Patient

- (NSString *)addPatient:(Patient *)patient {
    NSString *uuidStr = [patient generateUniqueID];
    patient.uniqueId = uuidStr;

    NSManagedObjectContext *context = [[self coreDataContainer] viewContext];
    PatientModel *pm = [NSEntityDescription insertNewObjectForEntityForName:@"Patient"
                                                     inManagedObjectContext:context];

    [pm importFromPatient:patient timestamp: [NSDate new]];
    
    NSError *error = nil;
    [context save:&error];
    if (error != nil) {
        NSLog(@"Cannot create patient %@", error);
    }
    return uuidStr;
}

- (NSString *)upsertPatient:(Patient *)patient {
    NSError *error = nil;
    if (patient.uniqueId.length) {
        PatientModel *p = [self getPatientModelWithUniqueID:patient.uniqueId];
        p.weightKg = patient.weightKg;
        p.heightCm = patient.heightCm;
        p.zipCode = patient.zipCode;
        p.city = patient.city;
        p.country = patient.country;
        p.postalAddress = patient.postalAddress;
        p.phoneNumber = patient.phoneNumber;
        p.emailAddress = patient.emailAddress;
        p.gender = patient.gender;
        [[self.coreDataContainer viewContext] save:&error];
        if (error != nil) {
            NSLog(@"Cannot update patient %@", error);
        }
        return patient.uniqueId;
    } else {
        return [self addPatient:patient];
    }
}

- (BOOL)deletePatient:(Patient *)patient {
    if (!patient.uniqueId.length) {
        return NO;
    }
    PatientModel *pm = [self getPatientModelWithUniqueID:patient.uniqueId];
    if (!pm) {
        return NO;
    }
    NSManagedObjectContext *context = [self.coreDataContainer viewContext];
    [context deleteObject:pm];
    return YES;
}

- (NSArray<Patient *> *)getAllPatients {
    NSError *error = nil;
    NSManagedObjectContext *context = [[self coreDataContainer] viewContext];
    
    NSFetchRequest *req = [PatientModel fetchRequest];
    req.sortDescriptors = @[
        [NSSortDescriptor sortDescriptorWithKey:@"familyName" ascending:YES]
    ];
    
    NSArray<PatientModel*> *pm = [context executeFetchRequest:req error:&error];
    if (error != nil) {
        NSLog(@"Cannot get all patients %@", error);
    }
    return [pm valueForKey:@"toPatient"];
}

- (NSFetchedResultsController *)resultsControllerForAllPatients {
    NSManagedObjectContext *context = [self.coreDataContainer viewContext];
    NSFetchRequest *fetchRequest = [PatientModel fetchRequest];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"familyName" ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];

    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc]
            initWithFetchRequest:fetchRequest
            managedObjectContext:context
            sectionNameKeyPath:nil
            cacheName:nil];
    return controller;
}

- (PatientModel *)getPatientModelWithUniqueID:(NSString *)uniqueID {
    NSError *error = nil;
    NSManagedObjectContext *context = [[self coreDataContainer] viewContext];
    NSFetchRequest *req = [PatientModel fetchRequest];
    req.predicate = [NSPredicate predicateWithFormat:@"uniqueId == %@", uniqueID];
    req.fetchLimit = 1;
    NSArray<PatientModel *> *patientModels = [context executeFetchRequest:req error:&error];
    return [patientModels firstObject];
}

- (Patient *) getPatientWithUniqueID:(NSString *)uniqueID {
    return [[self getPatientModelWithUniqueID:uniqueID] toPatient];
}

# pragma mark - Favourites

- (NSURL *)favouritesFile {
    return [[self documentDirectory] URLByAppendingPathComponent:@"favourites"];
}

- (void)migrateFromOldFile {
    NSString *oldFile = [@"~/Library/Preferences/data" stringByExpandingTildeInPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:oldFile]) {
        [[NSFileManager defaultManager] moveItemAtPath:oldFile
                                                toPath:[[self favouritesFile] path]
                                                 error:nil];
    }
}

# pragma mark - Migration

- (void)migratePatientSqliteToCoreData {
    NSManagedObjectContext *context = [self.coreDataContainer newBackgroundContext];
    [context performBlock:^{
        LegacyPatientDBAdapter *adapter = [[LegacyPatientDBAdapter alloc] init];
        if (![adapter openDatabase]) {
            return;
        }
        NSArray<Patient *> *patients = [adapter getAllPatients];
        NSMutableArray *dicts = [NSMutableArray arrayWithCapacity:patients.count];
        for (Patient *patient in patients) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            if (patient.birthDate != nil) {
                dict[@"birthDate"] = patient.birthDate;
            }
            if (patient.city != nil) {
                dict[@"city"] = patient.city;
            }
            if (patient.country != nil) {
                dict[@"country"] = patient.country;
            }
            if (patient.emailAddress != nil) {
                dict[@"emailAddress"] = patient.emailAddress;
            }
            if (patient.familyName != nil) {
                dict[@"familyName"] = patient.familyName;
            }
            if (patient.gender != nil) {
                dict[@"gender"] = patient.gender;
            }
            if (patient.givenName != nil) {
                dict[@"givenName"] = patient.givenName;
            }
            if (patient.heightCm != 0) {
                dict[@"heightCm"] = @(patient.heightCm);
            }
            if (patient.phoneNumber != nil) {
                dict[@"phoneNumber"] = patient.phoneNumber;
            }
            if (patient.postalAddress != nil) {
                dict[@"postalAddress"] = patient.postalAddress;
            }
            if (patient.uniqueId != nil) {
                dict[@"uniqueId"] = patient.uniqueId;
            }
            if (patient.weightKg != 0) {
                dict[@"weightKg"] = @(patient.weightKg);
            }
            if (patient.zipCode != nil) {
                dict[@"zipCode"] = patient.zipCode;
            }
            dict[@"timestamp"] = [NSDate date];
            [dicts addObject:dict];
        }
        NSBatchInsertRequest *req = [[NSBatchInsertRequest alloc] initWithEntity:[PatientModel entity]
                                                                         objects:dicts];
        NSError *error = nil;
        [context executeRequest:req error:&error];
        if (error != nil) {
            NSLog(@"Cannot migrate %@", error);
            return;
        }
        NSString *dbPath = [adapter dbPath];
        [[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil];
    }];
}

@end
