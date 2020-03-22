/*
 
 Copyright (c) 2014 Max Lungarella <cybrmx@gmail.com>
 
 Created on 14/02/2014.
 
 This file is part of AmiKoDesitin.
 
 AmiKoDesitin is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 
 ------------------------------------------------------------------------ */

#import "MLCustomURLConnection.h"
#import "MLProgressViewController.h"
#import "MLConstants.h"
#import "UpdateManager.h"

@implementation MLCustomURLConnection
{
    NSURLConnection *myConnection;
    NSFileHandle *mFile;        // writes directly to disk
    // NSMutableData *mData;    // caches in memory
    NSUInteger bytesReceived;
    long mStatusCode;
}

#pragma mark -

- (void) downloadFileWithName:(NSString *)fileName
{
    self.mFileName = fileName;

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async( queue, ^(void){
        NSURL *url = [NSURL URLWithString:[PILLBOX_ODDB_ORG stringByAppendingString:fileName]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url
                                                 cachePolicy:NSURLRequestUseProtocolCachePolicy
                                             timeoutInterval:30.0];
        
        self->myConnection = [[NSURLConnection alloc] initWithRequest:request
                                                       delegate:self
                                               startImmediately:NO];
        [self->myConnection setDelegateQueue:[NSOperationQueue mainQueue]];
        [self->myConnection start];
    });
    
    // Get handle to file where the downloaded file is saved
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    mFile = [NSFileHandle fileHandleForUpdatingAtPath:filePath];

}

#pragma mark - NSURLConnectionDataDelegate

// delegate calls just so let us know when it's working or when it isn't
- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"%s error: %@, %@", __FUNCTION__, error, [error description]);
#endif
    // Release stuff
    myConnection = nil;
    if (mFile)
        [mFile closeFile];
}

// Here we are notified of the number of bytes to be downloaded for one file
- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    UpdateManager *um = [UpdateManager sharedInstance];

    // Get status code
    mStatusCode = [((NSHTTPURLResponse *)response) statusCode];
    if (mStatusCode == 404) {
#ifdef DEBUG
        NSLog(@"%s %d, %@ ERROR: status code: %ld", __FUNCTION__, __LINE__, self.mFileName, mStatusCode);
#endif
        um.totalDownloadSuccess = false;
        [myConnection cancel];
        return;
    }
    
    um.totalExpectedBytes += [response expectedContentLength];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    UpdateManager *um = [UpdateManager sharedInstance];

    if (mFile)
        [mFile writeData:data];

    um.totalDownloadedBytes += [data length];
    [um updateProgress];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    // Release stuff
    myConnection = nil;
    if (mFile)
        [mFile closeFile];

    if (mStatusCode == 404) {   // Notify status code 404 (file not found)
        [[UpdateManager sharedInstance] setTotalDownloadSuccess:false];
        //[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_DB_UPDATE_DOWNLOAD_FAILURE object:self];
#ifdef DEBUG
        NSLog(@"%s %d ERROR mFileName: %@", __FUNCTION__, __LINE__, self.mFileName);
#endif
        [connection cancel];
        return;
    }

    if ([[self.mFileName pathExtension] isEqualToString:@"zip"])
        [self unzipDatabase];
    else
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_DB_UPDATE_DOWNLOAD_SUCCESS object:self];
}

- (void) unzipDatabase
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *zipFilePath = [documentsDirectory stringByAppendingPathComponent:self.mFileName];
    NSString *output = [documentsDirectory stringByAppendingPathComponent:@"."];

    BOOL unzipped = [SSZipArchive unzipFileAtPath:zipFilePath toDestination:output delegate:self];
    // Unzip data success, post notification
    if (unzipped)
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_DB_UPDATE_DOWNLOAD_SUCCESS object:self];
}

#pragma mark - SSZipArchiveDelegate

- (void) zipArchiveWillUnzipFileAtIndex:(NSInteger)fileIndex
                             totalFiles:(NSInteger)totalFiles
                            archivePath:(NSString *)archivePath
                               fileInfo:(unz_file_info)fileInfo
{
    NSLog(@"Unzipping: %ld of %ld", (long)fileIndex+1, (long)totalFiles);
}

@end
