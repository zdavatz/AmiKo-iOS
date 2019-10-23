//
//  UpdateManager.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 23 Oct 2019
//  Copyright © 2019 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UpdateManager.h"
#import "MLCustomURLConnection.h"
#import "MLConstants.h"

@implementation UpdateManager

+ (UpdateManager *)sharedInstance
{
    __strong static id sharedObject = nil;
    
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedObject = [self new];
    });
    
    return sharedObject;
}

- (void) addLanguageFile:(NSString *)filenamePrefix
               extension:(NSString *)ext
{
    if (!connectionArray)
        connectionArray = [NSMutableArray array];
    
    MLCustomURLConnection *conn = [MLCustomURLConnection new];
    
    NSString *lang = [MLConstants databaseLanguage];
    NSString *filename = [NSString stringWithFormat:@"%@_%@.%@", filenamePrefix, lang, ext];

    [conn downloadFileWithName:filename];
    [connectionArray addObject:conn];
}

- (NSUInteger)numConnections
{
    return [connectionArray count];
}

- (BOOL) allUpdateSucceeded
{
    return _totalDownloadSuccess;
}

- (void) resetProgressBar
{
    _totalDownloadedBytes = _totalExpectedBytes = 0;
    _totalDownloadSuccess = true;
    [connectionArray removeAllObjects];
    if (!myProgressView)
        myProgressView = [MLProgressViewController new];
}

- (void) startProgressBar
{
    [myProgressView start];
}

- (void) terminateProgressBar
{
    [myProgressView remove];
    myProgressView = nil;
}

- (void) updateProgressMessage:(NSString *)msg
{
    [myProgressView setMessage:msg];
}

- (void) updateProgress
{
    [myProgressView updateWith: _totalDownloadedBytes
                       andWith: _totalExpectedBytes];
}

- (BOOL) updateSucceeded
{
    return _totalDownloadSuccess;
}

@end
