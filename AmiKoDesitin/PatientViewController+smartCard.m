//
//  PatientViewController+smartCard.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 15/06/2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "PatientViewController+smartCard.h"
#import "UIImage+Cropping.h"
@import Vision;
#import <time.h>
#import "MLViewController.h"
#import "SWRevealViewController.h"
#import "MLAppDelegate.h"

//#define DEBUG_ISSUE_102_SHOW_ALL_BOXES
#define DISCARD_BAD_BOXES

@implementation PatientViewController (smartCard)

- (void) startCameraLivePreview
{
#ifdef DEBUG_ISSUE_102_VERBOSE
    NSLog(@"%s", __FUNCTION__);
#endif
    videoCaptureFinished = NO;

//    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
//    UINavigationController *nc = self.navigationController;  // nil
//    NSLog(@"%s self %p, class %@", __FUNCTION__, self, [self class]);
//    NSLog(@"navigationController %@", nc);
//    NSLog(@"rootVC %@ class %@, rootVC.nc %@", rootVC, [rootVC class], rootVC.navigationController);
    
    // Make sure front is PatientViewController
    UIViewController *nc_front = self.revealViewController.frontViewController; // UINavigationController
    UIViewController *vc_front = [nc_front.childViewControllers firstObject];   // PatientViewController
    
    if (!self.cameraVC)
        self.cameraVC = nil; // So that it will be reinitialized with the current orientation

    self.cameraVC = [[CameraViewController alloc] initWithNibName:@"CameraViewController"
                                                            bundle:nil];
    self.cameraVC.delegate = self;

    [vc_front presentViewController:self.cameraVC
                           animated:NO
                         completion:NULL];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
#ifdef DEBUG_ISSUE_102_VERBOSE
    static int frameNumber = 0;
    AVCaptureVideoOrientation entryVideoOrientation = connection.videoOrientation;
    NSLog(@"captureOutput line %d, frame# %d, ori: %ld, thread:%@, main:%d, finished:%d", __LINE__,
          frameNumber++,
          (long)entryVideoOrientation,
          [NSThread currentThread],
          [[NSThread currentThread] isMainThread],
          videoCaptureFinished);
#endif

    if (videoCaptureFinished)
        return;

//    __block UIInterfaceOrientation statusBarOrientation2;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        statusBarOrientation2 = [UIApplication sharedApplication].statusBarOrientation;
//    });

//    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];

    // TODO: maybe we don't need to set this here everytime

    dispatch_async(dispatch_get_main_queue(), ^{
        UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
        if ([connection isVideoOrientationSupported]) {
            if (statusBarOrientation == UIInterfaceOrientationPortrait)  // 1 ok
            {
                [connection setVideoOrientation: AVCaptureVideoOrientationPortrait];
                #ifdef DEBUG_ISSUE_102_VERBOSE
                NSLog(@"%s %d, setVideoOrientation: %ld", __FUNCTION__, __LINE__, (long)statusBarOrientation);
                NSLog(@"%s %d, connection.videoOrientation: %ld", __FUNCTION__, __LINE__, connection.videoOrientation);
                #endif
            }
            else if (statusBarOrientation == UIInterfaceOrientationLandscapeRight)  // 3 ok
            {
                [connection setVideoOrientation: AVCaptureVideoOrientationLandscapeRight];
                #ifdef DEBUG_ISSUE_102_VERBOSE
                NSLog(@"%s %d, setVideoOrientation: %ld", __FUNCTION__, __LINE__, (long)statusBarOrientation);
                NSLog(@"%s %d, connection.videoOrientation: %ld", __FUNCTION__, __LINE__, connection.videoOrientation);
                #endif
            }
            else if (statusBarOrientation == UIInterfaceOrientationLandscapeLeft)  // 4
            {
                [connection setVideoOrientation: AVCaptureVideoOrientationLandscapeLeft]; //upside down
                //[connection setVideoOrientation: AVCaptureVideoOrientationLandscapeRight];
                #ifdef DEBUG_ISSUE_102_VERBOSE
                NSLog(@"%s %d, setVideoOrientation: %ld", __FUNCTION__, __LINE__,
                      (long)statusBarOrientation);
                NSLog(@"%s %d, connection.videoOrientation: %ld", __FUNCTION__, __LINE__, connection.videoOrientation);
                #endif
            }
            else
            {
                [connection setVideoOrientation: AVCaptureVideoOrientationPortrait];
                #ifdef DEBUG_ISSUE_102_VERBOSE
                NSLog(@"%s %d, setVideoOrientation: %ld, P:%ld, L:%ld", __FUNCTION__, __LINE__,
                      (long)statusBarOrientation,
                      (long)UIInterfaceOrientationPortrait,
                      (long)UIInterfaceOrientationLandscapeLeft);
                NSLog(@"%s %d, connection.videoOrientation: %ld", __FUNCTION__, __LINE__, connection.videoOrientation);
                #endif
            }
            //[connection setVideoOrientation: (AVCaptureVideoOrientation)statusBarOrientation];  // NG
        }
    });

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.cameraVC.previewView updatePoiCornerPosition];
        [self.cameraVC.previewView updateCardFrameFraction];
    });

    UIImage *image;
    {
        CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        //NSLog(@"%s %d, ciImage.properties %@", __FUNCTION__, __LINE__, ciImage.properties); // null
        CIContext *context = [CIContext contextWithOptions:nil];
        CGRect r = CGRectMake(0, 0,
                              CVPixelBufferGetWidth(pixelBuffer),
                              CVPixelBufferGetHeight(pixelBuffer));
        CGImageRef myImage = [context createCGImage:ciImage
                                           fromRect:r];

        image = [UIImage imageWithCGImage:myImage];
        CGImageRelease(myImage);
        if (!image) {
            NSLog(@"%s %d, image is nil", __FUNCTION__, __LINE__);
            return;
        }
    }

    //NSLog(@"%s %d, image ori %ld", __FUNCTION__, __LINE__, (long)image.imageOrientation); // RO
    
