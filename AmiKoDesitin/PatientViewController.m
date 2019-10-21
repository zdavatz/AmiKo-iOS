//
//  PatientViewController.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 5 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "PatientViewController.h"
#import "PatientViewController+smartCard.h"
#import "SWRevealViewController.h"
#import "ContactsListViewController.h"
#import "MLViewController.h"
#import "MLAppDelegate.h"
#import "MLUtility.h"

#define DYNAMIC_BUTTONS

enum {
    NameFieldTag = 1,
    SurnameFieldTag,
    AddressFieldTag,
    CityFieldTag,
    ZIPFieldTag,
    DOBFieldTag,
    SexFieldTag
};

@interface PatientViewController ()

- (BOOL) stringIsNilOrEmpty:(NSString*)str;
- (BOOL) validateFields:(Patient *)patient;
- (Patient *) getAllFields;
#ifdef DYNAMIC_BUTTONS
- (void) saveCancelOn;
- (void) saveCancelOff;
#endif

@end

#pragma mark -

@implementation PatientViewController
{
    NSString *mPatientUUID;
}

@synthesize scrollView;

+ (PatientViewController *)sharedInstance
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
    
    SWRevealViewController *revealController = [self revealViewController];

    // Left button(s)
    UIBarButtonItem *revealButtonItem =
    [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:NAVIGATION_ICON_LEFT]
                                     style:UIBarButtonItemStylePlain
                                    target:revealController
                                    action:@selector(revealToggle:)];
#if 0
    // A single button on the left
    self.navigationItem.leftBarButtonItem = revealButtonItem;
#else
    // Two buttons on the left (with spacer between them)
    UIBarButtonItem *cancelItem =
    [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(cancelPatient:)];
    
#ifdef DYNAMIC_BUTTONS
    //cancelItem.enabled = NO; // Cancel always enabled
#endif

    UIBarButtonItem *spacer =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                  target:nil
                                                  action:nil];
    spacer.width = -15.0f;
    
    self.navigationItem.leftBarButtonItems =
    [NSArray arrayWithObjects:
                revealButtonItem, spacer, cancelItem, nil];
#endif
    
    // Middle button
    {
        UIButton* cameraButton = [UIButton new];
        UIImageSymbolConfiguration *configuration =
        [UIImageSymbolConfiguration configurationWithPointSize:24.0
                                                        weight:UIImageSymbolWeightLight
                                                         scale:UIImageSymbolScaleLarge];
        UIImage *image = [UIImage systemImageNamed:@"camera.viewfinder"
                                 withConfiguration:configuration];
        [cameraButton setBackgroundImage:image
                                forState:UIControlStateNormal];
        [cameraButton addTarget:self
                          action:@selector(handleCameraButton:)
                forControlEvents:UIControlEventTouchDown];

        self.navigationItem.titleView = cameraButton;
    }

    // Right button(s)
    {
#if 1
    // First ensure the "right" is a ContactsListViewController
    id aTarget = self;
    SEL aSelector = @selector(myRightRevealToggle:);
#else
    id aTarget = revealController;
    SEL aSelector = @selector(rightRevealToggle:);
#endif
    UIBarButtonItem *rightRevealButtonItem =
    [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:NAVIGATION_ICON_RIGHT]
                                     style:UIBarButtonItemStylePlain
                                    target:aTarget
                                    action:aSelector];
#if 0
    // A single button on the right
    self.navigationItem.rightBarButtonItem = rightRevealButtonItem;
#else
    // Two buttons on the right (with spacer between them)
    UIBarButtonItem *saveItem =
    [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", nil)
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(savePatient:)];
#ifdef DYNAMIC_BUTTONS
    saveItem.enabled = NO;
#endif

    self.navigationItem.rightBarButtonItems =
    [NSArray arrayWithObjects:rightRevealButtonItem, spacer, saveItem, nil];
#endif
    }
    
#ifdef DEBUG
    //self.navigationItem.prompt = @"Patient Edit";
#endif

    scrollView.bounces = NO;
    mPatientUUID = nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contactsListDidChangeSelection:)
                                                 name:@"ContactSelectedNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lastVideoFrame:)
                                                 name:@"lastVideoFrameNotification"
                                               object:nil];

    [mSex addTarget:self
             action:@selector(sexDefined:)
   forControlEvents:UIControlEventValueChanged];
}

