//
//  MLAmkListViewController.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 30 Jan 2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLAmkListViewController.h"
#import "SWRevealViewController.h"
#import "MLUtility.h"

static const float kAmkLabelFontSize = 12.0;

@interface MLAmkListViewController ()

@end

@implementation MLAmkListViewController
{
    NSMutableArray *amkFiles;
}

@synthesize myTableView;

- (void)viewDidLoad
{
    [super viewDidLoad];
   
    if (IOS_NEWER_OR_EQUAL_TO_7) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        myTableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }
    
    NSError *error;
    NSString *amkDir = [MLUtility amkDirectory];
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:amkDir error:&error];
    NSArray *amkFilesArray = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.amk'"]];
    amkFiles = [[NSMutableArray alloc] initWithArray:amkFilesArray];

    if (error)
        NSLog(@"%@", error.localizedDescription);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) removeItem:(NSUInteger)rowIndex
{
    NSLog(@"Delete amk file: %@", amkFiles[rowIndex]);
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

    NSString *actionTitle = [NSString stringWithFormat:NSLocalizedString(@"Confirm delete %@",nil), amkFiles[indexPath.row]];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *actionDelete = [UIAlertAction actionWithTitle:actionTitle
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action) {
                                                         [alertController dismissViewControllerAnimated:YES completion:nil];

                                                         [self removeItem:indexPath.row];
                                                         }];
    
    // Cancel buttons are removed from popovers automatically, because tapping outside the popover represents "cancel", in a popover context
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                             [alertController dismissViewControllerAnimated:YES completion:nil];
                                                         }];
    [alertController addAction:actionDelete];
    [alertController addAction:actionCancel];
    [alertController setModalPresentationStyle:UIModalPresentationPopover];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
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
        cell.textLabel.textAlignment = NSTextAlignmentRight;
        
        /** Use subview */
        UILabel *subLabel = nil;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            subLabel = [[UILabel alloc] initWithFrame:CGRectMake(20,0,230,36)];
            [subLabel setFont:[UIFont systemFontOfSize:kAmkLabelFontSize+2]];
        }
        else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            subLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,230,28)];
            [subLabel setFont:[UIFont systemFontOfSize:kAmkLabelFontSize]];
        }
        subLabel.textAlignment = NSTextAlignmentRight;
        
        // subLabel.text = [mSectionTitles objectAtIndex:indexPath.row];
        subLabel.tag = 123; // Constant which uniquely defines the label
        [cell.contentView addSubview:subLabel];
    }
    
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:123];
    label.text = amkFiles[indexPath.row];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AmkFilenameNotification"
                                                        object:filename];
}
@end
