//
//  MLDoctorViewController.h
//  AmiKoDesitin
//
//  Created by Alex Bettarini on 5 Mar 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    TitleFieldTag,
    NameFieldTag,
    SurnameFieldTag,
    AddressFieldTag,
    CityFieldTag,
    ZIPFieldTag
};

@interface MLDoctorViewController : UIViewController <UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, retain) IBOutlet UIImageView *signatureView;

+ (MLDoctorViewController *)sharedInstance;

- (IBAction) saveDoctor:(id)sender;
- (IBAction) handleSignature:(id)sender;

@end
