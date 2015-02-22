/*
 
 Copyright (c) 2013 Max Lungarella <cybrmx@gmail.com>
 
 Created on 24/06/2013.
 
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

#import "MLAppDelegate.h"

#import "MLConstants.h"
#import "SWRevealViewController.h"
#import "MLViewController.h"
#import "MLSecondViewController.h"
#import "MLTitleViewController.h"
#import "MLMenuViewController.h"

@interface MLAppDelegate()<SWRevealViewControllerDelegate>
// Do stuff
@end

@implementation MLAppDelegate

@synthesize window = _window;
@synthesize navController = _navController;
@synthesize revealViewController = _revealViewController;

void onUncaughtException(NSException *exception)
{
    NSLog(@"uncaught exception: %@", exception.description);
}

CGSize PhysicalPixelSizeOfScreen(UIScreen *s)
{
    CGSize result = s.bounds.size;
    
    if ([s respondsToSelector: @selector(scale)]) {
        CGFloat scale = s.scale;
        result = CGSizeMake(result.width * scale, result.height * scale);
    }
    
    return result;
}

- (BOOL) application: (UIApplication *)application didFinishLaunchingWithOptions: (NSDictionary *)launchOptions
{
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    self.window = [[UIWindow alloc] initWithFrame:screenBound];
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    
    NSLog(@"points w = %f, points h = %f, scale = %f", [[UIScreen mainScreen] applicationFrame].size.width,
          [[UIScreen mainScreen] applicationFrame].size.height, screenScale);
    
    CGSize sizeInPixels = PhysicalPixelSizeOfScreen([UIScreen mainScreen]);
    NSLog(@"physical w = %f, physical h = %f", sizeInPixels.width, sizeInPixels.height);
    
    MLViewController *mainViewController = [[MLViewController alloc] init];
    UINavigationController *mainViewNavigationController = [[UINavigationController alloc] initWithRootViewController:mainViewController];
    MLSecondViewController *secondViewController = [[MLSecondViewController alloc] init];
    UINavigationController *secondViewNavigationController = [[UINavigationController alloc] initWithRootViewController:secondViewController];
    
    SWRevealViewController *mainRevealController = [[SWRevealViewController alloc]
                                                initWithRearViewController:mainViewNavigationController
                                                frontViewController:secondViewNavigationController];
    
    MLTitleViewController *titleViewController = [[MLTitleViewController alloc] init];    
    mainRevealController.rightViewController = titleViewController;
    
    mainRevealController.delegate = self;
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
            mainRevealController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPad;
        } else {
            mainRevealController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPad;
        }
        mainRevealController.rearViewRevealOverdraw = RearViewRevealOverdraw_Portrait_iPad;
        mainRevealController.rightViewRevealWidth = RightViewRevealWidth_Portrait_iPad;

        self.revealViewController = mainRevealController;
        [mainRevealController setFrontViewPosition:FrontViewPositionRightMost animated:YES];

        self.window.rootViewController = self.revealViewController;
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        mainRevealController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPhone;
        mainRevealController.rightViewRevealWidth = RightViewRevealWidth_Portrait_iPhone;    // Check also MLMenuViewController.m
        
        self.revealViewController = mainRevealController;
        [mainRevealController setFrontViewPosition:FrontViewPositionRightMost animated:YES];
        
        self.window.rootViewController = self.revealViewController; 
    }
    mainRevealController.bounceBackOnOverdraw = YES;
    
    // Note: iOS7 - sets the global TINT color!!
    if (IOS_NEWER_OR_EQUAL_TO_7) {
        [application setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];  // WHITE
        // [application setStatusBarStyle:UIStatusBarStyleBlackOpaque];
        // [application setStatusBarStyle:UIStatusBarStyleDefault animated:YES];    // BLACK
        
        // Changes background color of navigation bar!
        // [[UINavigationBar appearance] setBarTintColor:MAIN_TINT_COLOR];
                
        self.window.clipsToBounds =YES;
        // self.window.frame = CGRectMake(0,0,self.window.frame.size.width,self.window.frame.size.height-20);
        
        // Text and tabbar button colors
        [self.window setTintColor:MAIN_TINT_COLOR];
        
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [UIFont systemFontOfSize:14], NSFontAttributeName,
                                    [UIColor whiteColor], NSForegroundColorAttributeName, nil];
        [[UINavigationBar appearance] setTitleTextAttributes:attributes];
     
        // Remove shadow?
        /*
        [[UINavigationBar appearance] setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        [[UINavigationBar appearance] setShadowImage:[UIImage new]];
        */
        
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    }
    
    [self.window makeKeyAndVisible];
    
    NSSetUncaughtExceptionHandler(&onUncaughtException);
    
    return YES;
}

- (void) applicationWillResignActive: (UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void) applicationDidEnterBackground: (UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void) applicationWillEnterForeground: (UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void) applicationDidBecomeActive: (UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void) applicationWillTerminate: (UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
