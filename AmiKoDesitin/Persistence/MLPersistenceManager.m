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

#define KEY_PERSISTENCE_SOURCE @"KEY_PERSISTENCE_SOURCE"

@interface MLPersistenceManager ()

- (void)moveFile:(NSURL *)url toURL:(NSURL *)targetUrl overwriteIfExisting:(BOOL)overwrite;
- (void)mergeFolderRecursively:(NSURL *)fromURL to:(NSURL *)toURL;

- (NSURL *)amkBaseDirectory;

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
        // TODO: take care of updated icloud status when app is active
        // https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Chapters/iCloudFundametals.html#//apple_ref/doc/uid/TP40012094-CH6-SW6
        [self setCurrentSource:MLPersistenceSourceLocal];
        [self setCurrentSource:MLPersistenceSourceICloud];
    }
    return self;
}

+ (BOOL)supportICloud {
    return [[NSFileManager defaultManager] ubiquityIdentityToken] != nil;
}

- (void)setCurrentSource: (MLPersistenceSource) source {
    if (source == self.currentSource) {
        return;
    }
    if (source == MLPersistenceSourceICloud && ![MLPersistenceManager supportICloud]) {
        return;
    }
    switch (source) {
        case MLPersistenceSourceLocal:
            [self migrateToLocal];
            break;
        case MLPersistenceSourceICloud:
            [self migrateToICloud];
            break;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:source forKey:KEY_PERSISTENCE_SOURCE];
    [defaults synchronize];
}

- (MLPersistenceSource)currentSource {
    return [[NSUserDefaults standardUserDefaults] integerForKey:KEY_PERSISTENCE_SOURCE];
}

- (void)migrateToLocal {
    if (self.currentSource == MLPersistenceSourceLocal) {
        return;
    }
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

# pragma mark - Migration Local -> iCloud

- (void)migrateToICloud {
    if (self.currentSource == MLPersistenceSourceICloud) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [self doctorDictionary]; // Migrate to file based doctor storage
        NSURL *localDocument = [NSURL fileURLWithPath:[MLUtility documentsDirectory]];
        NSURL *remoteDocument = [self iCloudDocumentDirectory];

        [self moveFile:[localDocument URLByAppendingPathComponent:@"doctor.plist"]
                 toURL:[remoteDocument URLByAppendingPathComponent:@"doctor.plist"]
   overwriteIfExisting:NO];
        [self moveFile:[localDocument URLByAppendingPathComponent:DOC_SIGNATURE_FILENAME]
                      toURL:[remoteDocument URLByAppendingPathComponent:DOC_SIGNATURE_FILENAME]
        overwriteIfExisting:NO];
        [self mergeFolderRecursively:[localDocument URLByAppendingPathComponent:@"amk" isDirectory:YES]
                                  to:[remoteDocument URLByAppendingPathComponent:@"amk" isDirectory:YES]];
    });
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

# pragma mark - Patient

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
# pragma mark - Utility

- (void)moveFile:(NSURL *)url toURL:(NSURL *)targetUrl overwriteIfExisting:(BOOL)overwrite {
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:[url path]]) {
        return;
    }
    BOOL exist = [manager fileExistsAtPath:[targetUrl path]];
    if (exist && overwrite) {
        [manager replaceItemAtURL:targetUrl
                    withItemAtURL:url
                   backupItemName:[NSString stringWithFormat:@"%@.bak", [url lastPathComponent]]
                          options:NSFileManagerItemReplacementUsingNewMetadataOnly
                 resultingItemURL:nil
                            error:nil];
        [manager removeItemAtURL:url error:nil];
    } else if (!exist) {
        [manager moveItemAtURL:url
                         toURL:targetUrl
                         error:nil];
    }

}

- (void)mergeFolderRecursively:(NSURL *)fromURL to:(NSURL *)toURL {
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    BOOL sourceExist = [manager fileExistsAtPath:[fromURL path] isDirectory:&isDirectory];
    if (!sourceExist || !isDirectory) {
        return;
    }
    isDirectory = NO;
    BOOL destExist = [manager fileExistsAtPath:[toURL path] isDirectory:&isDirectory];
    if (destExist && !isDirectory) {
        // Remote is a file but we need a directory, abort
        return;
    }
    if (!destExist) {
        [manager createDirectoryAtURL:toURL
          withIntermediateDirectories:YES
                           attributes:nil
                                error:nil];
    }
    NSArray<NSURL *> *sourceFiles = [manager contentsOfDirectoryAtURL:fromURL
                                           includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                              options:0
                                                                error:nil];
    for (NSURL *sourceFile in sourceFiles) {
        NSURL *destFile = [toURL URLByAppendingPathComponent:[sourceFile lastPathComponent]];
        NSNumber *sourceIsDir = @0;
        [sourceFile getResourceValue:&sourceIsDir
                              forKey:NSURLIsDirectoryKey
                               error:nil];
        if ([sourceIsDir boolValue]) {
            [self mergeFolderRecursively:sourceFile
                                      to:destFile];
        } else {
            [self moveFile:sourceFile toURL:destFile overwriteIfExisting:NO];
        }
    }
}

@end