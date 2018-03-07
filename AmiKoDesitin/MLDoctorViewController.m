//
//  MLDoctorViewController.m
//  AmiKoDesitin
//
//  Created by Alex Bettarini on 5 Mar 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLDoctorViewController.h"
#import "SWRevealViewController.h"
#import "MLUtility.h"
#import <MobileCoreServices/MobileCoreServices.h>

//#define SELFIE_EDIT_MODE

@interface MLDoctorViewController ()

- (BOOL) stringIsNilOrEmpty:(NSString*)str;
- (BOOL) validateFields:(MLOperator *)doctor;
- (void) resetFieldsColors;

@end

#pragma mark -

@implementation MLDoctorViewController

@synthesize signatureView;
@synthesize scrollView;

+ (MLDoctorViewController *)sharedInstance
{
    __strong static id sharedObject = nil;
    
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    SWRevealViewController *revealController = [self revealViewController];
    
    [self.view addGestureRecognizer:revealController.panGestureRecognizer];
    
    self.navigationItem.title = NSLocalizedString(@"Doctor", nil);
    
    // Left button(s)
    UIBarButtonItem *revealButtonItem =
    [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                     style:UIBarButtonItemStylePlain
                                    target:revealController
                                    action:@selector(revealToggle:)];
    
    // A single button on the left
    self.navigationItem.leftBarButtonItem = revealButtonItem;
    
    // Right button(s)
    UIBarButtonItem *saveItem =
    [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", nil)
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(saveDoctor:)];
    saveItem.enabled = NO;
    self.navigationItem.rightBarButtonItem = saveItem;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) stringIsNilOrEmpty:(NSString*)str
{
    return !(str && str.length);
}

- (void) resetFieldsColors
{
    mGivenName.backgroundColor = nil;
    mFamilyName.backgroundColor = nil;
    mPostalAddress.backgroundColor = nil;
    mCity.backgroundColor = nil;
    mZipCode.backgroundColor = nil;
    mPhone.backgroundColor = nil;
    mEmail.backgroundColor = nil;
}

- (void) checkFields
{
    UIColor *lightRed = [UIColor colorWithRed:1.0
                                        green:0.0
                                         blue:0.0
                                        alpha:0.3];
    [self resetFieldsColors];
    
    if ([self stringIsNilOrEmpty:[mGivenName text]])
        mGivenName.backgroundColor = lightRed;
    
    if ([self stringIsNilOrEmpty:[mFamilyName text]])
        mFamilyName.backgroundColor = lightRed;
    
    if ([self stringIsNilOrEmpty:[mPostalAddress text]])
        mPostalAddress.backgroundColor = lightRed;
    
    if ([self stringIsNilOrEmpty:[mCity text]])
        mCity.backgroundColor = lightRed;
    
    if ([self stringIsNilOrEmpty:[mZipCode text]])
        mZipCode.backgroundColor = lightRed;
    
    if ([self stringIsNilOrEmpty:[mPhone text]])
        mPhone.backgroundColor = lightRed;
    
    if ([self stringIsNilOrEmpty:[mEmail text]])
        mEmail.backgroundColor = lightRed;
}

- (MLOperator *) getAllFields
{
    MLOperator *doctor = [[MLOperator alloc] init];
    
    doctor.title = [mTitle text];
    doctor.givenName = [mGivenName text];
    doctor.familyName = [mFamilyName text];
    doctor.city = [mCity text];
    doctor.zipCode = [mZipCode text];
    doctor.postalAddress = [mPostalAddress text];
    doctor.phoneNumber = [mPhone text];
    doctor.emailAddress = [mEmail text];
    
    return doctor;
}

