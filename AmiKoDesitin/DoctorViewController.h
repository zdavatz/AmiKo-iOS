//
//  DoctorViewController.h
//  AmiKoDesitin
//
//  Created by Alex Bettarini on 5 Mar 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Operator.h"

enum {
    TitleFieldTag,
    NameFieldTag,
    SurnameFieldTag,
    AddressFieldTag,
    CityFieldTag,
    ZIPFieldTag
};

@interface DoctorViewController : UIViewController <UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    IBOutlet UITextField *mTitle;
    IBOutlet UITextField *mGivenName;
    IBOutlet UITextField *mFamilyName;
    IBOutlet UITextField *mPostalAddress;
    IBOutlet UITextField *mCity;
    IBOutlet UITextField *mZipCode;
    IBOutlet UITextField *mPhone;
    IBOutlet UITextField *mEmail;
    __weak IBOutlet UITextField *mZsrNumber;
    __weak IBOutlet UITextField *mGln;
}

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIImageView *signatureView;

- (IBAction) signWithSelfie:(id)sender;
- (IBAction) signWithPhoto:(id)sender;

- (void) setAllFields:(Operator *)p;

- (void)keyboardDidShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;

@end
