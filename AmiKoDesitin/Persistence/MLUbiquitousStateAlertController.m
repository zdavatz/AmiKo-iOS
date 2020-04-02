//
//  MLUbiquitousStateAlertController.m
//  AmikoDesitin
//
//  Created by b123400 on 2020/04/02.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//

#import "MLUbiquitousStateAlertController.h"

@interface MLUbiquitousStateAlertController ()

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSMetadataQuery *query;
@property (nonatomic, strong) UIAlertController *alert;

@end

@implementation MLUbiquitousStateAlertController

- (instancetype)initWithUbiquitousItem:(NSURL *)url {
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager isUbiquitousItemAtURL:url]) {
        return nil;
    }
    NSString *downloadStatus = nil;
    [url getResourceValue:&downloadStatus forKey:NSURLUbiquitousItemDownloadingStatusKey error:nil];
    if ([downloadStatus isEqualToString:NSURLUbiquitousItemDownloadingStatusCurrent] ||
        [downloadStatus isEqualToString:NSURLUbiquitousItemDownloadingStatusDownloaded]) {
        return nil;
    }
        
    if (self = [super init]) {
        self.url = url;
        [manager startDownloadingUbiquitousItemAtURL:url error:nil];
        self.query = [[NSMetadataQuery alloc] init];
        self.query.searchScopes = @[NSMetadataQueryUbiquitousDocumentsScope];
        self.query.predicate = [NSPredicate predicateWithFormat:@"%K == %@", NSMetadataItemURLKey, url];;
        self.query.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"lastPathComponent" ascending:NO]];
        [self.query startQuery];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(reloadState) name:NSMetadataQueryDidUpdateNotification object:self.query];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)presentAt: (UIViewController*)presenter {
    if (!self.alert) {
        self.alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Syncing...", nil)
                                                         message:NSLocalizedString(@"Downloading from iCloud", nil)
                                                  preferredStyle:UIAlertControllerStyleAlert];
        [presenter presentViewController:self.alert
                                animated:YES
                              completion:nil];
    }
}

- (void)reloadState {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNumber *isRequested = @0;
        [self.url getResourceValue:&isRequested forKey:NSURLUbiquitousItemDownloadRequestedKey error:nil];
        
        NSNumber *error = nil;
        [self.url getResourceValue:&error forKey:NSURLUbiquitousItemDownloadingErrorKey error:nil];
        
        NSString *downloadStatus = nil;
        [self.url getResourceValue:&downloadStatus forKey:NSURLUbiquitousItemDownloadingStatusKey error:nil];
        
        if ([downloadStatus isEqualToString:NSURLUbiquitousItemDownloadingStatusCurrent] ||
            [downloadStatus isEqualToString:NSURLUbiquitousItemDownloadingStatusDownloaded]
            ){
            [self.alert setMessage:NSLocalizedString(@"Downloaded from iCloud", nil)];
            [self.alert dismissViewControllerAnimated:YES completion:nil];
            if (self.onDone != nil) {
                self.onDone();
            }
        }
        if ([isRequested boolValue]) {
            [self.alert setMessage:NSLocalizedString(@"Started downloading from iCloud", nil)];
        }
        if (error != nil) {
            [self.alert dismissViewControllerAnimated:YES completion:nil];
            if (self.onError != nil) {
                self.onError();
            }
        }
    });
}

@end
