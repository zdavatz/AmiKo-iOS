//
//  MLSettingViewController.m
//  AmikoDesitin
//
//  Created by b123400 on 2020/03/23.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//

#import "MLSettingViewController.h"
#import "SWRevealViewController.h"
#import "MLPersistenceManager.h"

@interface MLSettingViewController () <MLSDSOAuthViewControllerDelegate, UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) UISwitch *iCloudSwitch;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (void)reloadICloudSwitch;

@end

@implementation MLSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.iCloudSwitch = [[UISwitch alloc] init];
    [self.iCloudSwitch addTarget:self
                          action:@selector(iCloudSwitched:)
                forControlEvents:UIControlEventValueChanged];
    
    SWRevealViewController *revealController = [self revealViewController];
    self.navigationItem.title = NSLocalizedString(@"Settings", nil);      // grey, in the navigation bar

    // Left button(s)
    UIBarButtonItem *revealButtonItem =
    [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:NAVIGATION_ICON_LEFT]
                                     style:UIBarButtonItemStylePlain
                                    target:revealController
                                    action:@selector(revealToggle:)];
    
    // A single button on the left
    self.navigationItem.leftBarButtonItem = revealButtonItem;
    
    [self reloadICloudSwitch];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSUbiquityIdentityDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        [self reloadICloudSwitch];
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 1;
        case 1: return 2;
        case 2: return 2;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"iCloud"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:@"iCloud"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryView = self.iCloudSwitch;
            cell.textLabel.text = NSLocalizedString(@"Sync with iCloud", @"");
        }
        return cell;
    }
    return nil;
}
- (IBAction)iCloudSwitched:(id)sender {
    if (self.iCloudSwitch.on) {
        [[MLPersistenceManager shared] setCurrentSourceToICloud];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Migrate from iCloud", nil)
                                                                       message:NSLocalizedString(@"Do you want to delete the files on iCloud?", nil)
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", nil)
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction * _Nonnull action) {
            [[MLPersistenceManager shared] setCurrentSourceToLocalWithDeleteICloud:YES];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No", nil)
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
            [[MLPersistenceManager shared] setCurrentSourceToLocalWithDeleteICloud:NO];
        }]];
        [[alert popoverPresentationController] setSourceView:self.iCloudSwitch];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)reloadICloudSwitch {
    if (![MLPersistenceManager supportICloud]) {
        self.iCloudSwitch.enabled = NO;
        self.iCloudSwitch.on = NO;
    } else {
        self.iCloudSwitch.on = [[MLPersistenceManager shared] currentSource] == MLPersistenceSourceICloud;
    }
}

@end