#ifdef DEBUG
- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"gestureRecognizers:%ld %@", [[self.view gestureRecognizers] count], [self.view gestureRecognizers]);
}
#endif

- (void)viewWillAppear:(BOOL)animated
{
    if ([[self.view gestureRecognizers] count] == 0)
        [self.view addGestureRecognizer:[self revealViewController].panGestureRecognizer];
    
    // Open patient DB
    mPatientDb = [PatientDBAdapter new];
    if (![mPatientDb openDatabase:@"patient_db"]) {
        NSLog(@"Could not open patient DB!");
        mPatientDb = nil;
    }
    
    [mNotification setText:@""];
    
    //[self startCameraStream]; // this would work but we don't want it yet
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

#pragma mark -

- (BOOL) stringIsNilOrEmpty:(NSString*)str
{
    return !(str && str.length);
}

- (void) resetFieldsColors
{
    mFamilyName.backgroundColor =
    mGivenName.backgroundColor =
    mBirthDate.backgroundColor =
    mPostalAddress.backgroundColor =
    mCity.backgroundColor =
    mZipCode.backgroundColor =
    mSex.backgroundColor =
    mEmail.backgroundColor = [UIColor secondarySystemBackgroundColor];
}

- (UIColor *)getInvalidFieldColor
{
    return [[UIColor systemRedColor] colorWithAlphaComponent:0.3];
}

- (void) checkFields
{
    [self resetFieldsColors];
    UIColor *lightRed = [self getInvalidFieldColor];
    
    if ([self stringIsNilOrEmpty:[mFamilyName text]])
        mFamilyName.backgroundColor = lightRed;

    if ([self stringIsNilOrEmpty:[mGivenName text]])
        mGivenName.backgroundColor = lightRed;

    if ([self stringIsNilOrEmpty:[mBirthDate text]])
        mBirthDate.backgroundColor = lightRed;

    if ([self stringIsNilOrEmpty:[mPostalAddress text]])
        mPostalAddress.backgroundColor = lightRed;

    if ([self stringIsNilOrEmpty:[mCity text]])
        mCity.backgroundColor = lightRed;

    if ([self stringIsNilOrEmpty:[mZipCode text]])
        mZipCode.backgroundColor = lightRed;
}

- (void) resetAllFields
{
#ifdef DEBUG
    //NSLog(@"%s %p", __FUNCTION__, self);
#endif
    
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

- (void) setAllFields:(Patient *)p
{
    if (p.familyName)
        [mFamilyName setText:p.familyName];

    if (p.givenName)
        [mGivenName setText:p.givenName];

    if (p.birthDate)
        [mBirthDate setText:p.birthDate];

    if (p.city)
        [mCity setText:p.city];

    if (p.zipCode)
        [mZipCode setText:p.zipCode];

    if (p.weightKg>0)
        [mWeight_kg setText:[NSString stringWithFormat:@"%d", p.weightKg]];

    if (p.heightCm>0)
        [mHeight_cm setText:[NSString stringWithFormat:@"%d", p.heightCm]];

    if (p.country)
        [mCountry setText:p.country];

    if (p.postalAddress)
        [mPostalAddress setText:p.postalAddress];

    if (p.emailAddress)
        [mEmail setText:p.emailAddress];

    if (p.phoneNumber)
        [mPhone setText:p.phoneNumber];

    if (p.uniqueId)
        mPatientUUID = p.uniqueId;

    if (p.gender) {
        if ([p.gender isEqualToString:KEY_AMK_PAT_GENDER_M])
            [mSex setSelectedSegmentIndex:0];
        else if ([p.gender isEqualToString:KEY_AMK_PAT_GENDER_F])
            [mSex setSelectedSegmentIndex:1];
    }
}

- (Patient *) getAllFields
{
    Patient *patient = [Patient new];
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
            patient.gender = KEY_AMK_PAT_GENDER_M;
            break;
        case 1:
            patient.gender = KEY_AMK_PAT_GENDER_F;
            break;
    }

    return patient;
}

- (void) friendlyNote:(NSString*)str
{
    [mNotification setText:str];
}

// Validate "required" fields
- (BOOL) validateFields:(Patient *)patient
{
    BOOL valid = TRUE;
    [self resetFieldsColors];
    UIColor *lightRed = [self getInvalidFieldColor];
    
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
    
    // The email is an optional field
    if (![self stringIsNilOrEmpty:patient.emailAddress] &&  // if used
        ![MLUtility emailValidator:patient.emailAddress])   // it must be valid
    {
        mEmail.backgroundColor = lightRed;
        valid = FALSE;
    }
    
    mPatientUUID = [patient generateUniqueID];
    
    return valid;
}

#ifdef DYNAMIC_BUTTONS
- (void) saveCancelOn
{
    self.navigationItem.leftBarButtonItems[0].enabled = NO;
    //self.navigationItem.leftBarButtonItems[2].enabled = YES;  // Cancel always enabled
    
    self.navigationItem.rightBarButtonItems[0].enabled = NO;
    self.navigationItem.rightBarButtonItems[2].enabled = YES;
}

- (void) saveCancelOff
{
    self.navigationItem.leftBarButtonItems[0].enabled = YES;
    //self.navigationItem.leftBarButtonItems[2].enabled = NO;
    
    self.navigationItem.rightBarButtonItems[0].enabled = YES;
    self.navigationItem.rightBarButtonItems[2].enabled = NO;
}
#endif

#pragma mark - UITextFieldDelegate

#ifdef DYNAMIC_BUTTONS
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self saveCancelOn];
}
#endif

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
#ifdef DEBUG
    //NSLog(@"%s tag:%ld", __FUNCTION__, textField.tag);
