//
//  MLMainMenuViewController.h
//  AmikoDesitin
//
//  Created by Max on 10/02/2014.
//  Copyright (c) 2014 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "MLViewController.h"

@interface MLMenuViewController : UIViewController <UIActionSheetDelegate, UIGestureRecognizerDelegate, MFMailComposeViewControllerDelegate>

- (IBAction) showReport:(id)sender;
- (IBAction) startUpdate:(id)sender;
- (IBAction) shareApp:(id)sender;
- (IBAction) rateApp:(id)sender;
- (IBAction) sendFeedback:(id)sender;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil parent:(MLViewController*)parentViewController;
- (void) showMenu:(MLViewController*)parentViewController;

@end
