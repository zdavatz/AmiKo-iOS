//
//  MLPatientDbListViewController.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 13 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLPatientDbListViewController.h"
#import "MLPatientDBAdapter.h"
#import "SWRevealViewController.h"

@interface MLPatientDbListViewController ()

@end

@implementation MLPatientDbListViewController
{
    MLPatientDBAdapter *mPatientDb;
}

+ (MLPatientDbListViewController *)sharedInstance
{
    __strong static id sharedObject = nil;

    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

// Called once per instance
- (void)viewDidLoad
{
#ifdef DEBUG
    NSLog(@"%s %p", __FUNCTION__, self);
#endif
    [super viewDidLoad];

    notificationName = @"PatientSelectedNotification";
    tableIdentifier = @"patientDbListTableItem";
    textColor = [UIColor blackColor];
}

// Called every time the instance is displayed
- (void)viewDidAppear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"%s %p", __FUNCTION__, self);
#endif
    
    mSearchFiltered = FALSE;
    
    // Retrieves contacts from address DB
    // Open patient DB
    mPatientDb = [[MLPatientDBAdapter alloc] init];
    if (![mPatientDb openDatabase:@"patient_db"]) {
        NSLog(@"Could not open patient DB!");
        mPatientDb = nil;
    }
    else {
        self.mArray = [mPatientDb getAllPatients];
        [mTableView reloadData];
    }    

    [self.theSearchBar becomeFirstResponder];
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) removeItem:(NSUInteger)rowIndex
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    MLPatient *pat = nil;
    if (mSearchFiltered) {
        pat = mFilteredArray[rowIndex];
    }
    else {
        pat = self.mArray[rowIndex];
    }
    
#if 0
    NSString *amkDir = [MLUtility amkDirectory];
    NSString *destination = [amkDir stringByAppendingPathComponent:amkFiles[rowIndex]];
    
    // TODO: find patient subdirectory and loop to delete all AMK files. Finally delete directory.
    
    if (![[NSFileManager defaultManager] isDeletableFileAtPath:destination]) {
        NSLog(@"Error removing file at path: %@", amkFiles[rowIndex]);
        return;
    }
    
    // First remove the actual file
    NSError *error;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:destination
                                                              error:&error];
    if (!success)
        NSLog(@"Error removing file at path: %@", error.localizedDescription);
    
#endif

#ifdef DEBUG
    NSLog(@"patients before deleting: %ld", [mPatientDb getNumPatients]);
#endif
    
    // Finally remove the entry from the list
    [mPatientDb deleteEntry:pat];

#ifdef DEBUG
    NSLog(@"patients after deleting: %ld", [mPatientDb getNumPatients]);
#endif

    // (Instead of removing one item from a NSMutableArray) reassign the whole NSArray
    self.mArray = [mPatientDb getAllPatients];

    mSearchFiltered = FALSE;
    [mTableView reloadData];
}

#pragma mark - Overloaded

- (NSString *) getTextAtRow:(NSInteger)row
{
#ifdef DEBUG
    //NSLog(@"%s", __FUNCTION__);
#endif
    MLPatient *p = [self getItemAtRow:row];
    NSString *cellStr = [NSString stringWithFormat:@"%@ %@", p.familyName, p.givenName];
    return cellStr;
}

#pragma mark - UIGestureRecognizerDelegate

- (IBAction) handleLongPress:(UILongPressGestureRecognizer *)gesture
{
    CGPoint p = [gesture locationInView:mTableView];
    NSIndexPath *indexPath = [mTableView indexPathForRowAtPoint:p];
    
    if (indexPath == nil) {
        NSLog(@"long press on table view but not on a row");
        return;
    }

    if (gesture.state != UIGestureRecognizerStateBegan) {
#ifdef DEBUG
        //NSLog(@"gestureRecognizer.state = %ld", gesture.state);
#endif
        return;
    }
    
    //NSLog(@"long press on table view at row %ld", indexPath.row);

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *actionDelete = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [alertController dismissViewControllerAnimated:YES completion:nil];
                                                             
                                                              [self removeItem:indexPath.row];
                                                         }];
    
    UIAlertAction *actionEdit = [UIAlertAction actionWithTitle:NSLocalizedString(@"Edit", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [alertController dismissViewControllerAnimated:YES completion:nil];

                                                             NSLog(@"TODO: Show patient edit view");
                                                         }];
    [alertController addAction:actionDelete];
    [alertController addAction:actionEdit];
    [alertController setModalPresentationStyle:UIModalPresentationPopover];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UITableViewCell *cell = [mTableView cellForRowAtIndexPath:indexPath];
        alertController.popoverPresentationController.sourceView = cell.contentView;
    }
    
    [self presentViewController:alertController animated:YES completion:nil]; // It returns immediately
}

@end
