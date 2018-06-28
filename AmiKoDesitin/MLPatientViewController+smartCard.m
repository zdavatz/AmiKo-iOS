//
//  MLPatientViewController+smartCard.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 15/06/2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLPatientViewController+smartCard.h"
#import "UIImage+Cropping.h"
@import Vision;
#import <time.h>
#import "MLViewController.h"
#import "SWRevealViewController.h"
#import "MLAppDelegate.h"

@implementation MLPatientViewController (smartCard)

- (void) startCameraLivePreview
{
    NSLog(@"%s", __FUNCTION__);
    
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    UINavigationController *nc = self.navigationController;  // nil
    NSLog(@"%s self %p, class %@", __FUNCTION__, self, [self class]);
    NSLog(@"navigationController %@", nc);
    NSLog(@"rootVC %@ class %@, rootVC.nc %@", rootVC, [rootVC class], rootVC.navigationController);
    
    // Make sure front is MLPatientViewController
    UIViewController *nc_front = self.revealViewController.frontViewController; // UINavigationController
    UIViewController *vc_front = [nc_front.childViewControllers firstObject];   // MLPatientViewController
    NSLog(@"nc_front %@", [nc_front class]);
    NSLog(@"vc_front %@", [vc_front class]);
    
    if (!self.camVC)
        self.camVC = [[CameraViewController alloc] initWithNibName:@"CameraViewController"
                                                            bundle:nil];
    
    [vc_front presentViewController:self.camVC
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
    
    NSData *data = [photo fileDataRepresentation];
    UIImage *image = [UIImage imageWithData:data];
    UIImage *imageCard;

    //NSLog(@"line %d cardFramePercent %@", __LINE__, NSStringFromCGRect(self.previewView.cardFramePercent));

    CGFloat xPercent = self.camVC.previewView.cardFramePercent.origin.x;
    CGFloat yPercent = self.camVC.previewView.cardFramePercent.origin.y;
    CGFloat wPercent = self.camVC.previewView.cardFramePercent.size.width;
    CGFloat hPercent = self.camVC.previewView.cardFramePercent.size.height;
    // Crop the image to the health card outline
    CGRect cg_rectCropCard = CGRectMake((xPercent / 100.0f) * image.size.width,
                                        (yPercent / 100.0f) * image.size.height,
                                        (wPercent / 100.0f) * image.size.width,
                                        (hPercent / 100.0f) * image.size.height);
    
    //NSLog(@"line %d cropCard %@", __LINE__, NSStringFromCGRect(cg_rectCropCard));
//    NSLog(@"line %d im size %@, ar %.3f", __LINE__,
//          NSStringFromCGSize(image.size),
//          image.size.width/image.size.height);
    imageCard = [image cropRectangle:cg_rectCropCard inFrame:image.size];
//    NSLog(@"line %d card size WH: %@, ar %.3f", __LINE__,
//          NSStringFromCGSize(imageCard.size),
//          imageCard.size.width/imageCard.size.height);

    // Vision, text detection
    CIImage* ciimage = [[CIImage alloc] initWithCGImage:imageCard.CGImage];
    //NSLog(@"line %d card size WH: %@", __LINE__, NSStringFromCGSize(imageCard.size));

    [self resetAllFields];

    NSArray *boxes = [self detectTextBoundingBoxes:ciimage];
    NSArray *goodBoxes = [self analyzeVisionBoxes:boxes];
    // We expect to have
    //  goodBoxes[0] FamilyName, GivenName
    //  goodBoxes[1] CardNumber (unused)
    //  goodBoxes[2] Birthday Sex
    if ([goodBoxes count] < 3) {
        NSLog(@"line %d only %ld boxes", __LINE__, [goodBoxes count]);
        [self friendlyNote:NSLocalizedString(@"Please retry OCR", nil)];
        return;
    }

    @autoreleasepool {

    NSMutableArray *ocrStrings = [[NSMutableArray alloc] init];

#if 1
    // OCR with tesseract

    G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng+fra"];
    tesseract.delegate = self;
    tesseract.maximumRecognitionTime = 2.0;
    tesseract.charBlacklist = @"_";
    //tesseract.engineMode = G8OCREngineModeTesseractCubeCombined; // G8OCREngineModeTesseractOnly
    
    UIImage *ui_img3 = imageCard;
    
    UIGraphicsBeginImageContextWithOptions(ui_img3.size, NO, ui_img3.scale);
    CGContextRef cg_context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(cg_context);
    
    CGContextSetLineWidth(cg_context, 10.0f);
    CGContextSetStrokeColorWithColor(cg_context, [UIColor blueColor].CGColor);
    
    CGSize cg_size = ui_img3.size;

    for (id box in goodBoxes){
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
            
            [tesseract recognize];    // Start the recognition

            // Add to result array, trimming off the trailing "\n\n"
            [ocrStrings addObject:[[tesseract recognizedText] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
        }   // autoreleasepool
    }
    
#ifdef DEBUG
    NSLog(@"OCR result <%@>", ocrStrings);
#endif
#endif // OCR with tesseract

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
    NSString *giveName = nameArray[1];
    if ([[NSCharacterSet whitespaceCharacterSet] characterIsMember:[giveName characterAtIndex:0]])
        giveName = [giveName substringFromIndex:1];

    // Trim trailing '-' from given name
    if (([giveName length] > 0) && [giveName hasSuffix:@"-"])
        giveName = [giveName substringToIndex:[giveName length]-1];

#ifdef DEBUG
    NSLog(@"Family name <%@>", nameArray[0]);
    NSLog(@"First name <%@>", giveName);
    NSLog(@"Birthday <%@>", dateArray[0]);
    NSLog(@"Sex <%@>", dateArray[1]);
#endif
    
    // Create a MLPatient and fill up the edit fields

    MLPatient *incompletePatient = [[MLPatient alloc] init];
    incompletePatient.familyName = nameArray[0];
    incompletePatient.givenName = giveName;
    incompletePatient.birthDate = dateArray[0];
    incompletePatient.uniqueId = [incompletePatient generateUniqueID];
    
    if ([dateArray[1] isEqualToString:@"M"])
        incompletePatient.gender = KEY_AMK_PAT_GENDER_M;
    else if ([dateArray[1] isEqualToString:@"F"])
        incompletePatient.gender = KEY_AMK_PAT_GENDER_F;

    [self resetAllFields];

    // Check it the patient is already in the database
    //NSLog(@"uniqueId %@", incompletePatient.uniqueId);
    
    MLPatient *existingPatient = [mPatientDb getPatientWithUniqueID:incompletePatient.uniqueId];
    if (existingPatient) {
        // Set as default patient for prescriptions
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:existingPatient.uniqueId forKey:@"currentPatient"];
        [defaults synchronize];

        MLAppDelegate *appDel = (MLAppDelegate *)[[UIApplication sharedApplication] delegate];
        appDel.editMode = EDIT_MODE_PRESCRIPTION;
        
        UIViewController *nc = self.revealViewController.rearViewController;
        MLViewController *vc = [nc.childViewControllers firstObject];
        [vc switchToPrescriptionView];
    }
    else
        [self setAllFields:incompletePatient];

        
    // Clean up

    //ciimage = nil;

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

# pragma mark Text Detection
// Returns an array with the word bounding boxes with x < 0.3 and y < 0.3
- (NSArray *)detectTextBoundingBoxes:(CIImage*)image
{
    NSMutableArray *words = [[NSMutableArray alloc] init];

    VNDetectTextRectanglesRequest *textRequest = [VNDetectTextRectanglesRequest new];
    textRequest.reportCharacterBoxes = NO;
    
    // Performs requests on a single image.
    VNImageRequestHandler *handler =
        [[VNImageRequestHandler alloc] initWithCIImage:image
                                           orientation:kCGImagePropertyOrientationRight
                                               options:@{}];
    [handler performRequests:@[textRequest] error:nil];
    
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
    if (n <= 3) {
        NSLog(@"%s Nothing to do with only %lu boxes", __FUNCTION__, (unsigned long)n);
        return allBoxes;
    }

    NSArray *boxes = allBoxes;

    // Keep only the first 5 (sorted by Y)
    if (n > 5) {
        boxes = [allBoxes subarrayWithRange:NSMakeRange(0, 5)];
        //NSLog(@"Keep first 5 %@", boxes);
    }
    
    // Sort boxes by height
    boxes = [boxes sortedArrayUsingComparator:^NSComparisonResult(NSValue *obj1, NSValue *obj2) {
        CGRect p1 = [obj1 CGRectValue];
        CGRect p2 = [obj2 CGRectValue];
        if (p1.size.height == p2.size.height)
            return NSOrderedSame;
        
        return p1.size.height < p2.size.height;
    }];
    //NSLog(@"sorted by height %@", boxes);
    
    // Keep only the first 3
    boxes = [boxes subarrayWithRange:NSMakeRange(0, 3)];
    //NSLog(@"Keep first 3 %@", boxes);

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
