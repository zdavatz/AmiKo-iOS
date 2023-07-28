//
//  MLHINOAuthViewController.h
//  AmikoDesitin
//
//  Created by b123400 on 2023/07/27.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MLHINOAuthViewController : UIViewController

@property (strong, nonatomic) UIActivityIndicatorView *loadingSpinner;

- (void)displayError:(NSError *)error;
- (void)displayStatus:(NSString *)status;

@end

NS_ASSUME_NONNULL_END
