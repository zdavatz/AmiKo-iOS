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
    NSArray *amkFiles;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
   
    NSError *error;
    NSString *amkDir = [MLUtility amkDirectory];
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:amkDir error:&error];
    amkFiles = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.amk'"]];
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

#pragma mark - Table view data source

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
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:tableIdentifier];
        //cell.textLabel.textAlignment = NSTextAlignmentRight;
    }
    
    cell.textLabel.text = amkFiles[indexPath.row];
    [cell.textLabel setFont:[UIFont systemFontOfSize:kAmkLabelFontSize]];
    return cell;
}

#pragma mark - Table view delegate

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
