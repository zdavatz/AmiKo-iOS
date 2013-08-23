//
//  MLAppDelegate.m
//  MyFirstApp
//
//  Created by Max on 24/06/2013.
//  Copyright (c) 2013 Madness. All rights reserved.
//

#import "MLAppDelegate.h"

#import "MLConstants.h"
#import "SWRevealViewController.h"
#import "MLViewController.h"
#import "MLSecondViewController.h"
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
    
    MLSecondViewController *frontViewController = [[MLSecondViewController alloc] init];
    MLViewController *rearViewController = [[MLViewController alloc] init];
    MLMenuViewController *rightViewController = [[MLMenuViewController alloc] init];
    
    UINavigationController *frontNavigationController = [[UINavigationController alloc]
                                                         initWithRootViewController:frontViewController];
    UINavigationController *rearNavigationController = [[UINavigationController alloc]
                                                        initWithRootViewController:rearViewController];
    
    SWRevealViewController *revealController = [[SWRevealViewController alloc]
                                                initWithRearViewController:rearNavigationController
                                                frontViewController:frontNavigationController];
    revealController.rightViewController = rightViewController;
    
    revealController.delegate = self;
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
            revealController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPad;
        } else {
            revealController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPad;
        }
        revealController.rearViewRevealOverdraw = RearViewRevealOverdraw_Portrait_iPad;
        revealController.rightViewRevealWidth = RightViewRevealWidth_Portrait_iPad;

        self.revealViewController = revealController;
        [revealController setFrontViewPosition:FrontViewPositionRightMost animated:YES];

        self.window.rootViewController = self.revealViewController;
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        revealController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPhone;
        revealController.rightViewRevealWidth = RightViewRevealWidth_Portrait_iPhone;    // Check also MLMenuViewController.m
        
        self.revealViewController = revealController;
        [revealController setFrontViewPosition:FrontViewPositionRightMost animated:YES];
        
        self.window.rootViewController = self.revealViewController; 
    }
    revealController.bounceBackOnOverdraw = YES;
    
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