#ifdef CROP_IMAGE_TO_CARD_ROI
    // Crop the image to the ROI in the health card outline
    CGFloat x = self.cameraVC.previewView.roiFrameFraction.origin.x;
    CGFloat y = self.cameraVC.previewView.roiFrameFraction.origin.y;
    CGFloat w = self.cameraVC.previewView.roiFrameFraction.size.width;
    CGFloat h = self.cameraVC.previewView.roiFrameFraction.size.height;

    CGRect cg_rectCropCard = CGRectMake(x * image.size.width,
                                        y * image.size.height,
                                        w * image.size.width,
                                        h * image.size.height);
#else
    // Crop the image to the health card outline
    CGFloat x = self.cameraVC.previewView.cardFrameFraction.origin.x;
    CGFloat y = self.cameraVC.previewView.cardFrameFraction.origin.y;
    CGFloat w = self.cameraVC.previewView.cardFrameFraction.size.width;
    CGFloat h = self.cameraVC.previewView.cardFrameFraction.size.height;

    CGRect cg_rectCropCard = CGRectMake(x * image.size.width,
                                        y * image.size.height,
                                        w * image.size.width,
                                        h * image.size.height);
#endif

    UIImage *imageCropped = [image cropRectangle:cg_rectCropCard inFrame:image.size];
    if (!imageCropped) {
        #ifdef DEBUG_ISSUE_102_VERBOSE
        NSLog(@"%s %d, imageCard is nil", __FUNCTION__, __LINE__);
        NSLog(@"%s %d, cg_rectCropCard %@", __FUNCTION__, __LINE__, NSStringFromCGRect(cg_rectCropCard));
        #endif
        return;
    }
    
    // Vision, text detection
    CIImage* ciimage = [[CIImage alloc] initWithCGImage:imageCropped.CGImage];
    if (!ciimage) {
        #ifdef DEBUG_ISSUE_102_VERBOSE
        NSLog(@"%s %d, ciimage is nil", __FUNCTION__, __LINE__);
        #endif
        return;
    }

    // Try ignoring the video orientation (always 0) and use the screen orientation
    __block UIInterfaceOrientation interfaceOrient;
    dispatch_async(dispatch_get_main_queue(), ^{
        interfaceOrient = [UIApplication sharedApplication].statusBarOrientation;
    });
    CGImagePropertyOrientation orient;
    if (interfaceOrient == UIInterfaceOrientationLandscapeRight) {
        //NSLog(@"%s %d, UIInterfaceOrientation LandscapeRight", __FUNCTION__, __LINE__);
        orient = kCGImagePropertyOrientationRight; // for portrait
    }
    else if (interfaceOrient == UIInterfaceOrientationPortrait) {
        //NSLog(@"%s %d, UIInterfaceOrientation Portrait", __FUNCTION__, __LINE__);
        orient = kCGImagePropertyOrientationUp; // for landscape L  // always this one ?
    }
    else if (interfaceOrient == UIInterfaceOrientationLandscapeLeft) {
        //NSLog(@"%s %d, UIInterfaceOrientation LandscapeLeft", __FUNCTION__, __LINE__);
        orient = kCGImagePropertyOrientationLeft; // for landscape R
    }
    else {
        //NSLog(@"%s %d, UIInterfaceOrientation other", __FUNCTION__, __LINE__);
        orient = kCGImagePropertyOrientationUp;
    }

    NSUInteger vnCount;
    NSArray *boxedWords = [self visionDetectTextBoundingBoxes:ciimage orientation:orient boxesCount:&vnCount];
