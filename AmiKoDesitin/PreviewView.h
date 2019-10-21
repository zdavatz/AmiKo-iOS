//
//  PreviewView.h
//
//  Created by Alex Bettarini on 4 Jun 2018
//  Copyright © 2018 Alex Bettarini. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

//#define VN_BOXES_NEED_XY_SWAP // This happens if the image orientation is wrong
#define VN_BOXES_NEED_Y_FLIP
#define CROP_IMAGE_TO_CARD_ROI // otherwise the whole card cutout will be OCRed

//#define TAP_TO_END_CARD_OCR   // otherwise terminate canera automatically

#pragma mark -

#define cardWidth_mm            85.6f
#define cardHeight_mm           53.98f
#define cardIgnoreTop_mm        35.0f // discard 35 mm at the top
#define cardKeepLeft_mm         15.0f // origin of detected boxes must fall within this strip on the left

#define cardAspectRatio         (cardWidth_mm / cardHeight_mm) // w/h 1.585

#define minTextHeight_mm        2.0f

// Following 4 defines in the range 0..1
#define cardROI_X               0.0f
#define cardROI_Y               (cardIgnoreTop_mm / cardHeight_mm)
#define cardROI_W               (60.0/cardWidth_mm)
#define cardROI_H               ((cardHeight_mm - cardIgnoreTop_mm)/cardHeight_mm)

#ifdef CROP_IMAGE_TO_CARD_ROI
#define rejectBoxWidthFraction  0.157f  // observed threshold
#else
#define rejectBoxWidthFraction  0.047f  // observed threshold
#endif

@class AVCaptureSession;

#pragma mark -

@interface PreviewView : UIView

@property (nonatomic) CGPoint zeroZero;     // top left
@property (nonatomic) CGPoint oneOne;       // bottom right

@property (nonatomic) CALayer *outerCardOutline;
@property (nonatomic) CALayer *innerCardOutline;
#ifdef CROP_IMAGE_TO_CARD_ROI
@property (nonatomic) CALayer *cardRoiOutline;
#endif

@property (nonatomic) NSMutableArray *ocrBoxes;
@property (nonatomic) NSMutableArray *ocrText;

@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) CGRect cardFrameFraction; // range 0..1 of the frame
#ifdef CROP_IMAGE_TO_CARD_ROI
@property (nonatomic) CGRect roiFrameFraction;  // range 0..1 of the frame
#endif

- (CALayer *) getBox:(CGRect)rect thickness:(CGFloat)thickness;
- (void) updatePoiCornerPosition;
- (void) updateCardFrameFraction;
- (void) updateOCRBoxedWords:(NSArray *)a;
@end
