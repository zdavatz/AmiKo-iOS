//
//  MLPersistenceManager.h
//  AmiKoDesitin
//
//  Created by b123400 on 2020/03/14.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>
#import "Prescription.h"
#import "MLHINTokens.h"

NS_ASSUME_NONNULL_BEGIN

#define PERSISTENCE_SOURCE_CHANGED_NOTIFICATION @"PERSISTENCE_SOURCE_CHANGED_NOTIFICATION"

typedef NS_ENUM(NSInteger, MLPersistenceSource) {
    MLPersistenceSourceLocal = 0,
    MLPersistenceSourceICloud = 1,
};

typedef NS_ENUM(NSInteger, MLPersistenceFileState) {
    MLPersistenceFileStateNotFound = 0,
    MLPersistenceFileStateAvailable = 1,
    MLPersistenceFileStateDownloading = 2,
    MLPersistenceFileStateErrored = 3,
};

@interface MLPersistenceManager : NSObject

@property (nonatomic, readonly) MLPersistenceSource currentSource;

+ (instancetype) shared;
+ (BOOL)supportICloud;
- (NSURL *)iCloudDocumentDirectory;
- (NSManagedObjectContext *)managedViewContext;

- (void)setCurrentSourceToICloud;
- (void)setCurrentSourceToLocalWithDeleteICloud:(BOOL)deleteFilesOnICloud;

# pragma mark - Doctor

- (MLPersistenceFileState)doctorFileState;
- (NSURL *)doctorDictionaryURL;
- (NSURL *)doctorSignatureURL;
- (void)setDoctorDictionary:(NSDictionary *)dict;
- (NSDictionary *)doctorDictionary;
- (void)setDoctorSignature:(UIImage *)image;
- (UIImage*)doctorSignature;

- (void)setHINSDSTokens:(MLHINTokens * _Nullable)tokens;
- (MLHINTokens * _Nullable)HINSDSTokens;

- (void)setHINADSwissTokens:(MLHINTokens * _Nullable)tokens;
- (MLHINTokens * _Nullable)HINADSwissTokens;
- (void)setHINADSwissAuthHandle:(NSString * _Nullable)authHandle;
- (NSString * _Nullable)HINADSwissAuthHandle;

# pragma mark - Prescription

- (NSURL *)amkDirectory;
- (NSURL *)amkDirectoryForPatient:(NSString*)uid;
- (NSURL *)savePrescription:(Prescription *)prescription;

#pragma mark - Patient

- (NSString *)addPatient:(Patient *)patient;
- (NSString *)upsertPatient:(Patient *)patient;
- (BOOL)deletePatient:(Patient *)patient;

- (NSArray<Patient *> *) getAllPatients;
- (NSFetchedResultsController *)resultsControllerForAllPatients;
- (Patient *) getPatientWithUniqueID:(NSString *)uniqueID;

#pragma mark - Favourites

- (NSURL *)favouritesFile;

@end

NS_ASSUME_NONNULL_END
