//
//  PatientDbListViewController.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 13 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "PatientDbListViewController.h"
#import "LegacyPatientDBAdapter.h"
#import "SWRevealViewController.h"

#import "MLViewController.h"
#import "PatientViewController.h"

#import "MLAppDelegate.h"
#import "MLPersistenceManager.h"

@interface PatientDbListViewController ()

@property (nonatomic, strong) NSFetchedResultsController *resultsController;

@end

@implementation PatientDbListViewController

+ (PatientDbListViewController *)sharedInstance
{
    __strong static id sharedObject = nil;

    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedObject = [self new];
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
    
    if (!self.resultsController) {
        self.resultsController = [[MLPersistenceManager shared] resultsControllerForAllPatients];
        self.resultsController.delegate = self;
    }

    notificationName = @"PatientSelectedNotification";
    tableIdentifier = @"patientDbListTableItem";
    textColor = [UIColor labelColor];
    // TODO: (TBC) make sure the right view is back to the iOS Contacts list, for the sake of the swiping action
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
    
    self.mArray = [[MLPersistenceManager shared] getAllPatients];
    [mTableView reloadData];

    [self.resultsController performFetch:nil];

    [self.theSearchBar becomeFirstResponder];
    [super viewDidAppear:animated];
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

- (void) removeItem:(NSUInteger)rowIndex
{
    Patient *pat = nil;
    if (mSearchFiltered) {
        pat = mFilteredArray[rowIndex];
    }
    else {
        pat = self.mArray[rowIndex];
    }
    
    // Remove the amk subdirectory for this patient
    NSURL *amkDir = [[MLPersistenceManager shared] amkDirectoryForPatient:pat.uniqueId];
    NSError *error;
    BOOL success = [[NSFileManager defaultManager] removeItemAtURL:amkDir error:&error];
    if (!success || error)
        NSLog(@"Error removing file at path: %@", error.localizedDescription);
    
    // Finally remove the entry from the list
    [[MLPersistenceManager shared] deletePatient:pat];
    // Clear the current user
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"currentPatient"];
    [defaults synchronize];
    // TODO: the patient edit view needs to go blank.
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
            self.mArray = [[MLPersistenceManager shared] getAllPatients];
    mSearchFiltered = FALSE;
    [mTableView reloadData];
}

#pragma mark - Overloaded

- (NSString *) getTextAtRow:(NSInteger)row
{
    Patient *p = [self getItemAtRow:row];
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
        return;
    }

    MLAppDelegate *appDel = (MLAppDelegate *)[[UIApplication sharedApplication] delegate];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *actionDelete = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [alertController dismissViewControllerAnimated:YES completion:nil];
                                                             
                                                              [self removeItem:indexPath.row];
                                                         }];
    [alertController addAction:actionDelete];

    if (appDel.editMode == EDIT_MODE_PRESCRIPTION) {
        UIAlertAction *actionEdit = [UIAlertAction actionWithTitle:NSLocalizedString(@"Edit", nil)
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 [alertController dismissViewControllerAnimated:YES completion:nil];
                                                                 
                                                                 // Make sure front is PatientViewController
                                                                 UIViewController *nc_front = self.revealViewController.frontViewController;
                                                                 UIViewController *vc_front = [nc_front.childViewControllers firstObject];
                                                                 if (![vc_front isKindOfClass:[PatientViewController class]]) {
                                                                     UIViewController *nc_rear = self.revealViewController.rearViewController;
                                                                     MLViewController *vc_rear = [nc_rear.childViewControllers firstObject];
                                                                     [vc_rear switchFrontToPatientEditView];
                                                                 }

                                                                 // Update the pointers to our controllers
                                                                 nc_front = self.revealViewController.frontViewController;
                                                                 vc_front = [nc_front.childViewControllers firstObject];
                                                                 if ([vc_front isKindOfClass:[PatientViewController class]]) {

                                                                     // Make sure viewDidLoad has run once before setting the patient
                                                                     [vc_front view];

                                                                     PatientViewController *pvc = (PatientViewController *)vc_front;
                                                                     [pvc resetAllFields];
                                                                     
                                                                     Patient *pat = nil;
                                                                     if (mSearchFiltered)
                                                                         pat = mFilteredArray[indexPath.row];
                                                                     else
                                                                         pat = self.mArray[indexPath.row];
                                                                     
                                                                     [pvc setAllFields:pat];

                                                                     // Finally show it
                                                                     [self.revealViewController rightRevealToggle:self];
                                                                 }
                                                                 
                                                             }];
        [alertController addAction:actionEdit];
    }
    else if ((appDel.editMode == EDIT_MODE_PATIENTS) &&
             ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone))
    {
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction *action) {
                                                                 [alertController dismissViewControllerAnimated:YES completion:nil];
                                                             }];
        [alertController addAction:actionCancel];
    }

    [alertController setModalPresentationStyle:UIModalPresentationPopover];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UITableViewCell *cell = [mTableView cellForRowAtIndexPath:indexPath];
        alertController.popoverPresentationController.sourceView = cell.contentView;
    }
    
    [self presentViewController:alertController animated:YES completion:nil]; // It returns immediately
}

@end
