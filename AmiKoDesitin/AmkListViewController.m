//
//  AmkListViewController.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 30 Jan 2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "AmkListViewController.h"
#import "SWRevealViewController.h"
#import "MLUtility.h"
#import "MLPersistenceManager.h"
#import "MLUbiquitousStateAlertController.h"

static const float kAmkLabelFontSize = 12.0;

@interface AmkListViewController ()

- (void) refreshFileList;
@property (nonatomic, strong) NSMetadataQuery *query;
@property (nonatomic, strong) MLUbiquitousStateAlertController *ubiquitousController;

@end

@implementation AmkListViewController
{
    NSMutableArray<NSURL *> *amkFiles;
}

@synthesize myTableView;

- (void)viewDidLoad
{
    [super viewDidLoad];
   
    self.edgesForExtendedLayout = UIRectEdgeNone;
    myTableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
}

- (void)viewDidAppear:(BOOL)animated
{
    [self refreshList];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

#pragma mark -

- (void) refreshList {
    [self refreshFileList];
    NSURL *amkDir = [[MLPersistenceManager shared] amkDirectory];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K BEGINSWITH %@ AND %K ENDSWITH '.amk'", NSMetadataItemPathKey, amkDir.path, NSMetadataItemFSNameKey];
    if (!self.query) {
        self.query = [[NSMetadataQuery alloc] init];
        self.query.searchScopes = @[NSMetadataQueryUbiquitousDocumentsScope];
        self.query.predicate = predicate;
        self.query.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"lastPathComponent" ascending:NO]];
        [self.query startQuery];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(refreshFileList) name:NSMetadataQueryDidUpdateNotification object:self.query];
    } else {
        self.query.predicate = predicate;
    }
}

- (void) refreshFileList {
    NSURL *amkDir = [[MLPersistenceManager shared] amkDirectory];
    NSError *error;
    NSArray<NSURL *> *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:amkDir
                                                      includingPropertiesForKeys:nil
                                                                         options:0
                                                                           error:&error];
    NSMutableArray<NSURL *> *amkFilesArray = [NSMutableArray array];
    for (NSURL *file in dirFiles) {
        if ([[NSFileManager defaultManager] isUbiquitousItemAtURL:file] || [[file pathExtension] isEqualToString:@"amk"]) {
            [amkFilesArray addObject:file];
        }
    }
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"lastPathComponent" ascending:NO];
    [amkFilesArray sortUsingDescriptors:@[sd]];
    amkFiles = amkFilesArray;
    [myTableView reloadData];
    if (error)
        NSLog(@"%@", error.localizedDescription);
}

- (void) removeFromListByFilename:(NSString *)filename
{
    for (int i=0; i<[amkFiles count]; i++) {
        if ([[amkFiles[i] lastPathComponent] isEqualToString:filename]) {
            [amkFiles removeObjectAtIndex:i];
            [myTableView reloadData];
            return;
        }
    }
}

// Also delete the file
- (void) removeItem:(NSUInteger)rowIndex
{
    NSURL *destination = amkFiles[rowIndex];
    if (![[NSFileManager defaultManager] isDeletableFileAtPath:destination.path]) {
        NSLog(@"Error removing file at path: %@", amkFiles[rowIndex]);
        return;
    }

    // First remove the actual file
    NSError *error;
    BOOL success = [[NSFileManager defaultManager] removeItemAtURL:destination error:&error];
    if (!success)
        NSLog(@"Error removing file at path: %@", error.localizedDescription);

    // If it's the one currently displayed,
    // remove it from the defaults and refresh the prescription view
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *fileName = [defaults stringForKey:@"lastUsedPrescription"];
    NSLog(@"lastUsedPrescription: %@, amkFiles[rowIndex] %@", fileName, amkFiles[rowIndex]);
    if ([fileName isEqualToString:amkFiles[rowIndex].lastPathComponent]) {
        [defaults removeObjectForKey:@"lastUsedPrescription"];
        [defaults synchronize];

        // Show empty prescription
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AmkFilenameDeletedNotification"
                                                            object:nil];
    }

    // Finally remove the entry from the list
    [amkFiles removeObjectAtIndex:rowIndex];
    [myTableView reloadData];
}

#pragma mark - UIGestureRecognizerDelegate

