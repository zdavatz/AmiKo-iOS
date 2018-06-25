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

static void * SessionRunningContext = &SessionRunningContext;

@implementation MLPatientViewController (smartCard)

- (void) initCamera
{
    NSLog(@"%s", __FUNCTION__);

#ifdef DEBUG
    [self.previewView setBackgroundColor:[UIColor magentaColor]];
#endif
    
    // Create the AVCaptureSession.
    self.session = [[AVCaptureSession alloc] init];
    
    // Create a device discovery session.
    NSArray<AVCaptureDeviceType> *deviceTypes = @[AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInDualCamera];

    self.videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession
            discoverySessionWithDeviceTypes:deviceTypes
                                  mediaType:AVMediaTypeVideo
                                   position:AVCaptureDevicePositionUnspecified];
    
    // Set up the preview view.
    self.previewView.session = self.session;
    
    // Communicate with the session and other session objects on this queue.
    self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
    
    self.setupResult = AVCamSetupResultSuccess;
    
    switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] )
    {
        case AVAuthorizationStatusAuthorized:
        {
            // The user has previously granted access to the camera.
            break;
        }
        case AVAuthorizationStatusNotDetermined:
        {
            /*
             The user has not yet been presented with the option to grant
             video access. We suspend the session queue to delay session
             setup until the access request has completed.
             
             Note that audio access will be implicitly requested when we
             create an AVCaptureDeviceInput for audio during session setup.
             */
            dispatch_suspend( self.sessionQueue );
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                if ( ! granted ) {
                    self.setupResult = AVCamSetupResultCameraNotAuthorized;
                }
                dispatch_resume( self.sessionQueue );
            }];
            break;
        }
        default:
        {
            // The user has previously denied access.
            self.setupResult = AVCamSetupResultCameraNotAuthorized;
            break;
        }
    }
    
    dispatch_async( self.sessionQueue, ^{
        [self configureSession];
    } );
}

- (void) startCameraStream
{
    dispatch_async( self.sessionQueue, ^{
        switch ( self.setupResult )
        {
            case AVCamSetupResultSuccess:
            {
                // Only setup observers and start the session running if setup succeeded.
                [self addObservers];
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
                break;
            }
            case AVCamSetupResultCameraNotAuthorized:
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"AmiKoDesitin doesn't have permission to use the camera, please change privacy settings", @"Alert message when the user has denied access to the camera" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AmiKoDesitin" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    // Provide quick access to Settings.
                    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Settings", @"Alert button to open Settings" ) style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                    }];
                    [alertController addAction:settingsAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } );
                break;
            }
            case AVCamSetupResultSessionConfigurationFailed:
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"Unable to capture media", @"Alert message when something goes wrong during capture session configuration" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AmiKoDesitin" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } );
                break;
            }
        }
    } );
}

- (void)stopCameraStream
{
    dispatch_async( self.sessionQueue, ^{
        if ( self.setupResult == AVCamSetupResultSuccess ) {
            [self.session stopRunning];
            [self removeObservers];
        }
    } );

}

- (void) startCameraLivePreview
{
    CGRect frame = self.view.frame;
#ifdef DEBUG
    NSLog(@"%s frame %@", __FUNCTION__, NSStringFromCGRect(frame));
    NSLog(@"%p, previewView.frame %@",
          self.previewView, NSStringFromCGRect(self.previewView.frame));
#endif
    
    if (!self.session.isRunning) {
        self.previewView.hidden = NO;
        [self startCameraStream];
    }
}

