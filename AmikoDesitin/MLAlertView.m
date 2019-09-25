/*

 Copyright (c) 2015 Max Lungarella <cybrmx@gmail.com>
 
 Created on 21/02/2015.
 
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

#import "MLAlertView.h"

#import "MLConstants.h"

@implementation MLAlertView
{
    UIAlertController *mAlertController;
    UIAlertAction *mAction;
}

- (instancetype) initWithTitle: (NSString *)alertTitle
                       message: (NSString *)message
                        button: (NSString *)buttonTitle
{
    mAlertController = [UIAlertController
                        alertControllerWithTitle:alertTitle
                        message:message
                        preferredStyle: UIAlertControllerStyleAlert];
    // Add button
    mAction = [UIAlertAction actionWithTitle:buttonTitle style:UIAlertActionStyleDefault handler:nil];
    [mAlertController addAction:mAction];

    return self;
}

- (void) show
{
    // Get pointer to app delegate, its main window and eventually to the rootViewController
    UIViewController *presentingController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];

    dispatch_async(dispatch_get_main_queue(), ^{
        if ([presentingController presentedViewController]!=nil)
            [presentingController dismissViewControllerAnimated:YES completion:nil];

        [presentingController presentViewController:self->mAlertController
                                           animated:YES
                                         completion:nil];
    });
}

@end