#ifdef DEBUG_ISSUE_102_VERBOSE
    if ([boxedWords count] > 0) {
        NSLog(@"==== Line %d, === Accepted boxes: %ld of %lu", __LINE__, [boxedWords count], (unsigned long)vnCount);
        for (NSDictionary *d in boxedWords) {
            NSLog(@"\t dict: %@", d);

//            NSValue *v = d[@"box"];
//            NSString *s = d[@"text"];
//            NSLog(@"\t\t rect: %@ <%@>", NSStringFromCGRect(v.CGRectValue), s);
        }
    }
#endif

    if ([boxedWords count] == 0) {
        //NSLog(@"%s Line %d, no boxes detected", __FUNCTION__, __LINE__);
        return;
    }

#ifdef DEBUG_ISSUE_102_SHOW_ALL_BOXES
    NSArray *goodBoxedWords = boxedWords;
#else
    NSArray *goodBoxedWords = [self analyzeVisionBoxedWords:boxedWords];
#endif
    
    // We expect to have
    //  goodBoxes[0] FamilyName, GivenName
    //  goodBoxes[1] CardNumber (unused)
    //  goodBoxes[2] Birthday Sex

//#ifdef DEBUG_ISSUE_102
//    // Check for multiline blocks (if any, only the first line should be kept)
//    for (NSDictionary *d in goodBoxedWords) {
//        NSString *s = d[@"text"];
//        NSArray *a = [s componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
//        if ([a count] > 1)
//            NSLog(@"multiline: %@", a);
//    }
//#endif
    
#ifndef DEBUG_ISSUE_102_SHOW_ALL_BOXES
  #ifdef DEBUG_ISSUE_102
    if ([goodBoxedWords count] != NUMBER_OF_BOXES_FOR_OCR ) {
        NSLog(@"Line %d, VN box: %ld, accepted: %ld, sorted %ld (expected %d)", __LINE__,
              vnCount,
              [boxedWords count],
              [goodBoxedWords count],
              NUMBER_OF_BOXES_FOR_OCR);

        //[self friendlyNote:NSLocalizedString(@"Please retry OCR", nil)];
        return;
    }
  #endif
    
  #ifdef DEBUG_ISSUE_102_VERBOSE
    NSLog(@"==== Line %d, === Sorted boxes: %ld", __LINE__, [goodBoxedWords count]);
    for (NSDictionary *d  in goodBoxedWords)
        NSLog(@"\t dict: %@", d);
  #endif
#endif

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.cameraVC.previewView updateOCRBoxedWords:goodBoxedWords];
        [self.cameraVC.previewView setNeedsDisplay];
    });
    
    // By now we know that we have the correct number of text boxes in the right place and with the right size
    // Let's verify that the text is formatted as expected

    if ([self validateOcrResults:goodBoxedWords]) {

#ifndef TAP_TO_END_CARD_OCR
        //NSLog(@"Line %d, OCR validated", __LINE__);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.cameraVC stopCameraStream];
            [self.cameraVC cancelCamera:nil];
        });

        [[NSNotificationCenter defaultCenter] postNotificationName:@"lastVideoFrameNotification"
                                                                object:nil];
#endif
    }
