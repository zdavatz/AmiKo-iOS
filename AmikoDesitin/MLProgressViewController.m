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

#import "MLConstants.h"

@implementation MLProgressViewController
{
    UIAlertView *mAlertView;
    UIAlertController *mAlertController;
    UIProgressView *mProgressBar;
}

@synthesize mDownloadInProgress;

- (id) init
{
    self = [super init];
    
    if (self) {
        {
            mAlertController = [UIAlertController
                                alertControllerWithTitle:@"Updating AIPS database"
                                message:@""
                                preferredStyle: UIAlertControllerStyleAlert];
            // float width = [mAlertController.view bounds].size.width;
            
            // Add cancel button
            UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil];
            [mAlertController addAction:cancel];
            
            // Add progress bar
            mProgressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
            UIViewController *v = [[UIViewController alloc] init];
            v.preferredContentSize = CGSizeMake(240, 20);
            [v.view addSubview:mProgressBar];
            [mProgressBar setFrame:CGRectMake(0, 0, 240, 20)];
            [mAlertController setValue:v forKey:@"contentViewController"];
        }
        
        mProgressBar.progress = 0.0;
    }
    
    return self;
}

- (void) setMessage:(NSString *)msg
{
    [mAlertController setMessage:msg];
}

- (void) start
{
    mDownloadInProgress = YES;

    // Get pointer to app delegate, its main window and eventually to the rootViewController
    UIViewController *presentingController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [presentingController presentViewController:mAlertController animated:YES completion:nil];
}

- (void) updateWith:(long)downloadedBytes andWith:(long)expectedBytes;
{
    float progress = 100*(float)downloadedBytes/expectedBytes;
    /*
     Given the blocking nature of the update mechanism we use a little trick here.
     We change the message before the unzipping does start.
    */
    if (progress<99) {
        [self setMessage:[NSString stringWithFormat:@"%d%% (%ldkb out of %ldkb)",
                                (int)(progress), downloadedBytes/1000, expectedBytes/1000]];
    } else {
        [self setMessage:[NSString stringWithFormat:@"Unzipping..."]];
    }
    if (mProgressBar!=nil)
        mProgressBar.progress = progress/100.0f;
}

- (void) remove
{
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [mAlertController dismissViewControllerAnimated:YES completion:nil];
        });
    }

    // Alternative in case the previous line causes a crash!
    // [mAlertView removeFromSuperview];
}

- (void) setCancelButtonTitle:(NSString *)title
{
    [mAlertController setTitle:@"Update cancelled!"];
}

#pragma mark - UIAlertViewDelegate

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == alertView.cancelButtonIndex) {
        mDownloadInProgress = NO;
	}
}

@end
