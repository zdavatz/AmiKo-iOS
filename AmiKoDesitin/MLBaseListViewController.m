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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
    return 20;
}

- (UITableViewCell *) tableView: (UITableView *)tableView
          cellForRowAtIndexPath: (NSIndexPath *)indexPath
{    
    static NSString *tableIdentifier = @"genericListTableItem";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:tableIdentifier];
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        //cell.selectionStyle = UITableViewCellSelectionStyleNone;
        //cell.textLabel.textColor = [UIColor blackColor];
    }
    
    NSString *cellStr = [NSString stringWithFormat:@"TODO patient %ld", indexPath.row];
    cell.textLabel.text = cellStr;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
#ifdef DEBUG
    NSLog(@"%s selected row:%ld, TODO: show front view", __FUNCTION__, indexPath.row);
#endif
    
}

@end