// Call this on the session queue.
- (void)configureSession
{
    //NSLog(@"%s", __FUNCTION__);

    if ( self.setupResult != AVCamSetupResultSuccess ) {
        return;
    }
    
    NSError *error = nil;
    
    [self.session beginConfiguration];
    
    /*
     We do not create an AVCaptureMovieFileOutput when setting up the session because the
     AVCaptureMovieFileOutput does not support movie recording with AVCaptureSessionPresetPhoto.
     */
    self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    
    // Add video input.
    
    AVCaptureDevice *videoDevice = [AVCaptureDevice
            defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
                              mediaType:AVMediaTypeVideo
                              position:AVCaptureDevicePositionBack];

    if ( ! videoDevice ) {
        NSLog(@"Could not create video device");
        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.session commitConfiguration];
        return;
    }

    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if ( ! videoDeviceInput ) {
        NSLog( @"Could not create video device input: %@", error );
        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.session commitConfiguration];
        return;
    }

    if ( [self.session canAddInput:videoDeviceInput] )
    {
        [self.session addInput:videoDeviceInput];
        self.videoDeviceInput = videoDeviceInput;
        
        dispatch_async( dispatch_get_main_queue(), ^{
            /*
             Why are we dispatching this to the main queue?
             Because AVCaptureVideoPreviewLayer is the backing layer for AVCamPreviewView and UIView
             can only be manipulated on the main thread.
             Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
             on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
             
             Use the status bar orientation as the initial video orientation. Subsequent orientation changes are
             handled by -[AVCamCameraViewController viewWillTransitionToSize:withTransitionCoordinator:].
             */
            UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
            AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
            if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
                initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
            }
            
            self.previewView.videoPreviewLayer.connection.videoOrientation = initialVideoOrientation;
            
            // Rather than resizing the view to fit the camera aspect ratio, we tell the camera to fit the view
            self.previewView.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        } );
    }
    else {
        NSLog( @"Could not add video device input to the session" );
        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.session commitConfiguration];
        return;
    }
    
    // Add photo output.
    AVCapturePhotoOutput *photoOutput = [[AVCapturePhotoOutput alloc] init];
    if ( [self.session canAddOutput:photoOutput] ) {
        [self.session addOutput:photoOutput];
        self.photoOutput = photoOutput;
        
        self.photoOutput.highResolutionCaptureEnabled = YES;
        self.photoOutput.livePhotoCaptureEnabled = self.photoOutput.livePhotoCaptureSupported;

        if (@available(iOS 11, *))
            self.photoOutput.depthDataDeliveryEnabled = self.photoOutput.depthDataDeliverySupported;
        
        self.livePhotoMode = self.photoOutput.livePhotoCaptureSupported ? AVCamLivePhotoModeOn : AVCamLivePhotoModeOff;
        
        if (@available(iOS 11, *))
            self.depthDataDeliveryMode = self.photoOutput.depthDataDeliverySupported ? AVCamDepthDataDeliveryModeOn : AVCamDepthDataDeliveryModeOff;
        
        
        //self.inProgressPhotoCaptureDelegates = [NSMutableDictionary dictionary];
        self.inProgressLivePhotoCapturesCount = 0;
    }
    else {
        NSLog( @"Could not add photo output to the session" );
        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.session commitConfiguration];
        return;
    }
    
    self.backgroundRecordingID = UIBackgroundTaskInvalid;
    
    [self.session commitConfiguration];
}

#pragma mark - AVCapturePhotoCaptureDelegate

#pragma mark KVO and Notifications

