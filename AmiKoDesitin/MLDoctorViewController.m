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

@interface MLDoctorViewController ()

@end

#pragma mark -

@implementation MLDoctorViewController

@synthesize signatureView;

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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    // TODO: set as default for prescriptions
    
    // Back to main screen
    [[self revealViewController] revealToggle:nil];
}

// Take selfie or choose file
- (IBAction) handleSignature:(id)sender
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
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    
    // Resize
    CGSize size = self.signatureView.frame.size;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [chosenImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Save to PNG file
    NSString *documentsDirectory = [MLUtility documentsDirectory];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"op_signature.png"];
    [UIImagePNGRepresentation(smallImage) writeToFile:filePath atomically:YES];

    // Show it
    self.signatureView.image = smallImage;
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
