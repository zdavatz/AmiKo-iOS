//
//  MLSDSOAuthWindowController.m
//  AmikoDesitin
//
//  Created by b123400 on 2023/07/28.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import "MLSDSOAuthViewController.h"
#import "MLHINClient.h"
#import "MLPersistenceManager.h"
#import "Operator.h"

@interface MLSDSOAuthViewController ()

@end

@implementation MLSDSOAuthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"")
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(closeButtonTapped:)];
}

- (NSURL *)authURL {
    return [[MLHINClient shared] authURLForSDS];
}

- (void)receivedTokens:(id)tokens {
    [[MLPersistenceManager shared] setHINSDSTokens:tokens];
    [self displayStatus:NSLocalizedString(@"Fetching profile", @"")];
    typeof(self) __weak _self = self;
    [[MLHINClient shared] fetchSDSSelfWithToken:tokens
                                     completion:^(NSError * _Nonnull error, MLHINProfile * _Nonnull profile) {
        if (error) {
            [_self displayError:error];
            return;
        }
        if (!profile) {
            [_self displayError:[NSError errorWithDomain:@"com.ywesee.AmikoDesitin"
                                                    code:0
                                                userInfo:@{
                NSLocalizedDescriptionKey: @"Invalid profile response"
            }]];
            return;
        }
        [_self displayStatus:NSLocalizedString(@"Received profile", @"")];
        Operator *doctor = [Operator new];
        NSDictionary *doctorDictionary = [[MLPersistenceManager shared] doctorDictionary];
        [doctor importFromDict:doctorDictionary];
        [_self mergeHINProfile:profile withDoctor:doctor];
        [[MLPersistenceManager shared] setDoctorDictionary:[doctor toDictionary]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_self.delegate sdsOAuthViewControllerDidFinishedOAuth:_self];
        });
    }];
}

- (void)mergeHINProfile:(MLHINProfile *)profile withDoctor:(Operator *)doctor {
    if (!doctor.emailAddress.length) {
        doctor.emailAddress = profile.email;
    }
    if (!doctor.familyName.length) {
        doctor.familyName = profile.lastName;
    }
    if (!doctor.givenName.length) {
        doctor.givenName = profile.firstName;
    }
    if (!doctor.postalAddress.length) {
        doctor.postalAddress = profile.address;
    }
    if (!doctor.zipCode.length) {
        doctor.zipCode = profile.postalCode;
    }
    if (!doctor.city.length) {
        doctor.city = profile.city;
    }
    if (!doctor.phoneNumber.length) {
        doctor.phoneNumber = profile.phoneNr;
    }
    if (!doctor.gln.length) {
        doctor.gln = profile.gln;
    }
}

- (void)closeButtonTapped:(id)sender {
    [self.delegate sdsOAuthViewControllerDidFinishedOAuth:self];
}

@end
