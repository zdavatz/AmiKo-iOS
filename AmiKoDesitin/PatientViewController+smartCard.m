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

#define NUMBER_OF_BOXES_FOR_TESSERACT   3
//#define WITH_ARRAY_OF_BLACKLISTS

@implementation PatientViewController (smartCard)

- (void) startCameraLivePreview
{
    NSLog(@"%s", __FUNCTION__);
    
//    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
//    UINavigationController *nc = self.navigationController;  // nil
//    NSLog(@"%s self %p, class %@", __FUNCTION__, self, [self class]);
//    NSLog(@"navigationController %@", nc);
//    NSLog(@"rootVC %@ class %@, rootVC.nc %@", rootVC, [rootVC class], rootVC.navigationController);
    
    // Make sure front is PatientViewController
    UIViewController *nc_front = self.revealViewController.frontViewController; // UINavigationController
    UIViewController *vc_front = [nc_front.childViewControllers firstObject];   // PatientViewController
    //NSLog(@"nc_front %@", [nc_front class]);
    //NSLog(@"vc_front %@", [vc_front class]);
    
    if (!self.cameraVC)
        self.cameraVC = nil; // So that it will be reinitialized with the current orientation

    self.cameraVC = [[CameraViewController alloc] initWithNibName:@"CameraViewController"
                                                            bundle:nil];
    self.cameraVC.delegate = self;

    [vc_front presentViewController:self.cameraVC
                           animated:NO
                         completion:NULL];
}

