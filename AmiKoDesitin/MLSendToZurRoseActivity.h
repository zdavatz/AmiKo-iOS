//
//  MLSendToZurRoseActivity.h
//  AmikoDesitin
//
//  Created by b123400 on 2024/12/23.
//  Copyright © 2024 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPrescription/ZurRosePrescription.h"

NS_ASSUME_NONNULL_BEGIN

@interface MLSendToZurRoseActivity : UIActivity

@property (nonatomic, strong) ZurRosePrescription *zurRosePrescription;

@end

NS_ASSUME_NONNULL_END