- (void)addObservers
{
    [self.session addObserver:self
                   forKeyPath:@"running"
                      options:NSKeyValueObservingOptionNew
                      context:SessionRunningContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(subjectAreaDidChange:)
                                                 name:AVCaptureDeviceSubjectAreaDidChangeNotification
                                               object:self.videoDeviceInput.device];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sessionRuntimeError:)
                                                 name:AVCaptureSessionRuntimeErrorNotification
                                               object:self.session];
    
    /*
     A session can only run when the app is full screen. It will be interrupted
     in a multi-app layout, introduced in iOS 9, see also the documentation of
     AVCaptureSessionInterruptionReason. Add observers to handle these session
     interruptions and show a preview is paused message. See the documentation
     of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
     */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sessionWasInterrupted:)
                                                 name:AVCaptureSessionWasInterruptedNotification
                                               object:self.session];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sessionInterruptionEnded:)
                                                 name:AVCaptureSessionInterruptionEndedNotification
                                               object:self.session];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.session removeObserver:self forKeyPath:@"running" context:SessionRunningContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ( context == SessionRunningContext ) {
#ifdef DEBUG
        BOOL isSessionRunning = [change[NSKeyValueChangeNewKey] boolValue];
        BOOL livePhotoCaptureSupported = self.photoOutput.livePhotoCaptureSupported;
        BOOL livePhotoCaptureEnabled = self.photoOutput.livePhotoCaptureEnabled;
        BOOL depthDataDeliverySupported = self.photoOutput.depthDataDeliverySupported;
        BOOL depthDataDeliveryEnabled = self.photoOutput.depthDataDeliveryEnabled;
        //NSLog(@"%s %d %d %d %d %d", __FUNCTION__, isSessionRunning, livePhotoCaptureSupported, livePhotoCaptureEnabled, depthDataDeliverySupported, depthDataDeliveryEnabled);
#endif
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *device = self.videoDeviceInput.device;
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            /*
             Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
             Call set(Focus/Exposure)Mode() to apply the new point of interest.
             */
            if ( device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode] ) {
                device.focusPointOfInterest = point;
                device.focusMode = focusMode;
            }
            
            if ( device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode] ) {
                device.exposurePointOfInterest = point;
                device.exposureMode = exposureMode;
            }
            
            device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
            [device unlockForConfiguration];
        }
        else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    } );
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
    CGPoint devicePoint = CGPointMake( 0.5, 0.5 );
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus
         exposeWithMode:AVCaptureExposureModeContinuousAutoExposure
          atDevicePoint:devicePoint
monitorSubjectAreaChange:NO];
}

- (void)sessionRuntimeError:(NSNotification *)notification
{
    NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
    NSLog( @"Capture session runtime error: %@", error );
    
    /*
     Automatically try to restart the session running if media services were
     reset and the last start running succeeded. Otherwise, enable the user
     to try to resume the session running.
     */
    if ( error.code == AVErrorMediaServicesWereReset ) {
        dispatch_async( self.sessionQueue, ^{
            if ( self.isSessionRunning ) {
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
#if 1
                AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettings];
                [self.photoOutput capturePhotoWithSettings:photoSettings
                                                  delegate:self];
#endif
            }
        } );
    }
}

- (void)sessionWasInterrupted:(NSNotification *)notification
{
    /*
     In some scenarios we want to enable the user to resume the session running.
     For example, if music playback is initiated via control center while
     using AmiKoDesitin, then the user can let AmiKoDesitin resume
     the session running, which will stop music playback. Note that stopping
     music playback in control center will not automatically resume the session
     running. Also note that it is not always possible to resume, see -[resumeInterruptedSession:].
     */
    
    AVCaptureSessionInterruptionReason reason = [notification.userInfo[AVCaptureSessionInterruptionReasonKey] integerValue];

    NSLog( @"Capture session was interrupted with reason %ld", (long)reason );
}

- (void)sessionInterruptionEnded:(NSNotification *)notification
{
    NSLog( @"Capture session interruption ended" );
}

#pragma mark - UIGestureRecognizerDelegate

- (IBAction) handleTap:(UITapGestureRecognizer *)gesture
{
    if (!self.session.isRunning)
        return;

    //NSLog(@"%s orient: %ld", __FUNCTION__, (long)[[UIDevice currentDevice] orientation]);
    
    // Acquire image
    AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettings];
    [self.photoOutput capturePhotoWithSettings:photoSettings
                                      delegate:self];
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

    CGFloat xPercent = self.previewView.cardFramePercent.origin.x;
    CGFloat yPercent = self.previewView.cardFramePercent.origin.y;
    CGFloat wPercent = self.previewView.cardFramePercent.size.width;
    CGFloat hPercent = self.previewView.cardFramePercent.size.height;
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

    // Dismiss camera
    self.previewView.hidden = YES;
    [self stopCameraStream];

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
        NSLog(@"Nothing to do with only %lu boxes", (unsigned long)n);
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
