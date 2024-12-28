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
#import "MLPersistenceManager.h"

#define DISCARD_BAD_BOXES

@implementation PatientViewController (smartCard)

- (void) startCameraLivePreview
{
    videoCaptureFinished = NO;

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
    if (videoCaptureFinished)
        return;

//    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];

    // TODO: maybe we don't need to set this here everytime

    dispatch_async(dispatch_get_main_queue(), ^{
        UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
        if ([connection isVideoOrientationSupported]) {
            if (statusBarOrientation == UIInterfaceOrientationPortrait)  // 1 ok
            {
                [connection setVideoOrientation: AVCaptureVideoOrientationPortrait];
            }
            else if (statusBarOrientation == UIInterfaceOrientationLandscapeRight)  // 3 ok
            {
                [connection setVideoOrientation: AVCaptureVideoOrientationLandscapeRight];
            }
            else if (statusBarOrientation == UIInterfaceOrientationLandscapeLeft)  // 4
            {
                [connection setVideoOrientation: AVCaptureVideoOrientationLandscapeLeft]; //upside down
                //[connection setVideoOrientation: AVCaptureVideoOrientationLandscapeRight];
            }
            else
            {
                [connection setVideoOrientation: AVCaptureVideoOrientationPortrait];
            }
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
        return;
    }
    
    // Vision, text detection
    CIImage* ciimage = [[CIImage alloc] initWithCGImage:imageCropped.CGImage];
    if (!ciimage) {
        return;
    }

    // Try ignoring the video orientation (always 0) and use the screen orientation
    __block UIInterfaceOrientation interfaceOrient;
    dispatch_async(dispatch_get_main_queue(), ^{
        interfaceOrient = [UIApplication sharedApplication].statusBarOrientation;
    });
    CGImagePropertyOrientation orient;
    if (interfaceOrient == UIInterfaceOrientationLandscapeRight) {
        orient = kCGImagePropertyOrientationRight; // for portrait
    }
    else if (interfaceOrient == UIInterfaceOrientationPortrait) {
        orient = kCGImagePropertyOrientationUp; // for landscape L  // always this one ?
    }
    else if (interfaceOrient == UIInterfaceOrientationLandscapeLeft) {
        orient = kCGImagePropertyOrientationLeft; // for landscape R
    }
    else {
        orient = kCGImagePropertyOrientationUp;
    }

    NSUInteger vnCount;
    NSArray *boxedWords = [self visionDetectTextBoundingBoxes:ciimage orientation:orient boxesCount:&vnCount];

    if ([boxedWords count] == 0) {
        return;
    }

    NSArray *goodBoxedWords = [self analyzeVisionBoxedWords:boxedWords];
    
    // We expect to have
    //  goodBoxes[0] FamilyName, GivenName
    //  goodBoxes[1] CardNumber (unused)
    //  goodBoxes[2] Birthday Sex

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
}

# pragma mark - Text Detection
// Returns an array with the word bounding boxes with x < 0.3 and y < 0.3
- (NSArray *)visionDetectTextBoundingBoxes:(CIImage*)image
                               orientation:(CGImagePropertyOrientation)orientation
                                boxesCount:(NSUInteger *)vnCount
{
    NSError *error = nil;
    NSArray *langs = [VNRecognizeTextRequest supportedRecognitionLanguagesForTextRecognitionLevel:VNRequestTextRecognitionLevelAccurate
                                                                        revision:VNRecognizeTextRequestRevision1
                                                                                            error:&error];
//    NSLog(@"%@", langs);
    
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
        return @[];
    }

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
            continue;
        }
#endif

#endif // DISCARD_BAD_BOXES

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
            BOOL shouldSkip = YES;
            // Handle BAG number, which is not at the right side of the card
            // 5 digit and all number
            if (s.length == 5 && [[NSString stringWithFormat:@"%05d",[s intValue]] isEqual:s]) {
                if (box.origin.x < 0.9) {
                    shouldSkip = NO;
                }
            } else if (s.length == 16) {
                NSError *error = nil;
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[0-9]{3}\\.[0-9]{4}\\.[0-9]{4}\\.[0-9]{2}$" options:0 error:&error];
                NSTextCheckingResult *match = [regex firstMatchInString:s options:0 range:NSMakeRange(0, s.length)];
                if (match) {
                    shouldSkip = NO;
                }
            }
            if (shouldSkip) {
                continue;
            }
        }

        // Discard text smaller than expected
        if (box.size.width < rejectBoxWidthFraction) {
            continue;
        }
        