#ifdef DEBUG_ISSUE_102
    else {
        NSLog(@"Line %d, OCR failed validation", __LINE__);
    }
#endif
}

# pragma mark - Text Detection
// Returns an array with the word bounding boxes with x < 0.3 and y < 0.3
- (NSArray *)visionDetectTextBoundingBoxes:(CIImage*)image
                               orientation:(CGImagePropertyOrientation)orientation
                                boxesCount:(NSUInteger *)vnCount
{
#ifdef DEBUG_ISSUE_102_VERBOSE
    NSLog(@"Line %d, orientation %d", __LINE__, orientation);
#endif
    
    VNRecognizeTextRequest *textRequest = [VNRecognizeTextRequest new];
    textRequest.recognitionLevel = VNRequestTextRecognitionLevelAccurate;
    //textRequest.recognitionLevel = VNRequestTextRecognitionLevelFast;
    textRequest.revision = VNRecognizeTextRequestRevision1;
    textRequest.usesLanguageCorrection = FALSE;
    textRequest.minimumTextHeight = minTextHeight_mm / cardHeight_mm;
    
    // Performs requests on a single image.
    VNImageRequestHandler *handler =
        [[VNImageRequestHandler alloc] initWithCIImage:image
                                           orientation:orientation
                                               options:@{}];
    [handler performRequests:@[textRequest] error:nil];
    
    *vnCount = [textRequest.results count];

    if (!textRequest.results || ([textRequest.results count] == 0)) {
        //NSLog(@"%s line %d, NO textRequest results", __FUNCTION__, __LINE__);
        return @[];
    }

#ifdef DEBUG_ISSUE_102_VERBOSE
    NSLog(@"==== Line %d, === Detected VN textRequest.results: %lu", __LINE__, (unsigned long)[textRequest.results count]);
#endif

    NSMutableArray *boxedWords = [NSMutableArray new];

    unsigned int boxNumber = 0;
    for (VNRecognizedTextObservation *obs in textRequest.results)
    {
        boxNumber++;
        CGRect box = obs.boundingBox;

#ifdef DISCARD_BAD_BOXES

#ifndef CROP_IMAGE_TO_CARD_ROI
        // Discards text in the top area of the card (0 is the top, 1 is the bottom)
  #ifdef VN_BOXES_NEED_XY_SWAP
        if ((box.origin.x) < (cardIgnoreTop_mm/cardHeight_mm))
  #else
        if ((box.origin.y) < (cardIgnoreTop_mm/cardHeight_mm))
  #endif
        {
            #ifdef DEBUG_ISSUE_102_VERBOSE
            NSLog(@"\t --%u-- Skip top because x: %.2f < %.2f", boxNumber, box.origin.x, cardIgnoreTop_mm / cardHeight_mm);
            #endif
            continue;
        }
#endif

#if 1
        // Discard text in the right area of the card
        // Keep only boxes with corner within 14mm strip on the left
  #ifdef CROP_IMAGE_TO_CARD_ROI
        CGFloat thresholdX = cardKeepLeft_mm / (cardROI_W*cardWidth_mm);
  #else
        CGFloat thresholdX = cardKeepLeft_mm / cardWidth_mm;
  #endif

  #ifdef VN_BOXES_NEED_XY_SWAP
        if (box.origin.y > thresholdX)
  #else
        if (box.origin.x > thresholdX)
  #endif
        {
            #ifdef DEBUG_ISSUE_102_VERBOSE
            NSLog(@"\t --%u-- Skip right because y: %.2f > %.2f", boxNumber, box.origin.y, thresholdX);
            #endif
            continue;
        }
#endif

#if 1
        // Discard text smaller than expected
        if (box.size.width < rejectBoxWidthFraction) {
            #ifdef DEBUG_ISSUE_102_VERBOSE
            NSLog(@"\t --%u-- Skip too small because width: %.2f < %.2f", boxNumber, box.size.width, rejectBoxWidthFraction);
            #endif
            continue;
        }
#endif

#if 0
        // Discard text bigger than expected
        // Careful: the box might be big but the "text box" smaller
        if (box.size.width > (rejectBoxWidth_mm / cardWidth_mm)) {
            #ifdef DEBUG_ISSUE_102_VERBOSE
            NSLog(@"\t --%u-- Skip too big", boxNumber);
            #endif
            continue;
        }
#endif
#endif // DISCARD_BAD_BOXES

        //NSLog(@"line %d, class %@", __LINE__, [obs class] ); // VNRecognizedTextObservation
        //NSLog(@"line %d, %@", __LINE__, obs );
#if 0 // show all candidates
        NSArray<VNRecognizedText*> *topCandidates = [obs topCandidates:3]; // (NSUInteger)maxCandidateCount;
        for (VNRecognizedText *t in topCandidates)
            NSLog(@"\t <%@>", t.string);
#endif

        NSArray<VNRecognizedText*> *topCandidates = [obs topCandidates:1];
        NSString *s;
        VNConfidence c = 0;
        CGRect boundBox = CGRectZero;  // text bounding box
        if (topCandidates.count == 0) {
            continue;
        }

        // Use only first candidate

        s = topCandidates[0].string;
        c = topCandidates[0].confidence;
        id bbox = [topCandidates[0] boundingBoxForRange:NSMakeRange(0, s.length) error:nil];
        boundBox = [bbox boundingBox];  // observed that it's >= obs.boundingBox
        //VNRecognizedText *t = topCandidates[0];

#ifdef DISCARD_BAD_BOXES
#if 1
        VNConfidence confidenceThreshold = 0.4f;
        if (c < confidenceThreshold) {
            #ifdef DEBUG_ISSUE_102_VERBOSE
            NSLog(@"\t --%u-- Skip <%@> confidence %.2f less than %.2f", boxNumber, s, c, confidenceThreshold);
            #endif
            continue;
        }
#endif
#if 1
        // Discard boxes whose text contains unwanted characters
        NSCharacterSet *unwantedCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/^•&~!=:(%#_"];
        NSUInteger loc = [s rangeOfCharacterFromSet:unwantedCharacters].location;
        if (loc != NSNotFound) {
            #ifdef DEBUG_ISSUE_102_VERBOSE
            NSLog(@"\t --%u-- Skip <%@> because of '%@'", boxNumber, s, [s substringWithRange:NSMakeRange(loc, 1)]);
            #endif
            continue;
        }
#endif
#if 1
        // Discard boxes that contain unwanted text
        NSArray *unwantedText = @[@"Name", @"Vorname", @"Cognome",
                                  @"Karten",
                                  @"Geburtsdatum", @"Date de",
                                  @"Data di", @"Data da"];
        BOOL foundUnwantedText = NO;
        for (id text in unwantedText)
        {
            if ([s rangeOfString:text].location != NSNotFound) {
                #ifdef DEBUG_ISSUE_102_VERBOSE
                NSLog(@"\t --%u-- Skip <%@> because of <%@>", boxNumber, s, text);
                #endif
                foundUnwantedText = YES;
                break;
            }
        }

        if (foundUnwantedText)
            continue;

        #ifdef DEBUG_ISSUE_102_VERBOSE
        NSLog(@"\t ++%d++ Keep <%@>\n\t\t%@", boxNumber, s, NSStringFromCGRect(box));
        //NSLog(@"\t ++%d++ Keep <%@>", boxNumber, s);
        #endif

#endif
#endif // DISCARD_BAD_BOXES
        
        NSDictionary *dict = @{@"box" : [NSValue valueWithCGRect: box],
                               @"conf": [NSNumber numberWithFloat: c],
                               @"bbx": [NSValue valueWithCGRect: boundBox],
                               @"text": s};
        [boxedWords addObject:dict];
    }
    
    return [boxedWords copy];
}

- (NSArray *)analyzeVisionBoxedWords:(NSArray *)allBoxes
{
    //NSLog(@"%s %@, class: %@", __FUNCTION__, allBoxes, [allBoxes[0] class]); // NSConcreteValue

    NSUInteger n = [allBoxes count];
    if (n < NUMBER_OF_BOXES_FOR_OCR) {
#ifdef DEBUG_ISSUE_102_VERBOSE
        NSLog(@"%s Nothing to do with only %lu boxes", __FUNCTION__, (unsigned long)n);
#endif
        return allBoxes;
    }
    
    // Note: if we have n == NUMBER_OF_BOXES_FOR_OCR we still need to sort them by Y

    NSArray *boxedWords = allBoxes;

    if (n > NUMBER_OF_BOXES_FOR_OCR)
    {
        // Keep only the first 5
        if (n > 5) {
            boxedWords = [allBoxes subarrayWithRange:NSMakeRange(0, 5)];
            //NSLog(@"Keep first 5 %@", boxes);
        }
        
#ifdef DEBUG_ISSUE_102_VERBOSE
        NSLog(@"%s %d, %d boxes to be sorted %@", __FUNCTION__, __LINE__, n, boxedWords);
#endif

        // Sort boxes by height
        boxedWords = [boxedWords sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
            CGRect p1 = [obj1[@"box"] CGRectValue];
            CGRect p2 = [obj2[@"box"] CGRectValue];
#ifdef VN_BOXES_NEED_XY_SWAP
            //  sort them by width for Vision boxes
            if (p1.size.width == p2.size.width)
                return NSOrderedSame;

            return p1.size.width < p2.size.width;
#else
            if (p1.size.height == p2.size.height)
                return NSOrderedSame;

            return p1.size.height < p2.size.height;
#endif
        }];
        //NSLog(@"sorted by height %@", boxedWords);
        
        // Keep only the first NUMBER_OF_BOXES_FOR_OCR
        boxedWords = [boxedWords subarrayWithRange:NSMakeRange(0, NUMBER_OF_BOXES_FOR_OCR)];
        //NSLog(@"Keep first %d %@", NUMBER_OF_BOXES_FOR_OCR, boxedWords);
    }

    // Sort them back by Y
    boxedWords = [boxedWords sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        CGRect p1 = [obj1[@"box"] CGRectValue];
        CGRect p2 = [obj2[@"box"] CGRectValue];
#ifdef VN_BOXES_NEED_XY_SWAP
        if (p1.origin.x == p2.origin.x)
            return NSOrderedSame;

        return p1.origin.x >= p2.origin.x;
#else
        if (p1.origin.y == p2.origin.y)
            return NSOrderedSame;

        return p1.origin.y < p2.origin.y;
#endif
    }];

    //NSLog(@"Sort by Y %@", boxedWords);
    return boxedWords;
}

