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

static const float kAmkLabelFontSize = 12.0;

@interface AmkListViewController ()

@end

@implementation AmkListViewController
{
    NSMutableArray *amkFiles;
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

- (void) refreshList
{
    NSString *amkDir = [MLUtility amkDirectory];
#ifdef DEBUG
    NSLog(@"%s %p %@", __FUNCTION__, self, amkDir);
#endif
    NSError *error;
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:amkDir error:&error];
    NSArray *amkFilesArray = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.amk'"]];
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:nil ascending:NO];
    amkFilesArray = [amkFilesArray sortedArrayUsingDescriptors:@[sd]];    
    amkFiles = [[NSMutableArray alloc] initWithArray:amkFilesArray];

    if (error)
        NSLog(@"%@", error.localizedDescription);
    
    [myTableView reloadData];
}

- (void) removeFromListByFilename:(NSString *)path
{
#ifdef DEBUG
    //NSLog(@"%s %@", __FUNCTION__, path);
#endif
    for (int i=0; i<[amkFiles count]; i++) {
        //NSLog(@"%d %@", i, amkFiles[i]);
        if ([amkFiles[i] isEqualToString:path]) {
            [amkFiles removeObjectAtIndex:i];
            [myTableView reloadData];
            return;
        }
    }
}

// Also delete the file
- (void) removeItem:(NSUInteger)rowIndex
{
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
    
    // If it's the one currently displayed,
    // remove it from the defaults and refresh the prescription view
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *fileName = [defaults stringForKey:@"lastUsedPrescription"];
    NSLog(@"lastUsedPrescription: %@, amkFiles[rowIndex] %@", fileName, amkFiles[rowIndex]);
    if ([fileName isEqualToString:amkFiles[rowIndex]]) {
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
#ifdef DEBUG
        //NSLog(@"gestureRecognizer.state = %ld", gesture.state);
#endif
        return;
    }

    //NSLog(@"long press on table view at row %ld", indexPath.row);

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];

    NSString *actionTitle = [NSString stringWithFormat:NSLocalizedString(@"Confirm delete %@",nil), amkFiles[indexPath.row]];
    
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
        //cell.textLabel.textAlignment = NSTextAlignmentLeft;
        
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
        
        // subLabel.text = [mSectionTitles objectAtIndex:indexPath.row];
        subLabel.tag = 123; // Constant which uniquely defines the label
        [cell.contentView addSubview:subLabel];
    }
    
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:123];
    label.text = [amkFiles[indexPath.row] stringByDeletingPathExtension];
//    cell.textLabel.text = amkFiles[indexPath.row];
//    [cell.textLabel setFont:[UIFont systemFontOfSize:kAmkLabelFontSize]];
    return cell;
}

#pragma mark - UITableViewDelegate

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return kAmkLabelFontSize;
//}

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
    NSString *filename = amkFiles[indexPath.row];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AmkFilenameSelectedNotification"
                                                        object:filename];
}

@end
