//
//  MLUbiquitousStateAlertController.h
//  AmikoDesitin
//
//  Created by b123400 on 2020/04/02.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MLUbiquitousStateAlertController : NSObject

@property (nonatomic, copy, nullable) void (^onDone)(void);
@property (nonatomic, copy, nullable) void (^onError)(void);

- (instancetype)initWithUbiquitousItem:(NSURL *)url;
- (void)presentAt: (UIViewController*)presenter;

@end

NS_ASSUME_NONNULL_END
