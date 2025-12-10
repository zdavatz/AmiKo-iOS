//
//  SceneDelegate.m
//  AmikoDesitin
//
//  Created by b123400 on 2025/12/10.
//  Copyright © 2025 Ywesee GmbH. All rights reserved.
//

#import "SceneDelegate.h"
#import "MLSecondViewController.h"
#import "MLConstants.h"
#import "MLUtility.h"

@interface SceneDelegate () <SWRevealViewControllerDelegate>

@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) return;
    UIWindowScene *windowScene = (UIWindowScene*)scene;
    
    // Init main window
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    
#ifdef DEBUG
    // Print out some useful info
    CGFloat screenScale = [[UIScreen mainScreen] scale];

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0  // Deprecated in iOS 9.0
    // Screen size minus the size of the status bar (if visible)
    // This is the size of the app window
    NSLog(@"points w = %f, points h = %f, scale = %f",
          [[UIScreen mainScreen] applicationFrame].size.width,
          [[UIScreen mainScreen] applicationFrame].size.height, screenScale);
#endif
    
    // Screen size regardless of status bar.
    // This is the size of the device
    NSLog(@"points w = %f, points h = %f, scale = %f",
          [[UIScreen mainScreen] bounds].size.width,
          [[UIScreen mainScreen] bounds].size.height, screenScale);
#endif

    // Rear
    self.mainViewController = [MLViewController new];
    UINavigationController *mainViewNavigationController =
        [[UINavigationController alloc] initWithRootViewController:self.mainViewController];
    mainViewNavigationController.view.backgroundColor = [UIColor secondarySystemBackgroundColor];

    // Front
    MLSecondViewController *secondViewController = [MLSecondViewController new];
    UINavigationController *secondViewNavigationController =
        [[UINavigationController alloc] initWithRootViewController:secondViewController];

    // Init swipe (reveal) view controller
    SWRevealViewController *mainRevealController = [[SWRevealViewController alloc]
                                                initWithRearViewController:mainViewNavigationController
                                                frontViewController:secondViewNavigationController];
    
    MLTitleViewController *titleViewController = [MLTitleViewController new];
    mainRevealController.rightViewController = titleViewController;
    
    mainRevealController.delegate = self;

    // Make sure the orientation is correct

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UIInterfaceOrientation orientation = windowScene.interfaceOrientation;
        if (orientation == UIInterfaceOrientationLandscapeLeft ||
            orientation == UIInterfaceOrientationLandscapeRight)
        {
            mainRevealController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPad;
        }
        else {
            mainRevealController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPad;
        }

        mainRevealController.rearViewRevealOverdraw = RearViewRevealOverdraw_Portrait_iPad;
        mainRevealController.rightViewRevealWidth = RightViewRevealWidth_Portrait_iPad;

        self.revealViewController = mainRevealController;
        [mainRevealController setFrontViewPosition:FrontViewPositionRightMost animated:YES];

        self.window.rootViewController = self.revealViewController;
    }
    else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        mainRevealController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPhone;
        mainRevealController.rightViewRevealWidth = RightViewRevealWidth_Portrait_iPhone;    // Check also MLMenuViewController.m

        self.revealViewController = mainRevealController;
        [mainRevealController setFrontViewPosition:FrontViewPositionRightMost animated:YES];

        self.window.rootViewController = self.revealViewController;
    }
    mainRevealController.bounceBackOnOverdraw = YES;
    
    // Note: iOS7 - sets the global TINT color!!
    {
        
        // Changes background color of navigation bar
        [[UINavigationBar appearance] setBarTintColor:[UIColor systemGray5Color]];
                
        self.window.clipsToBounds =YES;
        // self.window.frame = CGRectMake(0,0,self.window.frame.size.width,self.window.frame.size.height-20);
        
        // Text and TabBar button colors (also images on navigationBar ?)
        [self.window setTintColor:MAIN_TINT_COLOR];
        [self.window setTintColor:[UIColor labelColor]];
        
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [UIFont systemFontOfSize:14], NSFontAttributeName,
                                    [UIColor labelColor], NSForegroundColorAttributeName,
                                    nil];
        [[UINavigationBar appearance] setTitleTextAttributes:attributes];
     
        // Remove shadow?
        /*
        [[UINavigationBar appearance] setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        [[UINavigationBar appearance] setShadowImage:[UIImage new]];
        */
        
//        [[UIApplication sharedApplication] setStatusBarHidden:NO
//                                                withAnimation:UIStatusBarAnimationSlide];
    }
    
    self.window.rootViewController = self.revealViewController;
    [self.window makeKeyAndVisible];
    
    // Issue #54
    [mainRevealController revealToggle:nil];
    [mainRevealController revealToggle:nil];
}

@end