#endif
    if ((textField.tag == 6) ||     // country
        (textField.tag == 9) ||     // weight
        (textField.tag == 10) ||    // height
        (textField.tag == 11) ||    // phone
        (textField.tag == 12))      // email
    {
        return TRUE;  // Allow non mandatory fields to be empty
    }

    BOOL valid = TRUE;
    if ([textField.text isEqualToString:@""])
        valid = FALSE;

//    switch (textField.tag) {
//        case NameFieldTag: break;
//        case SurnameFieldTag: break;
//        case AddressFieldTag: break;
//        case CityFieldTag: break;
//        case ZIPFieldTag: break;
//        case DOBFieldTag: break;
//        case SexFieldTag: break;
//
//        default:
//            break;
//    }

    if (valid)
        textField.backgroundColor = [UIColor secondarySystemBackgroundColor];
    else
        textField.backgroundColor = [self getInvalidFieldColor];
    
    return valid;
}

#pragma mark - Actions

- (IBAction)myRightRevealToggle:(id)sender
{
    SWRevealViewController *revealController = [self revealViewController];

    // Check that the right controller class is ContactsListViewController
    UIViewController *vc_right = revealController.rightViewController;
    
#ifdef DEBUG
    NSLog(@"%s vc: %@", __FUNCTION__, [vc_right class]);
#endif
    
    if (![vc_right isKindOfClass:[ContactsListViewController class]] ) {
        // Replace right controller
        ContactsListViewController *contactsListViewController =
        [[ContactsListViewController alloc] initWithNibName:@"ContactsListViewController"
                                                       bundle:nil];
        [revealController setRightViewController:contactsListViewController];
        NSLog(@"Replaced right VC");
    }

#ifdef CONTACTS_LIST_FULL_WIDTH
    float frameWidth = self.view.frame.size.width;
    revealController.rightViewRevealWidth = frameWidth;
#endif
    
    if ([revealController frontViewPosition] == FrontViewPositionLeft)
        [revealController setFrontViewPosition:FrontViewPositionLeftSide animated:YES];
    else
        [revealController setFrontViewPosition:FrontViewPositionLeft animated:YES];  // Center
}

- (IBAction) handleCameraButton:(id)sender
{
    [self startCameraLivePreview];
}

- (IBAction) cancelPatient:(id)sender
{
#ifdef DEBUG
    //NSLog(@"%s", __FUNCTION__);
#endif
    [self resetAllFields];

#ifdef DYNAMIC_BUTTONS
    [self saveCancelOff];
#endif

    // Show list of patients from DB
    MLAppDelegate *appDel = (MLAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDel switchRigthToPatientDbList];
}

