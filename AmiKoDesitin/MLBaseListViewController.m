//
//  MLBaseListViewController.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 13 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLBaseListViewController.h"

@interface MLBaseListViewController ()

@end

@implementation MLBaseListViewController

@synthesize theSearchBar;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (id) getItemAtRow:(NSInteger)row
{
    if (mSearchFiltered)
        return mFilteredArray[row];
    
    if (mArray)
        return mArray[row];
    
    return nil;
}

//- (NSString *) getTextAtRow:(NSInteger)row
//{
//#ifdef DEBUG
//    NSLog(@"%s", __FUNCTION__);
//#endif
//    return @"";
//}

#pragma mark - UITableViewDataSource

- (NSInteger) tableView: (UITableView *)tableView
  numberOfRowsInSection: (NSInteger)section
{
    if (mSearchFiltered)
        return [mFilteredArray count];
    
    return [mArray count];
}

- (UITableViewCell *) tableView: (UITableView *)tableView
          cellForRowAtIndexPath: (NSIndexPath *)indexPath
{    
    //static NSString *tableIdentifier = @"genericListTableItem";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:tableIdentifier];
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        //cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textColor = textColor;
    }
    
    //NSLog(@"self: %@", [self class]);
    NSString *cellStr = [self getTextAtRow:indexPath.row];
    cell.textLabel.text = cellStr;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
    // Show front view
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName
                                                        object:[self getItemAtRow:indexPath.row]];
    
    mSearchFiltered = FALSE;
}

@end
