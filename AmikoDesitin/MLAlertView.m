/*
 
 Copyright (c) 2015 Max Lungarella <cybrmx@gmail.com>
 
 Created on 21/02/2015.
 
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

#import "MLAlertView.h"

#import "MLConstants.h"

@implementation MLAlertView
{
    UIAlertView *mAlertView;
    UIAlertController *mAlertController;
    UIAlertAction *mButton;
}

/** Instance functions
 */
- (instancetype) initWithTitle: (NSString *)alertTitle message: (NSString *)message button: (NSString *)buttonTitle
{
    if ([MLConstants iosVersion]>=8.0f) {
        mAlertController = [UIAlertController
                            alertControllerWithTitle:alertTitle
                            message:message
                            preferredStyle: UIAlertControllerStyleAlert];
        // Add button
        mButton = [UIAlertAction actionWithTitle:buttonTitle style:UIAlertActionStyleDefault handler:nil];
        [mAlertController addAction:mButton];
    } else {
        mAlertView = [[UIAlertView alloc] initWithTitle:alertTitle
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:buttonTitle
                                              otherButtonTitles:nil];
    }
    return self;
}

- (void) show
{
    if ([MLConstants iosVersion]>=8.0f) {
        // Get pointer to app delegate, its main window and eventually to the rootViewController
        UIViewController *presentingController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([presentingController presentedViewController]!=nil)
                [presentingController dismissViewControllerAnimated:YES completion:nil];
            [presentingController presentViewController:mAlertController animated:YES completion:nil];
        });
    } else {
        [mAlertView show];
    }
}

@end
