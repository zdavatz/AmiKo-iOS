//
//  MLPreviewView.m
//
//  Created by Alex Bettarini on 4 Jun 2018
//  Copyright © 2018 Alex Bettarini. All rights reserved.
//

@import AVFoundation;

#import "MLPreviewView.h"

@implementation MLPreviewView

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"bounds %@", NSStringFromCGRect(self.bounds)); // {{0, 0}, {375, 667}}
#endif

    const CGFloat cardAspectRatio = 85.6f / 53.98f; // w/h 1.585
    CGFloat cardX = 5.0f;
    CGFloat cardW = self.bounds.size.width - 2*cardX;
    CGFloat cardH = cardW / cardAspectRatio;
    CGFloat cardY = (self.bounds.size.height-cardH)/2;
    CGRect cardFrame = CGRectMake(cardX, cardY, cardW, cardH);
    NSLog(@"cardFrame %@", NSStringFromCGRect(cardFrame)); // {{5, 50}, {210, 132.4}}

    NSLog(@"percent %.1f%% %.1f%% %.1f%% %.1f%%", // 2.3% 17.5% 95.5% 46.3%
          100.0f * cardX / self.bounds.size.width,
          100.0f * cardY / self.bounds.size.height,
          100.0f * cardW / self.bounds.size.width,
          100.0f * cardH / self.bounds.size.height);

    CALayer *sublayer = [CALayer layer];
    sublayer.backgroundColor = [UIColor clearColor].CGColor;
    sublayer.shadowOffset = CGSizeMake(0, 3);
    sublayer.shadowRadius = 5.0;
    sublayer.shadowColor = [UIColor blackColor].CGColor;
    sublayer.shadowOpacity = 0.8;
    sublayer.frame = cardFrame;
    
    sublayer.borderColor = [UIColor greenColor].CGColor;
    sublayer.borderWidth = 2.0;
    sublayer.cornerRadius = 10.0;
    
    [self.layer addSublayer:sublayer];
}

+ (Class)layerClass
{
    NSLog(@"%s", __FUNCTION__);
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer
{
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

- (AVCaptureSession *)session
{
    return self.videoPreviewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session
{
    self.videoPreviewLayer.session = session;
}

@end