- (IBAction) handleLongPress:(UILongPressGestureRecognizer *)gesture
{
    CGPoint p = [gesture locationInView:self.myTableView];
    NSIndexPath *indexPath = [self.myTableView indexPathForRowAtPoint:p];
    
    if (indexPath == nil) {
        NSLog(@"long press on table view but not on a row");
        return;
    }

    if (gesture.state != UIGestureRecognizerStateBegan) {
        return;
    }

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSURL *url = amkFiles[indexPath.row];
    NSString *filename = nil;
    if ([url getResourceValue:&filename forKey:NSURLLocalizedNameKey error:nil]) {
        filename = [filename stringByDeletingPathExtension];
    } else {
        filename = url.lastPathComponent;
    }
    NSString *actionTitle = [NSString stringWithFormat:NSLocalizedString(@"Confirm delete %@",nil), filename];
    
    UIAlertAction *actionDelete = [UIAlertAction actionWithTitle:actionTitle
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action) {
                                                         [alertController dismissViewControllerAnimated:YES completion:nil];

                                                         [self removeItem:indexPath.row];
                                                         }];
    [alertController addAction:actionDelete];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        // iPad: Cancel buttons are removed from popovers automatically,
        // because tapping outside the popover represents "cancel", in a popover context
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction *action) {
                                                                 [alertController dismissViewControllerAnimated:YES completion:nil];
                                                             }];
        [alertController addAction:actionCancel];
    }

    [alertController setModalPresentationStyle:UIModalPresentationPopover];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UITableViewCell *cell = [myTableView cellForRowAtIndexPath:indexPath];
        alertController.popoverPresentationController.sourceView = cell.contentView;
    }

    [self presentViewController:alertController animated:YES completion:nil]; // It returns immediately
}

#pragma mark - UITableViewDataSource

- (NSInteger) tableView: (UITableView *)tableView
  numberOfRowsInSection: (NSInteger)section
{
    return [amkFiles count];
}

- (UITableViewCell *) tableView: (UITableView *)tableView
          cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    static NSString *tableIdentifier = @"amkListTableItem";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:tableIdentifier];
        
        /** Use subview */
        UILabel *subLabel = nil;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            subLabel = [[UILabel alloc] initWithFrame:CGRectMake(20,0,230,36)];
            [subLabel setFont:[UIFont systemFontOfSize:kAmkLabelFontSize+2]];
        }
        else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            subLabel = [[UILabel alloc] initWithFrame:CGRectMake(20,0,230,28)];
            [subLabel setFont:[UIFont systemFontOfSize:kAmkLabelFontSize]];
        }
        subLabel.textAlignment = NSTextAlignmentLeft;

        subLabel.tag = 123; // Constant which uniquely defines the label
        [cell.contentView addSubview:subLabel];
    }
    
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:123];
    NSURL *url = amkFiles[indexPath.row];
    label.text = [url.lastPathComponent stringByDeletingPathExtension];
    NSString *displayName = nil;
    if ([url getResourceValue:&displayName forKey:NSURLLocalizedNameKey error:nil]) {
        label.text = [displayName stringByDeletingPathExtension];
    }

    NSNumber *isDownloading = nil;
    NSNumber *isDownloadRequested = nil;
    NSString *downloadStatus = nil;
    NSError *error = nil;
    if ([url getResourceValue:&isDownloading forKey:NSURLUbiquitousItemIsDownloadingKey error:&error] &&
        error == nil &&
        [url getResourceValue:&isDownloadRequested forKey:NSURLUbiquitousItemDownloadRequestedKey error:&error] &&
        error == nil &&
        [url getResourceValue:&downloadStatus forKey:NSURLUbiquitousItemDownloadingStatusKey error:&error] &&
        error == nil &&
        ([isDownloadRequested boolValue] || [isDownloading boolValue]) &&
        [downloadStatus isEqualToString:NSURLUbiquitousItemDownloadingStatusNotDownloaded]) {
        
        label.text = @"Downloading"; // TODO: show loading spin
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
    NSURL *url = amkFiles[indexPath.row];
    
    if ([[NSFileManager defaultManager] isUbiquitousItemAtURL:url]) {
        NSString *downloadedFilename = nil;
        [url getResourceValue:&downloadedFilename forKey:NSURLLocalizedNameKey error:nil];
        url = [[url URLByDeletingLastPathComponent] URLByAppendingPathComponent:downloadedFilename];
    }

    MLUbiquitousStateAlertController *controller = [[MLUbiquitousStateAlertController alloc] initWithUbiquitousItem:url];
    if (controller != nil) {
        controller.onDone = ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AmkFilenameSelectedNotification"
                                                                object:url];
            self.ubiquitousController = nil;
        };
        controller.onError = ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                           message:NSLocalizedString(@"Cannot get file from iCloud", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            self.ubiquitousController = nil;
        };
        [controller presentAt:self];
        self.ubiquitousController = controller;
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AmkFilenameSelectedNotification"
                                                        object:url];
}

@end