- (BOOL)validateOcrResults:(NSArray *)ocrResults
{
    if (videoCaptureFinished) {
        #ifdef DEBUG_ISSUE_102
        NSLog(@"%s %d, no validation after videoCaptureFinished", __FUNCTION__, __LINE__);
        #endif
        return NO;
    }
    
    if ([ocrResults count] < NUMBER_OF_BOXES_FOR_OCR) {
        #ifdef DEBUG_ISSUE_102
        NSLog(@"%s %d, wrong number of OCR results", __FUNCTION__, __LINE__);
        #endif
        return NO;
    }

    // Validate first line /////////////////////////////////////////////////////
    NSDictionary *d = ocrResults[0];
    NSString *s = d[@"text"];
    
    NSArray *line1Array = [s componentsSeparatedByString:@","];
    if ([line1Array count] < 2) {
        #ifdef DEBUG_ISSUE_102
        NSLog(@"Line %d, not enough elements in first line: <%@>", __LINE__, line1Array);
        #endif
        return NO;
    }

    NSString *familyName = line1Array[0];
    NSString *givenName = line1Array[1];
    
    if ([givenName length] == 0) {
        #ifdef DEBUG_ISSUE_102
        NSLog(@"Line %d, given name is empty", __LINE__);
        #endif
        return NO;
    }

    // Trim leading space from given name
    if ([givenName length] > 0) {
        if ([[NSCharacterSet whitespaceCharacterSet] characterIsMember:[givenName characterAtIndex:0]])
            givenName = [givenName substringFromIndex:1];
        
//        // Trim trailing '-' from given name
//        if ([givenName hasSuffix:@"-"])
//            givenName = [givenName substringToIndex:[givenName length]-1];
    }

    // Validate second line ////////////////////////////////////////////////////
    // Still unused but it helps to validate it
    d = ocrResults[1];
    NSString *cardNumberString = d[@"text"];
    if ([cardNumberString length] != 20) {
        #ifdef DEBUG_ISSUE_102
        NSLog(@"Line %d, card number wrong size: <%lu>", __LINE__, (unsigned long)[cardNumberString length]);
        #endif
        return NO;
    }
    
    // Check that it contains only numerical digits
    NSCharacterSet *_NumericOnly = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *myStringSet = [NSCharacterSet characterSetWithCharactersInString:cardNumberString];
    if (![_NumericOnly isSupersetOfSet: myStringSet]) {
        #ifdef DEBUG_ISSUE_102
        NSLog(@"Line %d, card number not only digits: <%@>", __LINE__, cardNumberString);
        #endif
        return NO;
    }

    // Validate third line /////////////////////////////////////////////////////
    d = ocrResults[2];
    s = d[@"text"];
    NSArray *line2Array = [s componentsSeparatedByString:@" "];
    if ([line2Array count] < 2) {
        #ifdef DEBUG_ISSUE_102
        NSLog(@"Line %d, possibly missing sex field in third line: <%@>", __LINE__, line2Array);
        #endif
        return NO;
    }
    
    NSString *dateString = line2Array[0];
    // Validate that it contains 3 fields separated by '.'
    NSArray *dateFieldsArray = [dateString componentsSeparatedByString:@"."];
    if ([dateFieldsArray count] < 3) {
        #ifdef DEBUG_ISSUE_102
        NSLog(@"Line %d, bad date: <%@>", __LINE__, dateString);
        #endif
        return NO;
    }
    
    NSString *sexString = line2Array[1];

    if (![sexString isEqualToString:@"M"] &&
        ![sexString isEqualToString:@"F"])
    {
        #ifdef DEBUG_ISSUE_102
        NSLog(@"%s %d, wrong sex %@", __FUNCTION__, __LINE__, sexString);
        #endif
        return NO;
    }

    savedOcr.familyName = familyName;
    savedOcr.givenName = givenName;
    savedOcr.cardNumberString = cardNumberString;
    savedOcr.dateString = dateString;
    savedOcr.sexString = sexString;

#ifdef DEBUG_ISSUE_102_VERBOSE
    NSLog(@"Validated OCR results\n\t Family name <%@>\n\t First name <%@>\n\t Card# <%@>\n\t Birthday <%@>\n\t Sex <%@>",
          familyName,
          givenName,
          cardNumberString,
          dateString,
          sexString);
#endif
    
    return YES;
}