#ifdef DISCARD_BAD_BOXES
        VNConfidence confidenceThreshold = 0.4f;
        if (c < confidenceThreshold) {
            continue;
        }
        // Discard boxes whose text contains unwanted characters
        NSCharacterSet *unwantedCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/^•&~!=:(%#_"];
        NSUInteger loc = [s rangeOfCharacterFromSet:unwantedCharacters].location;
        if (loc != NSNotFound) {
            continue;
        }
        // Discard boxes that contain unwanted text
        NSArray *unwantedText = @[@"Name", @"Vorname", @"Cognome",
                                  @"Karten",
                                  @"Geburtsdatum", @"Date de",
                                  @"Data di", @"Data da"];
        BOOL foundUnwantedText = NO;
        for (id text in unwantedText)
        {
            if ([s rangeOfString:text].location != NSNotFound) {
                foundUnwantedText = YES;
                break;
            }
        }

        if (foundUnwantedText)
            continue;
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
    NSUInteger n = [allBoxes count];
    if (n < NUMBER_OF_BOXES_FOR_OCR) {
        return allBoxes;
    }
    
    // Note: if we have n == NUMBER_OF_BOXES_FOR_OCR we still need to sort them by Y

    NSArray *boxedWords = allBoxes;

    if (n > NUMBER_OF_BOXES_FOR_OCR)
    {
        // Keep only the first 5
        if (n > 5) {
            boxedWords = [allBoxes subarrayWithRange:NSMakeRange(0, 5)];
        }

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
        
        // Keep only the first NUMBER_OF_BOXES_FOR_OCR
        boxedWords = [boxedWords subarrayWithRange:NSMakeRange(0, NUMBER_OF_BOXES_FOR_OCR)];
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
    
    // At this point, the first one should be name, last one should be date string,
    // but we are not sure about the middle ones, at they are layed out horizontally
    NSDictionary *name = [boxedWords firstObject];
    NSDictionary *dateString = [boxedWords lastObject];
    
    boxedWords = [boxedWords subarrayWithRange:NSMakeRange(1, NUMBER_OF_BOXES_FOR_OCR - 2)];
    boxedWords = [boxedWords sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        CGRect p1 = [obj1[@"box"] CGRectValue];
        CGRect p2 = [obj2[@"box"] CGRectValue];
#ifdef VN_BOXES_NEED_XY_SWAP
        if (p1.origin.y == p2.origin.y)
            return NSOrderedSame;

        return p1.origin.y >= p2.origin.y;
#else
        if (p1.origin.x == p2.origin.x)
            return NSOrderedSame;

        return p1.origin.x >= p2.origin.x;
#endif
    }];
    boxedWords = [@[name] arrayByAddingObjectsFromArray:[boxedWords arrayByAddingObject:dateString]];

    return boxedWords;
}

- (BOOL)validateOcrResults:(NSArray *)ocrResults
{
    if (videoCaptureFinished) {
        return NO;
    }
    
    if ([ocrResults count] < NUMBER_OF_BOXES_FOR_OCR) {
        return NO;
    }

    // Validate first line /////////////////////////////////////////////////////
    NSDictionary *d = ocrResults[0];
    NSString *s = d[@"text"];
    
    NSArray *line1Array = [s componentsSeparatedByString:@","];
    if ([line1Array count] < 2) {
        return NO;
    }

    NSString *familyName = line1Array[0];
    NSString *givenName = line1Array[1];
    
    if ([givenName length] == 0) {
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
        return NO;
    }
    
    // Check that it contains only numerical digits
    NSCharacterSet *_NumericOnly = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *myStringSet = [NSCharacterSet characterSetWithCharactersInString:cardNumberString];
    if (![_NumericOnly isSupersetOfSet: myStringSet]) {
        return NO;
    }
    
    NSString *bagNumber = ocrResults[2][@"text"];
    NSString *ahvNumber = ocrResults[3][@"text"];

    // Validate third line /////////////////////////////////////////////////////
    d = ocrResults[4];
    s = d[@"text"];
    NSArray *line2Array = [s componentsSeparatedByString:@" "];
    if ([line2Array count] < 2) {
        return NO;
    }
    
    NSString *dateString = line2Array[0];
    // Validate that it contains 3 fields separated by '.'
    NSArray *dateFieldsArray = [dateString componentsSeparatedByString:@"."];
    if ([dateFieldsArray count] < 3) {
        return NO;
    }
    
    NSString *sexString = line2Array[1];

    if (![sexString isEqualToString:@"M"] &&
        ![sexString isEqualToString:@"F"])
    {
        return NO;
    }

    savedOcr.familyName = familyName;
    savedOcr.givenName = givenName;
    savedOcr.cardNumberString = cardNumberString;
    savedOcr.dateString = dateString;
    savedOcr.sexString = sexString;
    savedOcr.bagNumber = bagNumber;
    savedOcr.ahvNumber = ahvNumber;
    
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
    incompletePatient.healthCardNumber = savedOcr.cardNumberString;
    incompletePatient.insuranceGLN = [self bagNumberToInsuranceGLN:savedOcr.bagNumber];
    
    if ([savedOcr.sexString isEqualToString:@"M"])
        incompletePatient.gender = KEY_AMK_PAT_GENDER_M;
    else if ([savedOcr.sexString isEqualToString:@"F"])
        incompletePatient.gender = KEY_AMK_PAT_GENDER_F;
    
    NSLog(@"ahv %@", savedOcr.ahvNumber);

#ifdef TAP_TO_END_CARD_OCR
    [self resetAllFields];
#else
    dispatch_async(dispatch_get_main_queue(), ^{
        [self resetAllFields];
    });
#endif

    // Check it the patient is already in the database
    
    Patient *existingPatient = [[MLPersistenceManager shared] getPatientWithUniqueID:incompletePatient.uniqueId];
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

- (NSString *)bagNumberToInsuranceGLN:(NSString *)bagNumber {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"bag-to-insurance-gln" ofType:@"json"];
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    NSDictionary *mapping = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSString *key = [NSString stringWithFormat:@"%d", bagNumber.intValue];
    return mapping[key];
}
@end