- (IBAction) savePatient:(id)sender
{
#ifdef DEBUG
    //NSLog(@"%s", __FUNCTION__);
#endif

    if (!mPatientDb) {
        NSLog(@"%s Patient DB is null", __FUNCTION__);
        return;
    }
    
    Patient *patient = [self getAllFields];
    if (![self validateFields:patient]) {
        NSLog(@"Patient field validation failed");
        return;
    }
    
#ifdef DEBUG
    //NSLog(@"before adding %@, count %ld", mPatientUUID, [mPatientDb getNumPatients]);
#endif
    
    if (mPatientUUID && [mPatientUUID length]>0)
        patient.uniqueId = mPatientUUID;
    
    NSString *note = NSLocalizedString(@"Contact was saved in the AmiKo address book", nil);
    
    if ([mPatientDb getPatientWithUniqueID:mPatientUUID]==nil)
        mPatientUUID = [mPatientDb addEntry:patient];       // insert into DB
    else {
        if (patient.uniqueId!=nil &&
            [patient.uniqueId length]>0)
        {
            note = NSLocalizedString(@"The entry has been updated", nil);
        }

        mPatientUUID = [mPatientDb insertEntry:patient];    // insert into DB or update
    }

    if (mPatientUUID==nil) {
#ifdef DEBUG
        NSLog(@"%s:%d Could not add/insert patient", __FUNCTION__, __LINE__);
#endif
        return;
    }
    
    [self friendlyNote:note];

#ifdef DYNAMIC_BUTTONS
    [self saveCancelOff];
#endif
    
#ifdef DEBUG
    //NSLog(@"patients after adding: %ld", [mPatientDb getNumPatients]);
#endif
    
    // Set as default patient for prescriptions
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:mPatientUUID forKey:@"currentPatient"];
    [defaults synchronize];
    
#ifdef DEBUG_ISSUE_86
    NSLog(@"%s %d define currentPatient ID %@", __FUNCTION__, __LINE__, mPatientUUID);
#endif
    
    // Create patient subdirectory for prescriptions
#if 0 //def DEBUG
    NSString *amkDir = [MLUtility amkDirectory];
    NSLog(@"amk subdirectory: %@", amkDir);
#else
    //[MLUtility amkDirectoryForPatient:mPatientUUID];
    [MLUtility amkDirectory];
#endif
    
    // Switch view
    MLAppDelegate *appDel = (MLAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDel.editMode == EDIT_MODE_PATIENTS) {
        [appDel performSelector:@selector(switchRigthToPatientDbList) withObject:nil afterDelay:1.0];
    }
    else if (appDel.editMode == EDIT_MODE_PRESCRIPTION) {
        UIViewController *nc = self.revealViewController.rearViewController;
        MLViewController *vc = [nc.childViewControllers firstObject];
        [vc switchToPrescriptionView];
    }
}

#pragma mark - Notifications

- (void)sexDefined:(NSNotification *)notification
{
    [self saveCancelOn];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGRect keyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];

    UIEdgeInsets contentInset = self.scrollView.contentInset;
    contentInset.bottom = keyboardRect.size.height;
    self.scrollView.contentInset = contentInset;
    self.scrollView.scrollIndicatorInsets = contentInset;
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    UIEdgeInsets contentInset = self.scrollView.contentInset;
    contentInset.bottom = 0;
    self.scrollView.contentInset = contentInset;
    scrollView.scrollIndicatorInsets = contentInset;
}

- (void)contactsListDidChangeSelection:(NSNotification *)aNotification
{
    Patient *p = [aNotification object];
#ifdef DEBUG
    //NSLog(@"%s selected familyName:%@", __FUNCTION__, p.familyName);
#endif
    
    [self resetAllFields];
    [self setAllFields:p];
    
    // TODO: Add contact to patient DB
    
    SWRevealViewController *revealController = self.revealViewController;
#if 1
    [revealController rightRevealToggleAnimated:YES];
#else
    [revealController setFrontViewPosition:FrontViewPositionLeftSideMost animated:YES];
#endif
}

@end
