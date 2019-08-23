//
//  PreviewView.m
//
//  Created by Alex Bettarini on 4 Jun 2018
//  Copyright © 2018 Alex Bettarini. All rights reserved.
//

@import AVFoundation;

#import "PreviewView.h"

@implementation PreviewView

- (void)updateCardFrameFraction
{
    CGFloat referenceX=0, referenceY=0, referenceW=1, referenceH=1;
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            referenceX = self.oneOne.x;
            referenceY = self.zeroZero.y;
            referenceW = self.zeroZero.x - self.oneOne.x;
            referenceH = self.oneOne.y - self.zeroZero.y;
            NSLog(@"%s line %d P.", __FUNCTION__, __LINE__);
            break;
            
        case UIInterfaceOrientationLandscapeRight:  // = UIDeviceOrientationLandscapeLeft
            referenceX = self.zeroZero.x;
            referenceY = self.zeroZero.y;
            referenceW = fabs(self.oneOne.x - self.zeroZero.x);
            referenceH = fabs(self.oneOne.y - self.zeroZero.y);
            NSLog(@"%s line %d LR.", __FUNCTION__, __LINE__);
            break;
            
        case UIInterfaceOrientationLandscapeLeft: // = UIDeviceOrientationLandscapeRight
            referenceX = self.oneOne.x;
            referenceY = self.oneOne.y;
            referenceW = fabs(self.oneOne.x - self.zeroZero.x);
            referenceH = fabs(self.oneOne.y - self.zeroZero.y);
            NSLog(@"%s line %d LL.", __FUNCTION__, __LINE__);
            break;
            
        default:
            NSLog(@"%s line %d", __FUNCTION__, __LINE__);
            break;
    }
    
    NSLog(@"height view %f, camera %f", self.bounds.size.height, referenceH);
    NSLog(@"width  view %f, camera %f", self.bounds.size.width, referenceW);
    NSLog(@"line %d, reference XYWH: %.1f, %.1f, %.1f, %.1f", __LINE__,
          referenceX, referenceY, referenceW, referenceH);
    
    CGRect cardOutlineForDrawing = self.outerCardOutline.frame;
    CGFloat cardX = cardOutlineForDrawing.origin.x;
    CGFloat cardY = cardOutlineForDrawing.origin.y;
    CGFloat cardW = cardOutlineForDrawing.size.width;
    CGFloat cardH = cardOutlineForDrawing.size.height;
    
    // For cutting out the card from the image later on we need to do
    // further adjustments to account for the difference between camera and view coordinates
    // Also normalize each values to [0..1]
    self.cardFrameFraction = CGRectMake((cardX - referenceX) / referenceW,
                                        (cardY - referenceY) / referenceH,
                                        cardW / referenceW,
                                        cardH / referenceH);
}

// Update the points [0,0] and [1,1]
- (void) updatePoiCornerPosition
{
    //NSLog(@"%s videoPreviewLayer: %@, session: %@", __FUNCTION__, self.videoPreviewLayer, self.videoPreviewLayer.session);
    
    self.zeroZero = [self.videoPreviewLayer pointForCaptureDevicePointOfInterest:CGPointZero];
    self.oneOne = [self.videoPreviewLayer pointForCaptureDevicePointOfInterest:CGPointMake(1,1)];

#ifdef DEBUG
    NSLog(@"%s point for POI (0,0): %@", __FUNCTION__, NSStringFromCGPoint(self.zeroZero));
    NSLog(@"%s point for POI (1,1): %@", __FUNCTION__, NSStringFromCGPoint(self.oneOne));
#endif
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    //NSLog(@"%s", __FUNCTION__);
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.outerCardOutline = [self getBox:CGRectZero thickness:2.0];
        [self.layer addSublayer:self.outerCardOutline];
        
        self.innerCardOutline = [self getBox:CGRectZero thickness:1.0];
        [self.layer addSublayer:self.innerCardOutline];
    }

    return self;
}

- (CALayer *)getBox:(CGRect)rect
          thickness:(CGFloat)thickness
{
    CALayer *layer = [CALayer layer];
    layer.backgroundColor = [UIColor clearColor].CGColor;
#if 0
    layer.shadowOffset = CGSizeMake(0, 3);
    layer.shadowRadius = 5.0;
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowOpacity = 0.8;
#endif
    layer.frame = rect;
    
    layer.borderColor = [UIColor greenColor].CGColor;
    layer.borderWidth = thickness;
    layer.cornerRadius = 10.0;
    
    return layer;
}

- (void)drawRect:(CGRect)rect
{
    //NSLog(@"%s rect: %@", __FUNCTION__, NSStringFromCGRect(rect));

#if 0
    NSLog(@"%lu sublayers, %@", [[self.layer sublayers] count], [self.layer sublayers]);
    for (CALayer *layer in [self.layer sublayers])
        NSLog(@"layer frame: %@", NSStringFromCGRect(layer.frame));
#endif

    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    //NSLog(@"orientation: %ld", (long)orientation);

    [self updatePoiCornerPosition];

    const CGFloat cardAspectRatio = 85.6f / 53.98f; // w/h 1.585

    CGFloat cardX, cardY, cardW, cardH;

    if (orientation == UIInterfaceOrientationPortrait) {
        cardX = self.bounds.size.width * 0.04f ; // left margin: 4% of width
        cardW = self.bounds.size.width - (2.0f * cardX);
        cardH = cardW / cardAspectRatio;
        cardY = self.bounds.size.height/2.0f - cardH/2.0f; // Center vertically for drawing
    }
    else if (orientation == UIInterfaceOrientationLandscapeRight) { // = UIInterfaceOrientationLandscapeRight
        cardY = self.bounds.size.height * 0.1f; // top margin: 10% of the height
        cardH = self.bounds.size.height - 2.0f * cardY;
        cardW = cardH * cardAspectRatio;
        cardX = (self.bounds.size.width-cardW) / 2.0f; // Center horizontally for drawing
    }
    else {
        cardY = self.bounds.size.height * 0.1f; // top margin: 10% of the height
        cardH = self.bounds.size.height - 2.0f * cardY;
        cardW = cardH * cardAspectRatio;
        cardX = (self.bounds.size.width-cardW) / 2.0f; // Center horizontally for drawing
    }

    CGRect cardOutlineForDrawing = CGRectMake(cardX, cardY, cardW, cardH);
    //NSLog(@"green overlay card frame %@", NSStringFromCGRect(cardOutlineForDrawing));

    self.outerCardOutline.frame = cardOutlineForDrawing;
    
    CGFloat scaleFactor = 0.05f;    // 5%
    CGFloat dx = cardW * scaleFactor;
    CGFloat dy = cardH * scaleFactor;
    CGRect innerCardFrame = CGRectInset(cardOutlineForDrawing, dx, dy);
    self.innerCardOutline.frame = innerCardFrame;
}

+ (Class)layerClass
{
    //NSLog(@"%s", __FUNCTION__);
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