#pragma mark - AVCapturePhotoCaptureDelegate

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput
didFinishProcessingPhoto:(AVCapturePhoto *)photo
                error:(nullable NSError *)error
{
    if ( error ) {
        NSLog( @"Error capturing photo: %@", error );
        return;
    }
    
    [self.cameraVC.previewView updatePoiCornerPosition];
    [self.cameraVC.previewView updateCardFrameFraction];  // from outerCardOutline
    
    NSData *data = [photo fileDataRepresentation];
    UIImage *image = [UIImage imageWithData:data];

#ifdef DEBUG
    //NSLog(@"line %d cardFrameFraction %@", __LINE__, NSStringFromCGRect(self.previewView.cardFrameFraction));
    NSLog(@"%s line %d, imageOrientation %ld", __FUNCTION__, __LINE__, (long)image.imageOrientation);
#endif

    CGFloat x = self.cameraVC.previewView.cardFrameFraction.origin.x;
    CGFloat y = self.cameraVC.previewView.cardFrameFraction.origin.y;
    CGFloat w = self.cameraVC.previewView.cardFrameFraction.size.width;
    CGFloat h = self.cameraVC.previewView.cardFrameFraction.size.height;

    // Crop the image to the health card outline
    CGRect cg_rectCropCard = CGRectMake(x * image.size.width,
                                        y * image.size.height,
                                        w * image.size.width,
                                        h * image.size.height);
    
    //NSLog(@"line %d cropCard %@", __LINE__, NSStringFromCGRect(cg_rectCropCard));
//    NSLog(@"line %d im size %@, ar %.3f", __LINE__,
//          NSStringFromCGSize(image.size),
//          image.size.width/image.size.height);

    UIImage *imageCard = [image cropRectangle:cg_rectCropCard inFrame:image.size];
//    NSLog(@"line %d card size WH: %@, ar %.3f", __LINE__,
//          NSStringFromCGSize(imageCard.size),
//          imageCard.size.width/imageCard.size.height);

    [self resetAllFields];
    
    // Vision, text detection
    CIImage* ciimage = [[CIImage alloc] initWithCGImage:imageCard.CGImage];
    //NSLog(@"line %d card size WH: %@", __LINE__, NSStringFromCGSize(imageCard.size));

    CGImagePropertyOrientation orient;
    
    if (imageCard.imageOrientation == UIImageOrientationRight) {
        orient = kCGImagePropertyOrientationRight; // for portrait
    }
    else if (imageCard.imageOrientation == UIImageOrientationUp) {
        orient = kCGImagePropertyOrientationUp; // for landscape L
    }
    else { //if (imageCard.imageOrientation == UIImageOrientationDown) {
        orient = kCGImagePropertyOrientationDown; // for landscape R
    }

    NSArray *boxes = [self detectTextBoundingBoxes:ciimage orientation:orient];
    NSArray *goodBoxes = [self analyzeVisionBoxes:boxes];

    // We expect to have
    //  goodBoxes[0] FamilyName, GivenName
    //  goodBoxes[1] CardNumber (unused)
    //  goodBoxes[2] Birthday Sex

    if ([goodBoxes count] != NUMBER_OF_BOXES_FOR_TESSERACT) {
        NSLog(@"Detected %ld boxes instead of %d", [goodBoxes count], NUMBER_OF_BOXES_FOR_TESSERACT);
        [self friendlyNote:NSLocalizedString(@"Please retry OCR", nil)];
        return;
    }

//    for (NSValue *v in goodBoxes)
//        NSLog(@"\trect: %@", NSStringFromCGRect(v.CGRectValue));

    @autoreleasepool {

    NSMutableArray *ocrStrings = [NSMutableArray new];
#ifdef WITH_ARRAY_OF_BLACKLISTS
    NSArray *blacklist = [NSArray arrayWithObjects:
                          @"_}\".[]':",
                          @"", //   [NSNull null] will crash
                          @"",
                          nil];
    NSArray *whitelist = [NSArray arrayWithObjects:
                          @"",
                          @"0123456789",
                          @"0123456789. MF",
                          nil];
#endif

    // OCR with tesseract

    G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng+fra"];
    //NSLog(@"%s line %d, engineMode: %lu", __FUNCTION__, __LINE__, (unsigned long)tesseract.engineMode);
    tesseract.delegate = self;
    tesseract.maximumRecognitionTime = 2.0;

    //tesseract.engineMode = G8OCREngineModeTesseractOnly; // fastest (default)
    //tesseract.engineMode = G8OCREngineModeCubeOnly;// better accuracy, but slower
    //tesseract.engineMode = G8OCREngineModeTesseractCubeCombined;// Run both and combine results - best accuracy

#ifndef WITH_ARRAY_OF_BLACKLISTS
    tesseract.charBlacklist = @"_";
#endif

    UIImage *ui_img3 = imageCard;
    
    UIGraphicsBeginImageContextWithOptions(ui_img3.size, NO, ui_img3.scale);
    CGContextRef cg_context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(cg_context);
    
    CGContextSetLineWidth(cg_context, 10.0f);
    CGContextSetStrokeColorWithColor(cg_context, [UIColor blueColor].CGColor);
    
    CGSize cg_size = ui_img3.size;

        int i = 0;
        for (id box in goodBoxes) { // We know we have these many: NUMBER_OF_BOXES_FOR_TESSERACT
        @autoreleasepool {

            const CGFloat margin = 1.0f;
            CGRect cg_r = [box CGRectValue];
            CGRect cg_imageRect = CGRectMake(cg_r.origin.x * cg_size.width - margin, // XYWH
                                             cg_r.origin.y * cg_size.height - margin,
                                             cg_r.size.width * cg_size.width + 2*margin,
                                             cg_r.size.height * cg_size.height + 2*margin);
            CGContextStrokeRect(cg_context, cg_imageRect);
            
            CGRect cg_imageRect2 = CGRectMake(cg_imageRect.origin.x,
                                              ui_img3.size.height - (cg_imageRect.origin.y+cg_imageRect.size.height),
                                              cg_imageRect.size.width,
                                              cg_imageRect.size.height);
            UIImage *tesseractSubImage = [ui_img3 cropRectangle:cg_imageRect2 inFrame:ui_img3.size];
            tesseract.image = tesseractSubImage;

#ifdef WITH_ARRAY_OF_BLACKLISTS
            tesseract.charWhitelist = whitelist[i];
            tesseract.charBlacklist = blacklist[i];
#endif

            [tesseract recognize];    // Start the recognition

            // Add to result array, trimming off the trailing "\n\n"
            [ocrStrings addObject:[[tesseract recognizedText] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
            
            i++;
        }   // autoreleasepool
    } // for
    
#ifdef DEBUG
    NSLog(@"OCR result <%@>", ocrStrings);
#endif

    // Fixup OCR results

    // In some cases instead of the comma it detects a period
    NSString *nameString = [ocrStrings[0] stringByReplacingOccurrencesOfString:@"." withString:@","];

    NSArray *nameArray = [nameString componentsSeparatedByString:@","]; // sometimes we get ",_" instead of ", "
    NSArray *dateArray = [ocrStrings[2] componentsSeparatedByString:@" "];

    if ([nameArray count] < 2 || [dateArray count] < 2) {
        [self resetAllFields];
        [self friendlyNote:NSLocalizedString(@"Please retry OCR", nil)];
        return;
    }

    // Trim leading space from given name
    NSString *givenName = nameArray[1];
    if ([givenName length] > 0) {
        if ([[NSCharacterSet whitespaceCharacterSet] characterIsMember:[givenName characterAtIndex:0]])
            givenName = [givenName substringFromIndex:1];
        
        // Trim trailing '-' from given name
        if ([givenName hasSuffix:@"-"])
            givenName = [givenName substringToIndex:[givenName length]-1];
    }

#ifdef DEBUG
    NSLog(@"Family name <%@>", nameArray[0]);
    NSLog(@"First name <%@>", givenName);
    NSLog(@"Birthday <%@>", dateArray[0]);
    NSLog(@"Sex <%@>", dateArray[1]);
#endif
    
    // Create a Patient and fill up the edit fields

    Patient *incompletePatient = [Patient new];
    incompletePatient.familyName = nameArray[0];
    incompletePatient.givenName = givenName;
    incompletePatient.birthDate = dateArray[0];
    incompletePatient.uniqueId = [incompletePatient generateUniqueID];
    
    if ([dateArray[1] isEqualToString:@"M"])
        incompletePatient.gender = KEY_AMK_PAT_GENDER_M;
    else if ([dateArray[1] isEqualToString:@"F"])
        incompletePatient.gender = KEY_AMK_PAT_GENDER_F;

    [self resetAllFields];

    // Check it the patient is already in the database
    //NSLog(@"uniqueId %@", incompletePatient.uniqueId);
    
    Patient *existingPatient = [mPatientDb getPatientWithUniqueID:incompletePatient.uniqueId];
    if (existingPatient) {
        // Set as default patient for prescriptions
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:existingPatient.uniqueId forKey:@"currentPatient"];
        [defaults synchronize];
        
#ifdef DEBUG_ISSUE_86
        NSLog(@"%s %d define currentPatient ID %@", __FUNCTION__, __LINE__, existingPatient.uniqueId);
#endif

        MLAppDelegate *appDel = (MLAppDelegate *)[[UIApplication sharedApplication] delegate];
        appDel.editMode = EDIT_MODE_PRESCRIPTION;
        
        UIViewController *nc = self.revealViewController.rearViewController;
        MLViewController *vc = [nc.childViewControllers firstObject];
        [vc switchToPrescriptionView];
    }
    else
        [self setAllFields:incompletePatient];

        
    // Clean up

    tesseract = nil;
    // Try to call 'clearCache' after all the tesseract instances are completely deallocated
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        [G8Tesseract clearCache];
    });

    [ocrStrings removeAllObjects];
    ocrStrings = nil;
        
    } // autoreleasepool
}

