//
//  MLPatientViewController.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 2/5/18.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLPatientViewController.h"
#import "SWRevealViewController.h"

#import "MLPatientDBAdapter.h"

@interface MLPatientViewController ()

- (BOOL) stringIsNilOrEmpty:(NSString*)str;
- (BOOL) validateFields:(MLPatient *)patient;
- (MLPatient *) getAllFields;
- (void) resetAllFields;
- (void) friendlyNote;

@end

#pragma mark -

@implementation MLPatientViewController
{
    MLPatientDBAdapter *mPatientDb;
    NSString *mPatientUUID;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    SWRevealViewController *revealController = [self revealViewController];

    UIBarButtonItem *revealButtonItem =
    [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                     style:UIBarButtonItemStylePlain
                                    target:revealController
                                    action:@selector(revealToggle:)];
    self.navigationItem.leftBarButtonItem = revealButtonItem;
    
    mPatientUUID = nil;

    // Open patient DB
    mPatientDb = [[MLPatientDBAdapter alloc] init];
    if (![mPatientDb openDatabase:@"patient_db"]) {
        NSLog(@"Could not open patient DB!");
        mPatientDb = nil;
    }
    
    [mNotification setText:@""];
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

- (BOOL) stringIsNilOrEmpty:(NSString*)str
{
    return !(str && str.length);
}

- (void) resetFieldsColors
{
    mFamilyName.backgroundColor = nil;
    mGivenName.backgroundColor = nil;
    mBirthDate.backgroundColor = nil;
    mPostalAddress.backgroundColor = nil;
    mCity.backgroundColor = nil;
    mZipCode.backgroundColor = nil;
    mSex.backgroundColor = nil;
}

- (void) resetAllFields
{
    [self resetFieldsColors];
    
    [mFamilyName setText:@""];
    [mGivenName setText:@""];
    [mBirthDate setText:@""];
    [mCity setText:@""];
    [mZipCode setText:@""];
    [mWeight_kg setText:@""];
    [mHeight_cm setText:@""];
    [mPostalAddress setText:@""];
    [mZipCode setText:@""];
    [mCity setText:@""];
    [mCountry setText:@""];
    [mPhone setText:@""];
    [mEmail setText:@""];
    [mSex setSelectedSegmentIndex:UISegmentedControlNoSegment];
    
    mPatientUUID = nil;
    
    [mNotification setText:@""];
}

- (void) friendlyNote
{
    [mNotification setText:NSLocalizedString(@"Contact was saved in the AmiKo address book.", nil)];
}


// Validate required fields
- (BOOL) validateFields:(MLPatient *)patient
{
    BOOL valid = TRUE;
    UIColor *lightRed = [UIColor colorWithRed:1.0
                                        green:0.0
                                         blue:0.0
                                        alpha:0.3];

    [self resetFieldsColors];
    
    if ([self stringIsNilOrEmpty:patient.familyName]) {
        mFamilyName.backgroundColor = lightRed;
        valid = FALSE;
    }

    if ([self stringIsNilOrEmpty:patient.givenName]) {
        mGivenName.backgroundColor = lightRed;
        valid = FALSE;
    }

    if ([self stringIsNilOrEmpty:patient.birthDate]) {
        mBirthDate.backgroundColor = lightRed;
        valid = FALSE;
    }

    if ([self stringIsNilOrEmpty:patient.postalAddress]) {
        mPostalAddress.backgroundColor = lightRed;
        valid = FALSE;
    }

    if ([self stringIsNilOrEmpty:patient.city]) {
        mCity.backgroundColor = lightRed;
        valid = FALSE;
    }

    if ([self stringIsNilOrEmpty:patient.zipCode]) {
        mZipCode.backgroundColor = lightRed;
        valid = FALSE;
    }
    
    if ([mSex selectedSegmentIndex] == UISegmentedControlNoSegment) {
        mSex.backgroundColor = lightRed;
        valid = FALSE;
    }

    // TODO: the email is an optional field,
    // but if it's there, check at least that it is like *@*

    return valid;
}

- (MLPatient *) getAllFields
{
    MLPatient *patient = [[MLPatient alloc] init];
    patient.familyName = [mFamilyName text];
    
    patient.givenName = [mGivenName text];
    patient.birthDate = [mBirthDate text];
    patient.city = [mCity text];
    patient.zipCode = [mZipCode text];
    patient.postalAddress = [mPostalAddress text];
    patient.weightKg = [[mWeight_kg text] intValue];
    patient.heightCm = [[mHeight_cm text] intValue];
    patient.country = [mCountry text];
    patient.phoneNumber = [mPhone text];
    patient.emailAddress = [mEmail text];
    
    switch ([mSex selectedSegmentIndex]) {
        case UISegmentedControlNoSegment:
            patient.gender = @"";
            break;
        case 0:
            patient.gender = @"man";
            break;
        case 1:
            patient.gender = @"woman";
            break;
    }

    return patient;
}

#pragma mark - Actions

- (IBAction) cancelPatient:(id)sender
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    [self resetAllFields];
    // TODO: show list of patients from DB
}

- (IBAction) savePatient:(id)sender
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif

    if (!mPatientDb) {
        NSLog(@"%s Patient DB is null", __FUNCTION__);
        return;
    }
    
    MLPatient *patient = [self getAllFields];
    if (![self validateFields:patient]) {
        NSLog(@"Patient field validation failed");
        return;
    }
    
    if (mPatientUUID && [mPatientUUID length]>0)
        patient.uniqueId = mPatientUUID;
    
    if ([mPatientDb getPatientWithUniqueID:mPatientUUID]==nil) {
        mPatientUUID = [mPatientDb addEntry:patient];
    }
    else {
        mPatientUUID = [mPatientDb insertEntry:patient];
    }

#if 0 // TODO
    mSearchFiltered = FALSE;
    [mSearchKey setStringValue:@""];
    [self updateAmiKoAddressBookTableView];
#endif
    [self friendlyNote];
}

@end
