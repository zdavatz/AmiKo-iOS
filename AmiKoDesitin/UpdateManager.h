//
//  UpdateManager.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 23 Oct 2019
//  Copyright © 2019 Ywesee GmbH. All rights reserved.
//

#ifndef UpdateManager_h
#define UpdateManager_h

#import "MLProgressViewController.h"

#define NOTIFY_DB_UPDATE_DOWNLOAD_SUCCESS        @"MLDidFinishLoading"
//#define NOTIFY_DB_UPDATE_DOWNLOAD_FAILURE        @"MLStatusCode404"

@interface UpdateManager : NSObject
{
    NSMutableArray *connectionArray;
    MLProgressViewController *myProgressView;
}

@property (nonatomic, assign) BOOL totalDownloadSuccess;
@property (nonatomic, assign) long totalExpectedBytes;
@property (nonatomic, assign) long totalDownloadedBytes;

+ (UpdateManager *)sharedInstance;

- (void) addLanguageFile:(NSString *)filenamePrefix
               extension:(NSString *)ext;

- (NSUInteger)numConnections;
- (BOOL) allUpdateSucceeded;

- (void) resetProgressBar;
- (void) startProgressBar;
- (void) terminateProgressBar;
- (void) updateProgress;
- (void) updateProgressMessage:(NSString *)message;

- (BOOL) updateSucceeded;

@end

#endif /* UpdateManager_h */