# pragma mark - Text Detection
// Returns an array with the word bounding boxes with x < 0.3 and y < 0.3
- (NSArray *)detectTextBoundingBoxes:(CIImage*)image
                         orientation:(CGImagePropertyOrientation)orientation
{
    NSMutableArray *words = [NSMutableArray new];

    VNDetectTextRectanglesRequest *textRequest = [VNDetectTextRectanglesRequest new];
    textRequest.reportCharacterBoxes = NO;
    
    // Performs requests on a single image.
    VNImageRequestHandler *handler =
        [[VNImageRequestHandler alloc] initWithCIImage:image
                                           orientation:orientation
                                               options:@{}];
    [handler performRequests:@[textRequest] error:nil];
    
//#ifdef DEBUG
//    if (!textRequest.results)
//        NSLog(@"%s line %d, textRequest.results: nil", __FUNCTION__, __LINE__);
//    else
//        NSLog(@"%s line %d, textRequest.results: %lu", __FUNCTION__, __LINE__, (unsigned long)[textRequest.results count]);
//#endif
    
    for (VNTextObservation *observation in textRequest.results) {
        
        CGRect boundingBoxWord = observation.boundingBox;

        // Discards text in the top area of the card
        if (boundingBoxWord.origin.y > 0.352f)   // 0 is bottom of the card, 1 top
            continue;
        
        // Discard text in the right area of the card
        if (boundingBoxWord.origin.x > 0.3)
            continue;

        [words addObject:[NSValue valueWithCGRect: boundingBoxWord]];
    }
    
    return words;
}

- (NSArray *)analyzeVisionBoxes:(NSArray *)allBoxes
{
    //NSLog(@"%s %@, class: %@", __FUNCTION__, allBoxes, [allBoxes[0] class]); // NSConcreteValue

    NSUInteger n = [allBoxes count];
    if (n <= NUMBER_OF_BOXES_FOR_TESSERACT) {
        NSLog(@"%s Nothing to do with only %lu boxes", __FUNCTION__, (unsigned long)n);
        return allBoxes;
    }

    NSArray *boxes = allBoxes;

    // Keep only the first 5 (sorted by Y)
    if (n > 5) {
        boxes = [allBoxes subarrayWithRange:NSMakeRange(0, 5)];
        //NSLog(@"Keep first 5 %@", boxes);
    }
    
    // Sort boxes by vertical size
    boxes = [boxes sortedArrayUsingComparator:^NSComparisonResult(NSValue *obj1, NSValue *obj2) {
        CGRect p1 = [obj1 CGRectValue];
        CGRect p2 = [obj2 CGRectValue];
        if (p1.size.height == p2.size.height)
            return NSOrderedSame;
        
        return p1.size.height < p2.size.height;
    }];
    //NSLog(@"sorted by height %@", boxes);
    
    // Keep only the first NUMBER_OF_BOXES_FOR_TESSERACT
    boxes = [boxes subarrayWithRange:NSMakeRange(0, NUMBER_OF_BOXES_FOR_TESSERACT)];
    //NSLog(@"Keep first %d %@", NUMBER_OF_BOXES_FOR_TESSERACT, boxes);

    // Sort them back by Y
    boxes = [boxes sortedArrayUsingComparator:^NSComparisonResult(NSValue *obj1, NSValue *obj2) {
        CGRect p1 = [obj1 CGRectValue];
        CGRect p2 = [obj2 CGRectValue];
        if (p1.origin.y == p2.origin.y)
            return NSOrderedSame;
        
        return p1.origin.y < p2.origin.y;
    }];
    //NSLog(@"Sort by Y %@", boxes);

    return boxes;
}

@end
