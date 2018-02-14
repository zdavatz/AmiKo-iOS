//
//  MLPatientDbListViewController.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 13 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLPatientDbListViewController.h"
#import "MLPatientDBAdapter.h"

@interface MLPatientDbListViewController ()

@end

@implementation MLPatientDbListViewController
{
    MLPatientDBAdapter *mPatientDb;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    notificationName = @"ContactSelectedNotification";
    tableIdentifier = @"patientDbListTableItem";
    textColor = [UIColor blackColor];

    mSearchFiltered = FALSE;

    // Retrieves contacts from address DB
    // Open patient DB
    mPatientDb = [[MLPatientDBAdapter alloc] init];
    if (![mPatientDb openDatabase:@"patient_db"]) {
        NSLog(@"Could not open patient DB!");
        mPatientDb = nil;
    }
    else
        mArray = [mPatientDb getAllPatients];
}

- (void)viewDidAppear:(BOOL)animated {
    [self.theSearchBar becomeFirstResponder];
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (NSString *) getTextAtRow:(NSInteger)row
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    MLPatient *p = [self getItemAtRow:row];
    NSString *cellStr = [NSString stringWithFormat:@"%@ %@", p.familyName, p.givenName];
    return cellStr;
}
@end
