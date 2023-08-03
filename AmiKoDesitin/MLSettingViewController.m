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
#import <SafariServices/SafariServices.h>
#import <AuthenticationServices/AuthenticationServices.h>
#import "HINClient/MLHINClient.h"

@interface MLSettingViewController () <UITableViewDelegate, UITableViewDataSource, ASWebAuthenticationPresentationContextProviding>
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
    return 2;
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
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"SDSLabel"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                              reuseIdentifier:@"SDSLabel"];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.textLabel.text = NSLocalizedString(@"HIN (SDS) Login:", @"");
            }
            MLHINTokens *tokens = [[MLPersistenceManager shared] HINSDSTokens];
            if (tokens) {
                cell.detailTextLabel.text = tokens.hinId;
            } else {
                cell.detailTextLabel.text = NSLocalizedString(@"[Not logged in]",@"");
            }
            return cell;
        } else if (indexPath.row == 1) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"SDSButton"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                              reuseIdentifier:@"SDSButton"];
                cell.textLabel.textColor = [UIColor systemBlueColor];
            }
            MLHINTokens *tokens = [[MLPersistenceManager shared] HINSDSTokens];
            if (tokens) {
                cell.textLabel.text = NSLocalizedString(@"Logout from HIN (SDS)", @"");
            } else {
                cell.textLabel.text = NSLocalizedString(@"Login with HIN (SDS)", @"");
            }
            return cell;
        }
    } else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"ADSwissLabel"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                              reuseIdentifier:@"ADSwissLabel"];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.textLabel.text = NSLocalizedString(@"HIN (ADSwiss) Login:", @"");
            }
            MLHINTokens *tokens = [[MLPersistenceManager shared] HINADSwissTokens];
            if (tokens) {
                cell.detailTextLabel.text = tokens.hinId;
            } else {
                cell.detailTextLabel.text = NSLocalizedString(@"[Not logged in]",@"");
            }
            return cell;
        } else if (indexPath.row == 1) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"ADSwissButton"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                              reuseIdentifier:@"ADSwissButton"];
                cell.textLabel.textColor = [UIColor systemBlueColor];
            }
            MLHINTokens *tokens = [[MLPersistenceManager shared] HINADSwissTokens];
            if (tokens) {
                cell.textLabel.text = NSLocalizedString(@"Logout from HIN (ADSwiss)", @"");
            } else {
                cell.textLabel.text = NSLocalizedString(@"Login with HIN (ADSwiss)", @"");
            }
            return cell;
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.row == 1) {
        [self loginWithHINSDSClicked:tableView];
    } else if (indexPath.section == 2 && indexPath.row == 1) {
        [self loginwithHINADSwissClicked:tableView];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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

- (IBAction)loginWithHINSDSClicked:(id)sender {
    MLHINTokens *tokens = [[MLPersistenceManager shared] HINSDSTokens];
    if (!tokens) {
        typeof(self) __weak _self = self;
        NSURL *url = [[MLHINClient shared] authURLForSDS];
        ASWebAuthenticationSession *session = [[ASWebAuthenticationSession alloc] initWithURL:url
                                                                            callbackURLScheme:[[MLHINClient shared] oauthCallbackScheme]
                                                                            completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
            if (callbackURL) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Loading",@"")
                                                                               message:nil
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [_self presentViewController:alert animated:YES completion:nil];
                [[MLHINClient shared] handleSDSOAuthCallback:callbackURL callback:^(NSError * _Nonnull error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [alert dismissViewControllerAnimated:YES completion:nil];
                        if (error) {
                            UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error",@"")
                                                                                                message:error.localizedDescription
                                                                                         preferredStyle:UIAlertControllerStyleAlert];
                            [errorAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",@"")
                                                                           style:UIAlertActionStyleDefault
                                                                         handler:nil]];
                            [_self presentViewController:errorAlert animated:YES completion:nil];
                        }
                        [_self.tableView reloadData];
                    });
                }];
            }
        }];
        session.presentationContextProvider = self;
        [session start];
    } else {
        [[MLPersistenceManager shared] setHINSDSTokens:nil];
        [self.tableView reloadData];
    }
}

- (IBAction)loginwithHINADSwissClicked:(id)sender {
    MLHINTokens *tokens = [[MLPersistenceManager shared] HINADSwissTokens];
    if (!tokens) {
        typeof(self) __weak _self = self;
        NSURL *url = [[MLHINClient shared] authURLForADSwiss];
        ASWebAuthenticationSession *session = [[ASWebAuthenticationSession alloc] initWithURL:url
                                                                            callbackURLScheme:[[MLHINClient shared] oauthCallbackScheme]
                                                                            completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
            if (callbackURL) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Loading",@"")
                                                                               message:nil
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [_self presentViewController:alert animated:YES completion:nil];
                [[MLHINClient shared] handleADSwissOAuthCallback:callbackURL callback:^(NSError * _Nonnull error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [alert dismissViewControllerAnimated:YES completion:nil];
                        if (error) {
                            UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error",@"")
                                                                                                message:error.localizedDescription
                                                                                         preferredStyle:UIAlertControllerStyleAlert];
                            [errorAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",@"")
                                                                           style:UIAlertActionStyleDefault
                                                                         handler:nil]];
                            [_self presentViewController:errorAlert animated:YES completion:nil];
                        }
                        [_self.tableView reloadData];
                    });
                }];
            }
        }];
        session.presentationContextProvider = self;
        [session start];
    } else {
        [[MLPersistenceManager shared] setHINADSwissTokens:nil];
        [self.tableView reloadData];
    }
}

- (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:(ASWebAuthenticationSession *)session {
    return self.view.window;
}

@end
