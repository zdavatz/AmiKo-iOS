//
//  MLProgressViewController.h
//  AmikoDesitin
//
//  Created by Max on 19/02/2014.
//  Copyright (c) 2014 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MLProgressViewController : UIViewController <UIAlertViewDelegate>
{
    BOOL mDownloadInProgress;
}

@property (nonatomic, assign) BOOL mDownloadInProgress;

- (void) setMessage:(NSString *)msg;
- (void) start;
- (void) updateWith:(int)downloadedBytes andWith:(int)expectedBytes;
- (void) remove;

@end
