//
//  PreviewView.m
//
//  Created by Alex Bettarini on 4 Jun 2018
//  Copyright © 2018 Alex Bettarini. All rights reserved.
//

@import AVFoundation;

#import "PatientViewController+smartCard.h"  // for NUMBER_OF_BOXES_FOR_OCR
#import "PreviewView.h"

#define OCR_FONT_SIZE     14

#pragma mark -

@interface PreviewView ()

- (void) updateCardGuidelines: (UIInterfaceOrientation) orientation;

@end

#pragma mark -

@implementation PreviewView

- (void)updateCardFrameFraction
{
    CGFloat referenceX=0, referenceY=0, referenceW=1, referenceH=1;
    
    UIInterfaceOrientation interfaceOrient = [UIApplication sharedApplication].statusBarOrientation;

    switch (interfaceOrient) {
        case UIInterfaceOrientationPortrait:
            referenceX = self.oneOne.x;
            referenceY = self.zeroZero.y;
            referenceW = self.zeroZero.x - self.oneOne.x;
            referenceH = self.oneOne.y - self.zeroZero.y;
            break;
            
        case UIInterfaceOrientationLandscapeRight:  // = UIDeviceOrientationLandscapeLeft
            referenceX = self.zeroZero.x;
            referenceY = self.zeroZero.y;
            referenceW = fabs(self.oneOne.x - self.zeroZero.x);
            referenceH = fabs(self.oneOne.y - self.zeroZero.y);
            break;
            
        case UIInterfaceOrientationLandscapeLeft: // = UIDeviceOrientationLandscapeRight
            referenceX = self.oneOne.x;
            referenceY = self.oneOne.y;
            referenceW = fabs(self.oneOne.x - self.zeroZero.x);
            referenceH = fabs(self.oneOne.y - self.zeroZero.y);
            break;
            
        default:
            NSLog(@"%s line %d", __FUNCTION__, __LINE__);
            break;
    }
    
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
    
#ifdef CROP_IMAGE_TO_CARD_ROI
    CGFloat roiX = cardX + cardROI_X*cardW;
    CGFloat roiY = cardY + cardROI_Y*cardH;
    CGFloat roiW = cardROI_W * cardW;
    CGFloat roiH = cardROI_H * cardH;
    self.roiFrameFraction = CGRectMake((roiX - referenceX) / referenceW,
                                       (roiY - referenceY) / referenceH,
                                       roiW / referenceW,
                                       roiH / referenceH);
#endif
    
    [self updateCardGuidelines: interfaceOrient];
}

