//
//  PreviewView.m
//
//  Created by Alex Bettarini on 4 Jun 2018
//  Copyright © 2018 Alex Bettarini. All rights reserved.
//

@import AVFoundation;

#import "PreviewView.h"

@implementation PreviewView

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    //NSLog(@"%s", __FUNCTION__);
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.sublayer1 = [self getBox:CGRectNull thickness:2.0];
        [self.layer addSublayer:self.sublayer1];
        
        self.sublayer2 = [self getBox:CGRectNull thickness:1.0];
        [self.layer addSublayer:self.sublayer2];
    }

    return self;
}

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

- (void)drawRect:(CGRect)rect
{
    NSLog(@"%s rect: %@", __FUNCTION__, NSStringFromCGRect(rect));
#ifdef DEBUG
    NSLog(@"%lu sublayers, %@", [[self.layer sublayers] count], [self.layer sublayers]);
    for (CALayer *layer in [self.layer sublayers])
        NSLog(@"layer frame: %@", NSStringFromCGRect(layer.frame));
//    NSLog(@"bounds: %@", NSStringFromCGRect(self.bounds)); // {{0, 0}, {262, 360}}
//    NSLog(@"frame: %@", NSStringFromCGRect(self.frame));

    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    NSLog(@"orientation: %ld", (long)orientation);
    // 1 UIInterfaceOrientationPortrait
    // 4 UIInterfaceOrientationLandscapeRight
#endif

    const CGFloat cardAspectRatio = 85.6f / 53.98f; // w/h 1.585

    CGFloat cardX, cardY, cardW, cardH;
    if (orientation == UIInterfaceOrientationPortrait) {
        cardX = 5.0f;
        cardW = self.bounds.size.width - 2.0f * cardX;
        cardH = cardW / cardAspectRatio;
        cardY = (self.bounds.size.height-cardH) / 2.0f;
    }
    else {
        cardY = self.bounds.size.height / 10.0f;        // 10% of the height
        cardH = self.bounds.size.height - 2.0f * cardY;
        cardW = cardH * cardAspectRatio;
        cardX = (self.bounds.size.width-cardW) / 2.0f;
    }

    CGRect cardFrame = CGRectMake(cardX, cardY, cardW, cardH);
    NSLog(@"overlay card frame %@", NSStringFromCGRect(cardFrame));

    self.cardFramePercent = CGRectMake(100.0f * cardX / self.bounds.size.width,
                                       100.0f * cardY / self.bounds.size.height,
                                       100.0f * cardW / self.bounds.size.width,
                                       100.0f * cardH / self.bounds.size.height);
    //NSLog(@"self %p, percent %@", self, NSStringFromCGRect(self.cardFramePercent));

    self.sublayer1.frame = cardFrame;
    
    CGFloat scaleFactor = 0.05f;
    CGFloat dx = cardW * scaleFactor;
    CGFloat dy = cardH * scaleFactor;
    //NSLog(@"dx dy %.1f %.1f", dx, dy);
    CGRect innerCardFrame = CGRectInset(cardFrame, dx, dy);
    self.sublayer2.frame = innerCardFrame;
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
