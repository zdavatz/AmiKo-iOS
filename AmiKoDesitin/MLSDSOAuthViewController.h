//
//  MLSDSOAuthWindowController.h
//  AmikoDesitin
//
//  Created by b123400 on 2023/07/28.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import "MLHINOAuthViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MLSDSOAuthViewControllerDelegate <NSObject>

- (void)sdsOAuthViewControllerDidFinishedOAuth:(id)sender;

@end

@interface MLSDSOAuthViewController : MLHINOAuthViewController

@property (nonatomic, weak) id<MLSDSOAuthViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
