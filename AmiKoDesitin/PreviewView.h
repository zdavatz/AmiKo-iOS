//
//  PreviewView.h
//
//  Created by Alex Bettarini on 4 Jun 2018
//  Copyright © 2018 Alex Bettarini. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class AVCaptureSession;

@interface PreviewView : UIView

@property (nonatomic) CGPoint zeroZero;
@property (nonatomic) CGPoint oneOne;

@property (nonatomic) CALayer *outerCardOutline;
@property (nonatomic) CALayer *innerCardOutline;

@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) CGRect cardFrameFraction; // range 0..1

- (CALayer *) getBox:(CGRect)rect thickness:(CGFloat)thickness;
- (void) updatePoiCornerPosition;
- (void) updateCardFrameFraction;
@end
