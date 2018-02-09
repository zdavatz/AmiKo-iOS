//
//  MLPatientViewController.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 5 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MLPatient.h"

@interface MLPatientViewController : UIViewController <UITextFieldDelegate>
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

- (IBAction) savePatient:(id)sender;
- (IBAction) cancelPatient:(id)sender;

- (void)contactsListDidChangeSelection:(NSNotification *)aNotification;

@end
