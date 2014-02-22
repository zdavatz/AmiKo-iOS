/*
 
 Copyright (c) 2014 Max Lungarella <cybrmx@gmail.com>
 
 Created on 14/02/2014.
 
 This file is part of AMiKoDesitin.
 
 AmiKoDesitin is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 
 ------------------------------------------------------------------------ */


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
        // Little trick
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
    float progress = 100*(float)downloadedBytes/expectedBytes;
    /*
     Given the blocking nature of the update mechanism we use a little trick here.
     We change the message before the unzipping does start.
    */
    if (progress<99) {
        [mAlertView setMessage:[NSString stringWithFormat:@"%d%% (%dkb out of %dkb)",
                                (int)(progress), downloadedBytes/1000, expectedBytes/1000]];
    } else {
        [mAlertView setMessage:[NSString stringWithFormat:@"Unzipping..."]];
    }
    if (mProgressBar!=nil)
        mProgressBar.progress = progress/100.0f;
}

- (void) remove
{
    /*
    for (UIWindow* window in [UIApplication sharedApplication].windows) {
        NSArray* subviews = window.subviews;
        if ([subviews count] > 0)
            if ([[subviews objectAtIndex:0] isKindOfClass:[UIAlertView class]])
                [(UIAlertView *)[subviews objectAtIndex:0] dismissWithClickedButtonIndex:[(UIAlertView *)[subviews objectAtIndex:0] cancelButtonIndex] animated:NO];
    }
    */
    [mAlertView dismissWithClickedButtonIndex:-1 animated:NO];
    // Alternative in case the previous line causes a crash!
    // [mAlertView removeFromSuperview];
}

- (void) setCancelButtonTitle:(NSString *)title
{
    [mAlertView setTitle:@"Update cancelled!"];
}

#pragma mark - UIAlertViewDelegate

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == alertView.cancelButtonIndex) {
        mDownloadInProgress = NO;
	}
}

@end
