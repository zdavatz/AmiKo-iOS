/*
 
 Copyright (c) 2014 Max Lungarella <cybrmx@gmail.com>
 
 Created on 14/02/2014.
 
 This file is part of AmiKoDesitin.
 
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
    UIAlertController *mAlertController;
    UIProgressView *mProgressBar;
}

- (id) init
{
    self = [super init];
    
    if (self) {
        {
            NSDictionary *d = [[NSBundle mainBundle] infoDictionary];
            NSString *bundleName = [d objectForKey:@"CFBundleName"];
            NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Updating %@ database", nil), bundleName];

            mAlertController = [UIAlertController
                                alertControllerWithTitle:title
                                message:@""
                                preferredStyle: UIAlertControllerStyleAlert];
            // float width = [mAlertController.view bounds].size.width;
            
#if 0 // ISSUE_108
            // Add cancel button
            UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                             style:UIAlertActionStyleDefault
                                                           handler:nil];  // TODO: define handler that sets class variable
            [mAlertController addAction:cancel];
#endif
            
            // Add progress bar
            mProgressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
            UIViewController *v = [UIViewController new];
            v.preferredContentSize = CGSizeMake(240, 20);
            [v.view addSubview:mProgressBar];
            [mProgressBar setFrame:CGRectMake(0, 0, 240, 20)];
            [mAlertController setValue:v forKey:@"contentViewController"];
        }
        
        mProgressBar.progress = 0.0;
    }
    
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void) setMessage:(NSString *)msg
{
    [mAlertController setMessage:msg];
}

- (void) start
{
    self.mDownloadInProgress = YES;

    // Get pointer to app delegate, its main window and eventually to the rootViewController
    UIViewController *presentingController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [presentingController presentViewController:mAlertController animated:YES completion:nil];
}

- (void) updateWith:(long)downloadedBytes
            andWith:(long)expectedBytes;
{
    float progress = 100.0f * (float)downloadedBytes / (float)expectedBytes;
    //NSLog(@"%s %d progress: %f", __FUNCTION__, __LINE__, progress);
    //if (progress < 99)
    {
        [self setMessage:[NSString stringWithFormat:@"%ld MiB of %ld MiB\n%d%% ",
                          (long)(downloadedBytes/(1024*1024)),
                          (long)(expectedBytes/(1024*1024)),
                          (int)progress]];
    }
#if 0  // This is not accurate
    else {
        /*
         Given the blocking nature of the update mechanism we use a little trick here.
         We change the message before the unzipping does start.
        */
        [self setMessage:@"Unzipping..."];
    }
#endif

    if (mProgressBar)
        mProgressBar.progress = progress/100.0f;
    
    if (progress == 100)
        [self setMessage:NSLocalizedString(@"Reinitializing DB...", nil)];
}

- (void) remove
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->mAlertController dismissViewControllerAnimated:YES completion:nil];
    });

    // Alternative in case the previous line causes a crash!
    // [mAlertView removeFromSuperview];
}

- (void) setCancelButtonTitle:(NSString *)title
{
    [mAlertController setTitle:@"Update cancelled!"];
}

@end
