//
//  SceneDelegate.h
//  AmikoDesitin
//
//  Created by b123400 on 2025/12/10.
//  Copyright © 2025 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MLViewController.h"
#import "SWRevealViewController.h"

NS_ASSUME_NONNULL_BEGIN

//typedef NS_ENUM(NSInteger, EditMode) {
//    EDIT_MODE_UNDEFINED,
//    EDIT_MODE_PATIENTS,
//    EDIT_MODE_PRESCRIPTION
//};

@interface SceneDelegate: UIResponder <UIWindowSceneDelegate>

@property (strong, nonatomic) IBOutlet UIWindow *window;
@property (strong, nonatomic) SWRevealViewController *revealViewController;
@property (strong, nonatomic) MLViewController *mainViewController;
//@property EditMode editMode;

@end

NS_ASSUME_NONNULL_END
