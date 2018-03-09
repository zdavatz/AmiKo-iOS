//
//  MLDoctorViewController.h
//  AmiKoDesitin
//
//  Created by Alex Bettarini on 5 Mar 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MLOperator.h"

enum {
    TitleFieldTag,
    NameFieldTag,
    SurnameFieldTag,
    AddressFieldTag,
    CityFieldTag,
    ZIPFieldTag
};

@interface MLDoctorViewController : UIViewController <UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    IBOutlet UITextField *mTitle;
    IBOutlet UITextField *mGivenName;
    IBOutlet UITextField *mFamilyName;
    IBOutlet UITextField *mPostalAddress;
    IBOutlet UITextField *mCity;
    IBOutlet UITextField *mZipCode;
    IBOutlet UITextField *mPhone;
    IBOutlet UITextField *mEmail;
}

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIImageView *signatureView;

+ (MLDoctorViewController *)sharedInstance;

- (IBAction) saveDoctor:(id)sender;
- (IBAction) signWithSelfie:(id)sender;
- (IBAction) signWithPhoto:(id)sender;

- (void) setAllFields:(MLOperator *)p;

- (void)keyboardDidShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;

@end
