//
//  DoctorViewController.m
//  AmiKoDesitin
//
//  Created by Alex Bettarini on 5 Mar 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "DoctorViewController.h"
#import "SWRevealViewController.h"
#import "MLUtility.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "MLPersistenceManager.h"
#import "MLUbiquitousStateAlertController.h"

@interface DoctorViewController () <NSFilePresenter>

@property (nonatomic, strong) Operator *doctor;
@property (nonatomic, strong) NSMetadataQuery *query;
@property (nonatomic, strong) MLUbiquitousStateAlertController *ubiquitousController;

- (BOOL) stringIsNilOrEmpty:(NSString*)str;
- (BOOL) validateFields:(Operator *)doctor;
- (void) resetFieldsColors;
- (void) saveDoctor;

@end

#pragma mark -

@implementation DoctorViewController

@synthesize signatureView;
@synthesize scrollView;

- (instancetype)init {
    if (self = [super initWithNibName:@"DoctorViewController" bundle:nil]) {
        self.query = [[NSMetadataQuery alloc] init];
        self.query.searchScopes = @[NSMetadataQueryUbiquitousDocumentsScope];
        self.query.predicate = [NSPredicate predicateWithFormat:@"%K == %@ OR %K == %@",
                                NSMetadataItemURLKey,
                                [[MLPersistenceManager shared] doctorDictionaryURL],
                                NSMetadataItemURLKey,
                                [[MLPersistenceManager shared] doctorSignatureURL]];
        self.query.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"lastPathComponent" ascending:NO]];
        [self.query startQuery];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(reloadUIForDoctor) name:NSMetadataQueryDidUpdateNotification object:self.query];
    }
    return self;
}

- (void)dealloc {
    [NSFileCoordinator removeFilePresenter:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    SWRevealViewController *revealController = [self revealViewController];

    self.navigationItem.title = NSLocalizedString(@"Doctor", nil);      // grey, in the navigation bar

    // Left button(s)
    UIBarButtonItem *revealButtonItem =
    [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:NAVIGATION_ICON_LEFT]
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
                                    action:@selector(saveDoctorAndClose:)];
    saveItem.enabled = NO;
    self.navigationItem.rightBarButtonItem = saveItem;

    scrollView.bounces = NO;
    
    // Register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    MLUbiquitousStateAlertController *controller = [[MLUbiquitousStateAlertController alloc] initWithUbiquitousItem:[[MLPersistenceManager shared] doctorDictionaryURL]];
    if (controller != nil) {
        controller.onDone = ^{
            [self reloadUIForDoctor];
            self.ubiquitousController = nil;
        };
        controller.onError = ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                           message:NSLocalizedString(@"Cannot get file from iCloud", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            self.ubiquitousController = nil;
        };
        [controller presentAt:self];
        self.ubiquitousController = controller;
    }
}

#ifdef DEBUG
- (void) viewDidAppear:(BOOL)animated
{
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"gestureRecognizers:%ld %@", [[self.view gestureRecognizers] count], [self.view gestureRecognizers]);
}
#endif

- (void) viewWillAppear:(BOOL)animated
{
    if ([[self.view gestureRecognizers] count] == 0)
        [self.view addGestureRecognizer:[self revealViewController].panGestureRecognizer];
    
    if (![[NSFileCoordinator filePresenters] containsObject:self]) {
        [NSFileCoordinator addFilePresenter:self];
    }
    [self reloadUIForDoctor];
}