// Validate "required" fields
- (BOOL) validateFields:(MLOperator *)doctor
{
    BOOL valid = TRUE;
    UIColor *lightRed = [UIColor colorWithRed:1.0
                                        green:0.0
                                         blue:0.0
                                        alpha:0.3];
    
    [self resetFieldsColors];
    
    if ([self stringIsNilOrEmpty:doctor.givenName]) {
        mGivenName.backgroundColor = lightRed;
        valid = FALSE;
    }

    if ([self stringIsNilOrEmpty:doctor.familyName]) {
        mFamilyName.backgroundColor = lightRed;
        valid = FALSE;
    }
    
    if ([self stringIsNilOrEmpty:doctor.postalAddress]) {
        mPostalAddress.backgroundColor = lightRed;
        valid = FALSE;
    }
    
    if ([self stringIsNilOrEmpty:doctor.city]) {
        mCity.backgroundColor = lightRed;
        valid = FALSE;
    }
    
    if ([self stringIsNilOrEmpty:doctor.zipCode]) {
        mZipCode.backgroundColor = lightRed;
        valid = FALSE;
    }
    
    if ([self stringIsNilOrEmpty:doctor.phoneNumber]) {
        mPhone.backgroundColor = lightRed;
        valid = FALSE;
    }
    
    if ([self stringIsNilOrEmpty:doctor.emailAddress]) {
        // TODO:  check at least that it is like *@*
        mEmail.backgroundColor = lightRed;
        valid = FALSE;
    }

    // Validate photo
    if (!self.signatureView.image) {
        self.signatureView.backgroundColor = lightRed;
        valid = FALSE;
    }

    return valid;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.navigationItem.rightBarButtonItems[0].enabled = YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
#ifdef DEBUG
    //NSLog(@"%s tag:%ld", __FUNCTION__, textField.tag);
#endif
    UIColor *lightRed = [UIColor colorWithRed:1.0
                                        green:0.0
                                         blue:0.0
                                        alpha:0.3];
    BOOL valid = TRUE;
    if ([textField.text isEqualToString:@""])
        valid = FALSE;
    
    if (valid)
        textField.backgroundColor = nil;
    else
        textField.backgroundColor = lightRed;
    
    return valid;
}

#pragma mark - Actions

- (IBAction) saveDoctor:(id)sender
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    
    MLOperator *doctor = [self getAllFields];
    if (![self validateFields:doctor]) {
        NSLog(@"Doctor field validation failed");
        return;
    }
    
    // Set as default for prescriptions
    NSMutableDictionary *doctorDict = [[NSMutableDictionary alloc] init];
    [doctorDict setObject:mTitle.text forKey:@"title"];
    [doctorDict setObject:mGivenName.text forKey:@"name"];
    [doctorDict setObject:mFamilyName.text forKey:@"surname"];
    [doctorDict setObject:mPostalAddress.text forKey:@"address"];
    [doctorDict setObject:mCity.text forKey:@"city"];
    [doctorDict setObject:mZipCode.text forKey:@"zip"];
    [doctorDict setObject:mPhone.text forKey:@"phone"];
    [doctorDict setObject:mEmail.text forKey:@"email"];

#ifdef DEBUG
    NSLog(@"doctorDict: %@", doctorDict);
#endif

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:doctorDict forKey:@"currentDoctor"];
    [defaults synchronize];
    
    // Back to main screen
    [[self revealViewController] revealToggle:nil];
}

- (IBAction) signWithSelfie:(id)sender
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        NSLog(@"Camera not available");
        return;
    }

    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
#ifdef SELFIE_EDIT_MODE
    picker.allowsEditing = YES;
#endif
    //picker.navigationBarHidden = NO;
    //picker.wantsFullScreenLayout = NO;

    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.mediaTypes = @[(NSString *) kUTTypeImage];
    //picker.mediaTypes = @[(NSString *) kUTTypeImage, (NSString *) kUTTypeLivePhoto];
    picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    //picker.showsCameraControls = NO;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (IBAction) signWithPhoto:(id)sender
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        NSLog(@"Photo library not available");
        return;
    }
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
#ifdef SELFIE_EDIT_MODE
    picker.allowsEditing = YES;
#endif
    //picker.navigationBarHidden = NO;
    //picker.wantsFullScreenLayout = NO;

    //picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;  // all folders in gallery
    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum; // camera roll
    
    [self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark - Notifications

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

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
#ifdef DEBUG
    //NSLog(@"%s %@", __FUNCTION__, info);
#endif
    
#ifdef SELFIE_EDIT_MODE
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
#else
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
#endif
    //NSLog(@"chosenImage %@", NSStringFromCGSize(chosenImage.size));
    
    // TODO: first resize it for the PNG file, then resize even smaller for the view

#if 0
    // If we want to keep the image for future use:
    // check if the image originated from the camera, store it in the photo album
    // this require NSAppleMusicUsageDescription in Info.plist
    UIImage *referenceURL = info[UIImagePickerControllerReferenceURL];
    if (!referenceURL) // nil if coming from camera
        UIImageWriteToSavedPhotosAlbum(chosenImage, nil, nil, nil);
#endif
    
    // Resize
    CGSize size = self.signatureView.frame.size;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [chosenImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //NSLog(@"smallImage %@", NSStringFromCGSize(smallImage.size));

    // Save to PNG file
    NSString *documentsDirectory = [MLUtility documentsDirectory];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"op_signature.png"];
    [UIImagePNGRepresentation(smallImage) writeToFile:filePath atomically:YES];

    // Show it
    self.signatureView.backgroundColor = nil;
    self.signatureView.image = smallImage;
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
