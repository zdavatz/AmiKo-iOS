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

#define KEY_PERSISTENCE_SOURCE @"KEY_PERSISTENCE_SOURCE"

@implementation MLPersistenceManager

+ (instancetype)shared {
    __strong static id sharedObject = nil;
    
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedObject = [[MLPersistenceManager alloc] init];
    });
    
    return sharedObject;
}

- (instancetype)init {
    if (self = [super init]) {
        // TODO: take care of updated icloud status when app is active
        // https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Chapters/iCloudFundametals.html#//apple_ref/doc/uid/TP40012094-CH6-SW6
        [self migrateToICloud];
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
        case MLPersistenceSourceICloud:
            [self migrateToICloud];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:source forKey:KEY_PERSISTENCE_SOURCE];
    [defaults synchronize];
}

- (MLPersistenceSource)currentSource {
    return [[NSUserDefaults standardUserDefaults] integerForKey:KEY_PERSISTENCE_SOURCE];
}

- (void)migrateToICloud {
    if (self.currentSource == MLPersistenceSourceICloud) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [self doctorDictionary]; // Migrate to file based doctor storage
        NSError *error = nil;
        NSFileManager *manager = [NSFileManager defaultManager];
        NSURL *documentDir = [self iCloudDocumentDirectory];
        
        NSArray<NSURL *> *localFiles = [manager contentsOfDirectoryAtURL:[NSURL fileURLWithPath:[MLUtility documentsDirectory]]
                                              includingPropertiesForKeys:nil
                                                                 options:0
                                                                   error:&error];
        if (error != nil) {
            NSLog(@"%@", error);
            return;
        }
        
        NSArray<NSURL *> *contents = [manager contentsOfDirectoryAtURL:documentDir
                                            includingPropertiesForKeys:nil
                                                               options:0
                                                                 error:&error];
        NSLog(@"contents: %@", contents);
        if (error != nil) {
            NSLog(@"%@", error);
            return;
        }
        // Merging files and folder instead of overwriting
        for (NSURL *localFile in localFiles) {
//            [[NSFileManager defaultManager] moveItemAtURL:localFile
//                                                    toURL:[documentDir URLByAppendingPathComponent:[localFile lastPathComponent]]
//                                                    error:&error];
            [[NSFileManager defaultManager] copyItemAtURL:localFile
                                                    toURL:[documentDir URLByAppendingPathComponent:[localFile lastPathComponent]]
                                                    error:&error];
            if (error != nil) {
                NSLog(@"%@", error);
            }
        }
    });
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

# pragma -- Doctor

- (NSURL *)doctorDictionaryURL {
    return [[self documentDirectory] URLByAppendingPathComponent:@"doctor.plist"];
}

- (void)saveDoctorDictionary:(NSDictionary *)dict {
    [dict writeToURL:self.doctorDictionaryURL
          atomically:YES];
}

- (NSDictionary *)doctorDictionary {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *doctorDictionary = [defaults dictionaryForKey:@"currentDoctor"];
    if (doctorDictionary != nil) {
        // Migrate to use document file
        [self saveDoctorDictionary:doctorDictionary];
        [defaults removeObjectForKey:@"currentDoctor"];
        [defaults synchronize];
    } else {
        doctorDictionary = [NSDictionary dictionaryWithContentsOfURL:self.doctorDictionaryURL];
    }
    return doctorDictionary;
}

@end
