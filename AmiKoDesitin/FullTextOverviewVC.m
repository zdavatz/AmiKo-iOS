//
//  FullTextOverviewVC.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 24/07/2019.
//  Copyright © 2019 Ywesee GmbH. All rights reserved.
//

#import "FullTextOverviewVC.h"
#import "SWRevealViewController.h"

static const float kFtLabelFontSize = 12.0;

@interface FullTextOverviewVC ()

@end

@implementation FullTextOverviewVC
{
    //NSMutableArray *ftResults;
}

@synthesize myTableView;
@synthesize ftResults;

+ (FullTextOverviewVC *)sharedInstance
{
    __strong static id sharedObject = nil;
    
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedObject = [self new];
    });
    
    return sharedObject;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.revealViewController.rightViewRevealWidth = 240.0;
}

- (void)viewDidAppear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    [myTableView reloadData];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UITableViewDataSource

- (NSInteger) tableView: (UITableView *)tableView
  numberOfRowsInSection: (NSInteger)section
{
    return [ftResults count];
}

- (UITableViewCell *) tableView: (UITableView *)tableView
          cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    static NSString *tableIdentifier = @"ftOverviewListTableItem";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:tableIdentifier];
        //cell.textLabel.textAlignment = NSTextAlignmentLeft;
        
        /** Use subview */
        UILabel *subLabel = nil;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            subLabel = [[UILabel alloc] initWithFrame:CGRectMake(20,0,230,36)];
            [subLabel setFont:[UIFont systemFontOfSize:kFtLabelFontSize+2]];
        }
        else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            subLabel = [[UILabel alloc] initWithFrame:CGRectMake(20,0,230,28)];
            [subLabel setFont:[UIFont systemFontOfSize:kFtLabelFontSize]];
        }
        subLabel.textAlignment = NSTextAlignmentLeft;
        
        // subLabel.text = [mSectionTitles objectAtIndex:indexPath.row];
        subLabel.tag = 123; // Constant which uniquely defines the label
        [cell.contentView addSubview:subLabel];
    }
    
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:123];
    label.text = [ftResults[indexPath.row] stringByDeletingPathExtension];
//    cell.textLabel.text = ftResults[indexPath.row];
//    [cell.textLabel setFont:[UIFont systemFontOfSize:kFtLabelFontSize]];
    return cell;
}

#pragma mark - UITableViewDelegate

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return kFtLabelFontSize;
//}

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
    // Check that ftResults has more than 1 item, otherwise there is no point in resorting
    if ([ftResults count] < 2) {
        // Close the right pane and return
        [self.revealViewController rightRevealToggleAnimated:YES];
        return;
    }
    
#ifdef DEBUG
    NSString *selectedText = ftResults[indexPath.row];
    NSLog(@"%s, ftResults count: %lu, selectedText: %@", __FUNCTION__,
          (unsigned long)[ftResults count], selectedText);
#endif

    NSDictionary *patientDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithInt: indexPath.row], KEY_FT_ROW,
                                 selectedText,     KEY_FT_TEXT,
                                 nil];

#if 0
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ftOverviewSelectedNotification"
                                                        object:[NSNumber numberWithInt: indexPath.row]];
#else
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ftOverviewSelectedNotification"
                                                        object:patientDict];
#endif
}

@end