#pragma mark - Notifications
- (void)lastVideoFrame:(NSNotification *)notification
{
    videoCaptureFinished = YES;
    
    // Create a Patient and fill up the edit fields

    Patient *incompletePatient = [Patient new];
    incompletePatient.familyName = savedOcr.familyName;
    incompletePatient.givenName = savedOcr.givenName;
    incompletePatient.birthDate = savedOcr.dateString;
    incompletePatient.uniqueId = [incompletePatient generateUniqueID];
    
    if ([savedOcr.sexString isEqualToString:@"M"])
        incompletePatient.gender = KEY_AMK_PAT_GENDER_M;
    else if ([savedOcr.sexString isEqualToString:@"F"])
        incompletePatient.gender = KEY_AMK_PAT_GENDER_F;

#ifdef TAP_TO_END_CARD_OCR
    [self resetAllFields];
#else
    dispatch_async(dispatch_get_main_queue(), ^{
        [self resetAllFields];
    });
#endif

    // Check it the patient is already in the database
    //NSLog(@"uniqueId %@", incompletePatient.uniqueId);
    
    Patient *existingPatient = [mPatientDb getPatientWithUniqueID:incompletePatient.uniqueId];
    if (existingPatient) {
        // Set as default patient for prescriptions
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:existingPatient.uniqueId forKey:@"currentPatient"];
        [defaults synchronize];

        dispatch_async(dispatch_get_main_queue(), ^{
            MLAppDelegate *appDel = (MLAppDelegate *)[[UIApplication sharedApplication] delegate];
            appDel.editMode = EDIT_MODE_PRESCRIPTION;
            
            UIViewController *nc = self.revealViewController.rearViewController;
            MLViewController *vc = [nc.childViewControllers firstObject];
            [vc switchToPrescriptionView];
        });
    }
    else {
#ifdef TAP_TO_END_CARD_OCR
        [self setAllFields:incompletePatient];

#else
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setAllFields:incompletePatient];
        });
#endif
    }
}
@end