- (void)reloadUIForDoctor {
    NSDictionary *doctorDictionary = [[MLPersistenceManager shared] doctorDictionary];
    if (!doctorDictionary) {
        NSLog(@"Default doctor signature not defined");
        [self.signatureView.layer setBorderColor: [[UIColor labelColor] CGColor]];
        [self.signatureView.layer setBorderWidth: 2.0];
        return;
    }

    self.doctor = [Operator new];
    [self.doctor importFromDict:doctorDictionary];
    [self setAllFields:self.doctor];

    if ([self.doctor importSignatureFromFile]) {
        self.signatureView.image = [self.doctor thumbnailFromSignature:self.signatureView.frame.size];
    }
    else {
        NSLog(@"Default doctor signature not yet defined");
        // Make the picture area stand out with a border
        [self.signatureView.layer setBorderColor: [[UIColor labelColor] CGColor]];
        [self.signatureView.layer setBorderWidth: 2.0];
    }
    Operator *newDoctor = [self getAllFields];
    [self validateFields:newDoctor];
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

- (UIColor *)getInvalidFieldColor
{
    return [[UIColor systemRedColor] colorWithAlphaComponent:0.3];
}

- (BOOL) stringIsNilOrEmpty:(NSString*)str
{
    return !(str && str.length);
}

- (void) resetFieldsColors
{
    mGivenName.backgroundColor =
    mFamilyName.backgroundColor =
    mPostalAddress.backgroundColor =
    mCity.backgroundColor =
    mZipCode.backgroundColor =
    mPhone.backgroundColor =
    mEmail.backgroundColor =
    mZsrNumber.backgroundColor =
    mGln.backgroundColor = [UIColor secondarySystemBackgroundColor];
}

- (void) setAllFields:(Operator *)p
{
    if (p.title)
        [mTitle setText:p.title];
    
    if (p.givenName)
        [mGivenName setText:p.givenName];
    
    if (p.familyName)
        [mFamilyName setText:p.familyName];
    
    if (p.gln) {
        [mGln setText:p.gln];
    }
    
    if (p.zsrNumber) {
        [mZsrNumber setText:p.zsrNumber];
    }
    
    if (p.city)
        [mCity setText:p.city];
    
    if (p.zipCode)
        [mZipCode setText:p.zipCode];
    
    if (p.postalAddress)
        [mPostalAddress setText:p.postalAddress];
    
    if (p.phoneNumber)
        [mPhone setText:p.phoneNumber];
    
    if (p.emailAddress)
        [mEmail setText:p.emailAddress];
    
}

- (Operator *) getAllFields
{
    Operator *doctor = [Operator new];
    
    doctor.title = [mTitle text];
    doctor.givenName = [mGivenName text];
    doctor.familyName = [mFamilyName text];
    doctor.gln = [mGln text];
    doctor.zsrNumber = [mZsrNumber text];
    doctor.city = [mCity text];
    doctor.zipCode = [mZipCode text];
    doctor.postalAddress = [mPostalAddress text];
    doctor.phoneNumber = [mPhone text];
    doctor.emailAddress = [mEmail text];
    
    return doctor;
}

// Validate "required" fields
- (BOOL) validateFields:(Operator *)doctor
{
    BOOL valid = TRUE;
    UIColor *lightRed = [self getInvalidFieldColor];
    
    [self resetFieldsColors];
    
    if ([self stringIsNilOrEmpty:doctor.givenName]) {
        mGivenName.backgroundColor = lightRed;
        valid = FALSE;
    }

    if ([self stringIsNilOrEmpty:doctor.familyName]) {
        mFamilyName.backgroundColor = lightRed;
        valid = FALSE;
    }
    
    if ([self stringIsNilOrEmpty: doctor.gln] ||
        [doctor.gln length] != 13 ||
        ![[@([doctor.gln integerValue]) stringValue] isEqual:doctor.gln]) {
        mGln.backgroundColor = lightRed;
        valid = FALSE;
    }
    
    if (![self stringIsNilOrEmpty:doctor.zsrNumber]) {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[a-zA-Z][0-9]{6}$" options:0
                                                                                 error:nil];
        NSTextCheckingResult *result = [regex firstMatchInString:doctor.zsrNumber options:0 range:NSMakeRange(0, doctor.zsrNumber.length)];
        if (!result) {
            mZsrNumber.backgroundColor = lightRed;
            valid = FALSE;
        }
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
    
    // The email is a required field
    if ([self stringIsNilOrEmpty:doctor.emailAddress] ||    // must be there
        ![MLUtility emailValidator:doctor.emailAddress])    // must be valid
    {
        mEmail.backgroundColor = lightRed;
        valid = FALSE;
    }

    BOOL hinLoggedIn = [[MLPersistenceManager shared] HINSDSTokens] != nil || [[MLPersistenceManager shared] HINADSwissTokens] != nil;
    // Validate photo
    if (!self.signatureView.image && !hinLoggedIn) {
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
    BOOL valid = TRUE;
    if ([textField.text isEqualToString:@""])
        valid = FALSE;
    
    if (valid)
        textField.backgroundColor = [UIColor secondarySystemBackgroundColor];
    else
        textField.backgroundColor = [self getInvalidFieldColor];
    
    return valid;
}

#pragma mark - Actions

- (IBAction) saveDoctorAndClose:(id)sender {
    Operator *newDoctor = [self getAllFields];
    if (![self validateFields:newDoctor]) {
        return;
    }
    [self saveDoctor];
    // Back to main screen
    [[self revealViewController] revealToggle:nil];
}
- (IBAction) saveDoctor
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    
    Operator *newDoctor = [self getAllFields];
    if (![self validateFields:newDoctor]) {
        NSLog(@"Doctor field validation failed");
        return;
    }

    NSDictionary *doctorDict = [self.doctor toDictionary];
    NSDictionary *newDoctorDict = [newDoctor toDictionary];
    if ([doctorDict isEqualToDictionary:newDoctorDict]) {
        return;
    } else {
        self.doctor = newDoctor;
    }
#ifdef DEBUG
    NSLog(@"newDoctorDict: %@", newDoctorDict);
#endif

    [[MLPersistenceManager shared] setDoctorDictionary:newDoctorDict];
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

    UIImagePickerController *picker = [UIImagePickerController new];
    picker.delegate = self;

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
    
    UIImagePickerController *picker = [UIImagePickerController new];
    picker.delegate = self;

    //picker.navigationBarHidden = NO;
    //picker.wantsFullScreenLayout = NO;

    //picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;  // all folders in gallery
    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum; // camera roll
    
    [self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark - File system

- (NSURL *)presentedItemURL {
    return [[MLPersistenceManager shared] doctorDictionaryURL];
}

- (NSOperationQueue *)presentedItemOperationQueue {
    return [NSOperationQueue mainQueue];
}

- (void)savePresentedItemChangesWithCompletionHandler:(void (^)(NSError *errorOrNil))completionHandler {
    [self saveDoctor];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        completionHandler(nil);
    });
}

- (void)presentedItemDidChange {
    NSDictionary *dict = [[MLPersistenceManager shared] doctorDictionary];
    [self.doctor importFromDict:dict];
    [self setAllFields:self.doctor];
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
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
#if 0
    // If we want to keep the image for future use:
    // check if the image originated from the camera, store it in the photo album
    // this require NSAppleMusicUsageDescription in Info.plist
    UIImage *referenceURL = info[UIImagePickerControllerReferenceURL];
    if (!referenceURL) // nil if coming from camera
        UIImageWriteToSavedPhotosAlbum(chosenImage, nil, nil, nil);
#endif

    // First resize it to 20% for the PNG file

    // Resize to 20% for doctor's profile (PNG file in Documents directory) and for AMK
    CGSize sizeScaled = CGSizeMake(chosenImage.size.width*0.2, chosenImage.size.height*0.2);
    // Note that a scale parameter of 0.0 means using [UIScreen mainScreen].scale and
    // ending up with a PNG file with x2 dimensions if the device is a retina display
    CGFloat scale = 1.0;
    UIGraphicsBeginImageContextWithOptions(sizeScaled, NO, scale);
    [chosenImage drawInRect:CGRectMake(0, 0, sizeScaled.width, sizeScaled.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Save to PNG file
    [MLPersistenceManager shared].doctorSignature = scaledImage;

    // Resize to signatureView frame for thumbnail
    CGSize sizeTN = self.signatureView.frame.size;
    UIGraphicsBeginImageContextWithOptions(sizeTN, NO, 0.0);
    [chosenImage drawInRect:CGRectMake(0, 0, sizeTN.width, sizeTN.height)];
    UIImage *thumbnailImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
#ifdef DEBUG
    NSLog(@"thumbnailImage %@", NSStringFromCGSize(thumbnailImage.size));
#endif

    // Show it
    self.signatureView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.signatureView.image = thumbnailImage;
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
