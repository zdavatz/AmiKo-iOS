//
//  MLSendToZurRoseActivity.m
//  AmikoDesitin
//
//  Created by b123400 on 2024/12/23.
//  Copyright © 2024 Ywesee GmbH. All rights reserved.
//

#import "MLSendToZurRoseActivity.h"

@implementation MLSendToZurRoseActivity

- (NSString *)activityTitle {
    return NSLocalizedString(@"Send to ZurRose", @"");
}

- (UIImage *)activityImage {
    return [UIImage systemImageNamed:@"paperplane"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    
}

- (void)performActivity {
    [self.zurRosePrescription sendToZurRoseWithCompletion:^(NSHTTPURLResponse * _Nonnull res, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIViewController *root = [[UIApplication sharedApplication].keyWindow rootViewController];
            if (error || res.statusCode != 200) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"")
                                                                               message:[error localizedDescription] ?: [NSString stringWithFormat:NSLocalizedString(@"Error Code: %ld", @""), res.statusCode]
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                                          style:UIAlertActionStyleDefault
                                                        handler:nil]];
                [root presentViewController:alert animated:YES completion:nil];
            } else {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                               message:NSLocalizedString(@"Prescription is sent to ZurRose", @"")
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                                          style:UIAlertActionStyleDefault
                                                        handler:nil]];
                [root presentViewController:alert animated:YES completion:nil];
            }
        });
    }];
}

- (UIActivityCategory)activityCategory {
    return UIActivityCategoryShare;
}

@end
