//
//  MLMainMenuViewController.m
//  AmikoDesitin
//
//  Created by Max on 10/02/2014.
//  Copyright (c) 2014 Ywesee GmbH. All rights reserved.
//

#import "MLMenuViewController.h"
#import "MLConstants.h"
#import "MLCustomURLConnection.h"

#import "SWRevealViewController.h"

@interface MLMenuViewController ()

@end

@implementation MLMenuViewController
{
    NSArray *options;
    MLViewController *mParentViewController;
    UIActionSheet *mMenuActionSheet;
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil parent:(MLViewController *)parentViewController
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
 
    mParentViewController = parentViewController;
    
    if (self) {
        // To stuff...
    }
    
    return self;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    
    [mMenuActionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (void) viewDidLoad
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    
    [super viewDidLoad];
    
    if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad) {
    
        // SWRevealViewController extends UIViewController!
        SWRevealViewController *revealController = [self revealViewController];
       
        /*
        UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                                                         style:UIBarButtonItemStyleBordered
                                                                        target:revealController
                                                                        action:@selector(revealToggle:)];
        self.navigationItem.leftBarButtonItem = revealButtonItem;
        */
        
        // PanGestureRecognizer goes here
        [self.navigationController.navigationBar addGestureRecognizer:revealController.panGestureRecognizer];
        [self.view addGestureRecognizer:revealController.panGestureRecognizer];
    
        // Single tap gesture recognizer goes here
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(handleSingleTap:)];
        singleTap.numberOfTapsRequired = 1;
        singleTap.delegate = self;
        [self.view addGestureRecognizer:singleTap];
        
        [self.navigationController.navigationBar setHidden:YES];
    }    
}

#pragma mark Delegate methods

// UIGestureRecognizerDelegate
- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void) handleSingleTap:(UITapGestureRecognizer*)gesture
{
    SWRevealViewController *revealController = [self revealViewController];
    [revealController revealToggle:self];
}

- (void) showMenu:(MLViewController*)parentViewController
{
    mParentViewController = parentViewController;
    
    mMenuActionSheet = [[UIActionSheet alloc] initWithTitle:@"Select menu option"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Report", @"Update", @"Share", @"Rate", @"Feedback", nil];
    mMenuActionSheet.tag = 1;
    
    [mMenuActionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
    [mMenuActionSheet showInView:[parentViewController view]];
}

- (void) actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (sheet.tag) {
        case 1: {
            switch (buttonIndex) {
                case 0:
                    [self showReport:@"Report"];
                    break;
                case 1:
                    [self startUpdate:@"Update"];
                    break;
                case 2:
                    NSLog(@"Share");
                    break;
                case 3:
                    NSLog(@"Rate");
                    break;
                case 4:
                    NSLog(@"Feedback");
                    break;
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

- (IBAction) showReport:(id)sender
{
    NSLog(@"Report");
    if (mParentViewController!=nil) {
        [mParentViewController myIconPressMethod:self];
    }
}

- (IBAction) startUpdate:(id)sender
{
    NSLog(@"Update");
    MLCustomURLConnection *reportConn = [[MLCustomURLConnection alloc] init];
    MLCustomURLConnection *dbConn = [[MLCustomURLConnection alloc] init];

    if ([APP_NAME isEqualToString:@"iAmiKo"] || [APP_NAME isEqualToString:@"AmiKoDesitin"]) {
        [reportConn downloadFileWithName:@"amiko_report_de.html" andModal:NO];
        [dbConn downloadFileWithName:@"amiko_db_full_idx_de.zip" andModal:YES];
    } else if ([APP_NAME isEqualToString:@"iCoMed"] || [APP_NAME isEqualToString:@"CoMedDesitin"]) {
        [reportConn downloadFileWithName:@"amiko_report_fr.html" andModal:NO];
        [dbConn downloadFileWithName:@"amiko_db_full_idx_fr.zip" andModal:YES];
    } else {
        // Do nothing
    }
}

- (IBAction) shareApp:(id)sender
{
    NSLog(@"Share");
}

- (IBAction) rateApp:(id)sender
{
    NSLog(@"Rate");
}

- (IBAction) sendFeedback:(id)sender
{
    NSLog(@"Feedback");
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
