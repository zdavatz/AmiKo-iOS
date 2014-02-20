//
//  MLProgressViewController.m
//  AmikoDesitin
//
//  Created by Max on 19/02/2014.
//  Copyright (c) 2014 Ywesee GmbH. All rights reserved.
//

#import "MLProgressViewController.h"

@implementation MLProgressViewController
{
    UIAlertView *mAlertView;
    UIProgressView *mProgressBar;
}

@synthesize mDownloadInProgress;

- (id) init
{
    self = [super init];
    
    if (self) {
        mAlertView = [[UIAlertView alloc] initWithTitle:@"Updating AIPS database"
                                                message:@""
                                               delegate:self
                                      cancelButtonTitle:@"Cancel"
                                      otherButtonTitles:nil];
        
        mAlertView.tag = 1;
        
        mProgressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        
        UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 160, 30)];
        [v addSubview:mProgressBar];
        [mAlertView setValue:v forKey:@"accessoryView"];
        mProgressBar.progress = 0.0;
    }
    
    return self;
}

- (void) setMessage:(NSString *)msg
{
    [mAlertView setMessage:msg];
}

- (void) start
{
    mDownloadInProgress = YES;
    [mAlertView show];
}

- (void) updateWith:(int)downloadedBytes andWith:(int)expectedBytes;
{
    float progress = (float)downloadedBytes/expectedBytes;
    [mAlertView setMessage:[NSString stringWithFormat:@"%d%% (%dkb out of %dkb)",
                            (int)(100*progress), downloadedBytes/1000, expectedBytes/1000]];
    if (mProgressBar!=nil)
        mProgressBar.progress = progress;
}

- (void) remove
{
    [mAlertView dismissWithClickedButtonIndex:-1 animated:NO];
    // Alternative in case the previous line causes a crash!
    // [mAlertView removeFromSuperview];
}

- (void) setCancelButtonTitle:(NSString *)title
{
    [mAlertView setTitle:@"Update cancelled!"];
}

/*
 UIAlertViewDelegate implements
 */
- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == alertView.cancelButtonIndex) {
        mDownloadInProgress = NO;
	}
}

@end
