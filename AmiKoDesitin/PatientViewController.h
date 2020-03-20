//
//  PatientViewController.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 5 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "Patient.h"
#import "LegacyPatientDBAdapter.h"

@interface PatientViewController : UIViewController <UITextFieldDelegate, NSFetchedResultsControllerDelegate>
{
//    IBOutlet NSWindow *mPanel;
//    IBOutlet NSTableView *mTableView;
//    IBOutlet NSTextField *mNumPatients;
    IBOutlet UITextField *mNotification;
//    IBOutlet NSSearchField *mSearchKey;

    IBOutlet UITextField *mFamilyName;
    IBOutlet UITextField *mGivenName;
    IBOutlet UITextField *mBirthDate;
    IBOutlet UITextField *mWeight_kg;
    IBOutlet UITextField *mHeight_cm;
    IBOutlet UITextField *mZipCode;
    IBOutlet UITextField *mPostalAddress;
    IBOutlet UITextField *mCity;
    IBOutlet UITextField *mCountry;
    IBOutlet UITextField *mPhone;
    IBOutlet UITextField *mEmail;
    IBOutlet UISegmentedControl *mSex;
}

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

+ (PatientViewController *)sharedInstance;

- (IBAction) savePatient:(id)sender;
- (IBAction) cancelPatient:(id)sender;
- (IBAction) handleCameraButton:(id)sender;

- (IBAction) myRightRevealToggle:(id)sender;

- (void) setAllFields:(Patient *)p;
- (void) resetAllFields;
- (void) friendlyNote:(NSString*)str;

- (void)sexDefined:(NSNotification *)notification;
- (void)keyboardDidShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
- (void)contactsListDidChangeSelection:(NSNotification *)aNotification;

@end
