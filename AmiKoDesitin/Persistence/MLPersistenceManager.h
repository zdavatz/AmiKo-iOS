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

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MLPersistenceSource) {
    MLPersistenceSourceLocal = 0,
    MLPersistenceSourceICloud = 1,
};

@interface MLPersistenceManager : NSObject

@property (nonatomic) MLPersistenceSource currentSource;

+ (instancetype) shared;
+ (BOOL)supportICloud;
- (NSURL *)iCloudDocumentDirectory;
- (NSManagedObjectContext *)managedViewContext;

# pragma mark - Doctor

- (NSURL *)doctorDictionaryURL;
- (void)setDoctorDictionary:(NSDictionary *)dict;
- (NSDictionary *)doctorDictionary;
- (void)setDoctorSignature:(UIImage *)image;
- (UIImage*)doctorSignature;

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

@end

NS_ASSUME_NONNULL_END
