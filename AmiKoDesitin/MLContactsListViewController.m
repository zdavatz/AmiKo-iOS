//
//  MLContactsListViewController.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 8 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLContactsListViewController.h"

@interface MLContactsListViewController ()

@end

@implementation MLContactsListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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

#pragma mark - UITableViewDataSource

- (NSInteger) tableView: (UITableView *)tableView
  numberOfRowsInSection: (NSInteger)section
{
    return 32; // TODO: scrool bar
}

- (UITableViewCell *) tableView: (UITableView *)tableView
          cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    static NSString *tableIdentifier = @"contactsListTableItem";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:tableIdentifier];
        //cell.textLabel.textAlignment = NSTextAlignmentRight;
        //cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"Contact example %ld", indexPath.row];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"example %ld", indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
#ifdef DEBUG
    NSLog(@"%s selected row:%ld", __FUNCTION__, indexPath.row);
#endif
    // TODO: Add contact to patient DB
}

@end
