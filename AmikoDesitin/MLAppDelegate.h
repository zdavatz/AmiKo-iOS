//
//  MLAppDelegate.h
//  MyFirstApp
//
//  Created by Max on 24/06/2013.
//  Copyright (c) 2013 Madness. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MLViewController;
@class SWRevealViewController;

@interface MLAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) IBOutlet UIWindow *window;
@property (retain, nonatomic) UINavigationController *navController;
@property (strong, nonatomic) MLViewController *viewController;
@property (strong, nonatomic) SWRevealViewController *revealViewController;

@end
