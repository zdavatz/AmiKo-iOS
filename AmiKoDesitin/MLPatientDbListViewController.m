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

- (void)viewDidLoad
{
    [super viewDidLoad];

    notificationName = @"ContactSelectedNotification";
    tableIdentifier = @"patientDbListTableItem";
    textColor = [UIColor blackColor];

    mSearchFiltered = FALSE;

    // Retrieves contacts from address DB
    // Open patient DB
    mPatientDb = [[MLPatientDBAdapter alloc] init];
    if (![mPatientDb openDatabase:@"patient_db"]) {
        NSLog(@"Could not open patient DB!");
        mPatientDb = nil;
    }
    else
        mArray = [mPatientDb getAllPatients];
}

- (void)viewDidAppear:(BOOL)animated {
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
        pat = mArray[rowIndex];
    }
    
#if 0 // TODO remove all amk files for this patient
    NSString *amkDir = [MLUtility amkDirectory];
    NSString *destination = [amkDir stringByAppendingPathComponent:amkFiles[rowIndex]];
    
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

    // Finally remove the entry from the list
    [mPatientDb deleteEntry:pat];
    mArray = [mPatientDb getAllPatients];
    mSearchFiltered = FALSE;
    [mTableView reloadData];  // TODO: debug why it's not refreshed
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
    
    NSLog(@"long press on table view at row %ld", indexPath.row);
    MLPatient *pat = nil;
//    if (mSearchFiltered) {
//        pat = mFilteredArray[indexPath.row];
//    } else {
//        pat = mArray[indexPath.row];
//    }

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *actionDelete = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [alertController dismissViewControllerAnimated:YES completion:nil];
                                                             
                                                              [self removeItem:indexPath.row];
                                                         }];
    
    // Cancel buttons are removed from popovers automatically, because tapping outside the popover represents "cancel", in a popover context
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