- (void) updateCardGuidelines: (UIInterfaceOrientation) intOr
{
    //[self updatePoiCornerPosition];

    CGFloat cardX, cardY, cardW, cardH;

    if (intOr == UIInterfaceOrientationPortrait) {
        cardX = self.bounds.size.width * 0.04f ; // left margin: 4% of width
        cardW = self.bounds.size.width - (2.0f * cardX);
        cardH = cardW / cardAspectRatio;
        cardY = self.bounds.size.height/2.0f - cardH/2.0f; // Center vertically for drawing
    }
    else if (intOr == UIInterfaceOrientationLandscapeRight) { // = UIInterfaceOrientationLandscapeRight
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

    self.outerCardOutline.frame = cardOutlineForDrawing;

    CGFloat scaleFactor = 0.05f;    // 5%
    CGFloat dx = cardW * scaleFactor;
    CGFloat dy = cardH * scaleFactor;
    CGRect innerCardFrame = CGRectInset(cardOutlineForDrawing, dx, dy);
    self.innerCardOutline.frame = innerCardFrame;
    
    CGRect newFrame = self.outerCardOutline.frame;
#ifdef CROP_IMAGE_TO_CARD_ROI
    newFrame.size.width = cardROI_W * self.outerCardOutline.frame.size.width;;
    newFrame.size.height = cardROI_H * self.outerCardOutline.frame.size.height;
    newFrame.origin.y = self.outerCardOutline.frame.origin.y + cardROI_Y * self.outerCardOutline.frame.size.height;
#else
    newFrame.size.width = (cardKeepLeft_mm/cardWidth_mm) * self.outerCardOutline.frame.size.width;;
    newFrame.size.height = cardROI_H * self.outerCardOutline.frame.size.height;
#endif
    _cardRoiOutline.frame = newFrame;
}

// Update the points [0,0] and [1,1]
- (void) updatePoiCornerPosition
{
    self.zeroZero = [self.videoPreviewLayer pointForCaptureDevicePointOfInterest:CGPointZero];
    self.oneOne = [self.videoPreviewLayer pointForCaptureDevicePointOfInterest:CGPointMake(1,1)];
}

// TODO: take into consideration confidence and update only if higher
- (void) updateOCRBoxedWords:(NSArray *)a
{
    int i;
    
#ifdef CROP_IMAGE_TO_CARD_ROI
    CGRect rCard = self.cardRoiOutline.frame;
#else
    CGRect rCard = self.outerCardOutline.frame;
#endif
    
    for (i=0; i < MIN([a count], NUMBER_OF_BOXES_FOR_OCR); i++)
    {
        CALayer *layerBox = [self.ocrBoxes objectAtIndex:i];
        if (!layerBox) {
           // NSLog(@"Why is box layer %d nil ?", i);
            continue;
        }

        CATextLayer *layerText = [self.ocrText objectAtIndex:i];
        if (!layerText) {
           // NSLog(@"Why is text layer %d nil ?", i);
            continue;
        }

        NSDictionary *d = a[i];

        // BOX

        NSValue *v = d[@"box"];
        CGRect frame = v.CGRectValue;
#ifdef VN_BOXES_NEED_XY_SWAP     // Comment out this section to see original Vision boxes
        // It looks like X and Y are swapped between Vision and CoreGraphics
        CGRect detectedBox = v.CGRectValue;
        frame.origin.x = detectedBox.origin.y;
        frame.origin.y = detectedBox.origin.x;
        frame.size.width = detectedBox.size.height;
        frame.size.height = detectedBox.size.width;
#endif
#ifdef VN_BOXES_NEED_Y_FLIP
        frame.origin.y = 1.0f - frame.origin.y;
#endif
        // Scale up from 0..1 range to actual pixel position
        // with (0,0) at the top left of the card cutout
        frame.origin.x *= rCard.size.width;
        frame.origin.x += rCard.origin.x;

        frame.origin.y *= rCard.size.height;
        frame.origin.y += rCard.origin.y;

        frame.size.width *= rCard.size.width;
        frame.size.height *= rCard.size.height;

        layerBox.frame = frame;
        CGRect frameBox = frame;
        layerBox.hidden = NO;
        
        /// TEXT

        CGFloat scaleTextSize = 2.0f;
        CGRect frameText = frameBox;
        //frameText.size.width *= scaleTextSize;
        frameText.size.width = 300; //hardcoded to show long debug text
        frameText.size.height *= scaleTextSize;
        layerText.frame = frameText; // XYWH

        layerText.string = d[@"text"];
        layerText.hidden = NO;
    }
    
    // Hide the remaining ones, if any
    for (; i<NUMBER_OF_BOXES_FOR_OCR; i++) {
        CALayer *layerBox = [self.ocrBoxes objectAtIndex:i];
        CATextLayer *layerText = [self.ocrText objectAtIndex:i];
        layerBox.hidden = layerText.hidden = YES;
    }
}

#pragma mark -

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.outerCardOutline = [self getBox:CGRectZero thickness:2.0];
        [self.layer addSublayer:self.outerCardOutline];
        
        self.innerCardOutline = [self getBox:CGRectZero thickness:1.0];
        [self.layer addSublayer:self.innerCardOutline];

#ifdef CROP_IMAGE_TO_CARD_ROI
        _cardRoiOutline = [CALayer layer];
        _cardRoiOutline.backgroundColor = [UIColor clearColor].CGColor;
        _cardRoiOutline.borderColor = [UIColor systemPinkColor].CGColor;
        _cardRoiOutline.borderWidth = 2;
        [self.layer addSublayer:_cardRoiOutline];
#endif

        self.ocrBoxes = [NSMutableArray array];
        self.ocrText = [NSMutableArray array];
        for (int i=0; i<NUMBER_OF_BOXES_FOR_OCR; i++) {
            CALayer *newLayer= [CALayer layer];
            newLayer.backgroundColor = [UIColor clearColor].CGColor;
            newLayer.borderColor = [UIColor systemOrangeColor].CGColor;
            newLayer.borderWidth = 2;
            //newLayer.frame = CGRectMake(10*i, 16*i, 140, 160);
            newLayer.hidden = YES;
            [self.ocrBoxes addObject:newLayer];
            [self.layer addSublayer:newLayer];

            CATextLayer *newTextLayer= [CATextLayer layer];
            newTextLayer.foregroundColor = [UIColor labelColor].CGColor;
            [newTextLayer setFont:@"Helvetica"];
            newTextLayer.fontSize = OCR_FONT_SIZE;
            newTextLayer.hidden = YES;
            [self.ocrText addObject:newTextLayer];
            [self.layer addSublayer:newTextLayer];
        }
    }

    return self;
}

- (CALayer *)getBox:(CGRect)rect
          thickness:(CGFloat)thickness
{
    CALayer *layer = [CALayer layer];
    layer.backgroundColor = [UIColor clearColor].CGColor;
    layer.frame = rect;
    
    layer.borderColor = [UIColor systemGreenColor].CGColor;
    layer.borderWidth = thickness;
    layer.cornerRadius = 10.0;
    
    return layer;
}

- (void)drawRect:(CGRect)rect
{
#if defined( CROP_IMAGE_TO_CARD_ROI )
    self.cardRoiOutline.hidden = YES;
#endif
}

+ (Class)layerClass
{
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
