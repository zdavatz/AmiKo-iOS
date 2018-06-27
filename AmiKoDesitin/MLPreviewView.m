//
//  MLPreviewView.m
//
//  Created by Alex Bettarini on 4 Jun 2018
//  Copyright © 2018 Alex Bettarini. All rights reserved.
//

@import AVFoundation;

#import "MLPreviewView.h"

@implementation MLPreviewView

- (CALayer *)getBox:(CGRect)rect
          thickness:(CGFloat)thickness
{
    CALayer *layer = [CALayer layer];
    layer.backgroundColor = [UIColor clearColor].CGColor;
    layer.shadowOffset = CGSizeMake(0, 3);
    layer.shadowRadius = 5.0;
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowOpacity = 0.8;
    layer.frame = rect;
    
    layer.borderColor = [UIColor greenColor].CGColor;
    layer.borderWidth = thickness;
    layer.cornerRadius = 10.0;
    
    return layer;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
//    NSLog(@"%s rect: %@", __FUNCTION__, NSStringFromCGRect(rect));
//    NSLog(@"bounds: %@", NSStringFromCGRect(self.bounds)); // {{0, 0}, {262, 360}}
//    NSLog(@"frame: %@", NSStringFromCGRect(self.frame));

    const CGFloat cardAspectRatio = 85.6f / 53.98f; // w/h 1.585
    CGFloat cardX = 5.0f;
    CGFloat cardW = self.bounds.size.width - 2.0f * cardX;
    CGFloat cardH = cardW / cardAspectRatio;
    CGFloat cardY = (self.bounds.size.height-cardH) / 2.0f;
    CGRect cardFrame = CGRectMake(cardX, cardY, cardW, cardH);
    //NSLog(@"overlay card frame %@", NSStringFromCGRect(cardFrame)); // {{5, 100}, {252, 158.9}}

    self.cardFramePercent = CGRectMake(100.0f * cardX / self.bounds.size.width,
                                       100.0f * cardY / self.bounds.size.height,
                                       100.0f * cardW / self.bounds.size.width,
                                       100.0f * cardH / self.bounds.size.height);
    //NSLog(@"self %p, percent %@", self, NSStringFromCGRect(self.cardFramePercent));  // 1.9, 27.9, 96.1, 44.1

    CALayer *sublayer = [self getBox:cardFrame thickness:2.0];
    [self.layer addSublayer:sublayer];
    
    CGFloat scaleFactor = 0.05f;
    CGFloat dx = cardW * scaleFactor;
    CGFloat dy = cardH * scaleFactor;
    //NSLog(@"dx dy %.1f %.1f", dx, dy);
    CGRect innerCardFrame = CGRectInset(cardFrame, dx, dy);
    CALayer *sublayer2 = [self getBox:innerCardFrame thickness:1.0];
    [self.layer addSublayer:sublayer2];
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
