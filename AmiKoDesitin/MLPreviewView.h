//
//  MLPreviewView.h
//
//  Created by Alex Bettarini on 4 Jun 2018
//  Copyright © 2018 Alex Bettarini. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class AVCaptureSession;

@interface MLPreviewView : UIView

@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) CGRect cardFramePercent;

@end
