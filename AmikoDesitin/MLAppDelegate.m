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
#import "MLPrescriptionViewController.h"
#import "MLTitleViewController.h"
#import "MLMenuViewController.h"

@interface MLAppDelegate()<SWRevealViewControllerDelegate>
// Do stuff
@end

@implementation MLAppDelegate

@synthesize window = _window;
@synthesize navController = _navController;
@synthesize revealViewController = _revealViewController;

MLViewController *mainViewController;

int launchState = eAips;
bool launchedFromShortcut = NO;

void onUncaughtException(NSException *exception)
{
    NSLog(@"uncaught exception: %@", exception.description);
}

/** Utility functions
 */
CGSize PhysicalPixelSizeOfScreen(UIScreen *s)
{
    CGSize result = s.bounds.size;
    
    if ([s respondsToSelector: @selector(scale)]) {
        CGFloat scale = s.scale;
        result = CGSizeMake(result.width * scale, result.height * scale);
    }
    
    return result;
}

/** Handles Quick Action shortcuts
 */
- (BOOL) handleShortcutItem:(UIApplicationShortcutItem *)shortcutItem
{
    bool handled = NO;

    // Check which quick action to run
    if ([shortcutItem.type isEqualToString:@"com.ywesee.amiko.ios.aips"]
        || [shortcutItem.type isEqualToString:@"com.ywesee.comed.ios.aips"]) {
#ifdef DEBUG
        NSLog(@"shortcut tapped: aips");
#endif
        launchState = eAips;
        handled = YES;
    }
    if ([shortcutItem.type isEqualToString:@"com.ywesee.amiko.ios.favorites"]
        || [shortcutItem.type isEqualToString:@"com.ywesee.comed.ios.favorites"]) {
#ifdef DEBUG
        NSLog(@"shortcut tapped: favorites");
#endif
        launchState = eFavorites;
        handled = YES;
    }
    if ([shortcutItem.type isEqualToString:@"com.ywesee.amiko.ios.interactions"]
        || [shortcutItem.type isEqualToString:@"com.ywesee.comed.ios.interactions"]) {
#ifdef DEBUG
        NSLog(@"shortcut tapped: interactions");
#endif
        launchState = eInteractions;
        handled = YES;
    }
    if ([shortcutItem.type isEqualToString:@"com.ywesee.amiko.ios.desitin"]
        || [shortcutItem.type isEqualToString:@"com.ywesee.comed.ios.desitin"]) {
#ifdef DEBUG
        NSLog(@"shortcut tapped: desitin");
#endif
        launchState = eDesitin;
        handled = YES;
    }
    
    if (mainViewController!=nil && handled==YES) {
        [mainViewController setLaunchState:launchState];
    }
    
    return handled;
}

/** Override delegate method: quick actions
 */
- (void) application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler
{
    bool handledShortcutItem = [self handleShortcutItem:shortcutItem];
    // completionHandler expects a bool indicating whether we are able to handle the item
    completionHandler(handledShortcutItem);
}


/** Override method: app entry point
 */
- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#ifdef DEBUG
    //NSLog(@"%s", __FUNCTION__);
#endif
    // Init main window
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    self.window = [[UIWindow alloc] initWithFrame:screenBound];
    
    // Print out some useful info
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    CGSize sizeInPixels = PhysicalPixelSizeOfScreen([UIScreen mainScreen]);
#ifdef DEBUG
    NSLog(@"points w = %f, points h = %f, scale = %f", [[UIScreen mainScreen] applicationFrame].size.width,
          [[UIScreen mainScreen] applicationFrame].size.height, screenScale);
    NSLog(@"physical w = %f, physical h = %f", sizeInPixels.width, sizeInPixels.height);
#endif
    
    // Init all view controllers (main and secondary)
    mainViewController = [[MLViewController alloc] init];
    UINavigationController *mainViewNavigationController =
        [[UINavigationController alloc] initWithRootViewController:mainViewController];

    MLSecondViewController *secondViewController = [[MLSecondViewController alloc] init];
    UINavigationController *secondViewNavigationController =
        [[UINavigationController alloc] initWithRootViewController:secondViewController];

    // Check if app was launched by quick action
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        UIApplicationShortcutItem *shortcutItem = [launchOptions objectForKey:UIApplicationLaunchOptionsShortcutItemKey];
        if (shortcutItem != nil) {
            [self handleShortcutItem:shortcutItem];
            // Method returns false if application was launched from shortcut
            // and prevents performActionForShortcutItem to be called...
            launchedFromShortcut = YES;
        }
    }
    
    // Init swipe (reveal) view controller
    SWRevealViewController *mainRevealController = [[SWRevealViewController alloc]
                                                initWithRearViewController:mainViewNavigationController
                                                frontViewController:secondViewNavigationController];
    
    MLTitleViewController *titleViewController = [[MLTitleViewController alloc] init];    
    mainRevealController.rightViewController = titleViewController;
    
    mainRevealController.delegate = self;

    // Make sure the orientation is correct
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
    }
    else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
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
    
    // Register the applications default
    NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];
    if ([[MLConstants appLanguage] isEqualToString:@"de"]) {
        [appDefaults setValue:[NSDate date] forKey:@"germanDBLastUpdate"];
        [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    }
    else if ([[MLConstants appLanguage] isEqualToString:@"fr"]) {
        [appDefaults setValue:[NSDate date] forKey:@"frenchDBLastUpdate"];
        [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    }
    
    // Initialize user defaults first time app is run
    if ([[MLConstants appLanguage] isEqualToString:@"de"]) {
        NSDate* lastUpdated = [[NSUserDefaults standardUserDefaults] objectForKey:@"germanDBLastUpdate"];
        if (lastUpdated==nil) {
            [lastUpdated setValue:[NSDate date] forKey:@"germanDBLastUpdate"];
            NSLog(@"Initializing defaults...");
        }
    }
    else if ([[MLConstants appLanguage] isEqualToString:@"fr"]) {
        NSDate* lastUpdated = [[NSUserDefaults standardUserDefaults] objectForKey:@"frenchDBLastUpdate"];
        if (lastUpdated==nil) {
            [lastUpdated setValue:[NSDate date] forKey:@"frenchDBLastUpdate"];
            NSLog(@"Initializing defaults...");
        }
    }
    
    [self.window makeKeyAndVisible];
    
    NSSetUncaughtExceptionHandler(&onUncaughtException);
    
    return !launchedFromShortcut;
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
