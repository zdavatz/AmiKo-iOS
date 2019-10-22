//
//  CameraViewController.m
//  AmiKoDesitin
//
//  Created by Alex Bettarini on 26 Jun 2018
//  Copyright © 2018 Alex Bettarini. All rights reserved.
//

#import "CameraViewController.h"
#import "PatientViewController+smartCard.h" // use this class as video delegate
#import "avcamtypes.h"

//static void * SessionRunningContext = &SessionRunningContext;

#pragma mark -

@interface CameraViewController ()

@property (nonatomic) AVCamSetupResult setupResult;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput; // .device
@property (nonatomic) AVCamLivePhotoMode livePhotoMode;
@property (nonatomic) AVCamDepthDataDeliveryMode depthDataDeliveryMode;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;

@end

#pragma mark -

@implementation CameraViewController

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.session = [AVCaptureSession new];
    self.previewView.session = self.session;
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
            dispatch_suspend( self.sessionQueue );
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                                     completionHandler:^( BOOL granted ) {
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
    
    [self.previewView setSession:self.session];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self startCameraStream];
    [self setVidOrientation:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self stopCameraStream];
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Rotation

- (BOOL)shouldAutorotate
{
    //NSLog(@"%s", __FUNCTION__);
    return YES;
}

- (void)didRotate:(CGSize)size
{
    //NSLog(@"%s, size %@, %@", __FUNCTION__, NSStringFromCGSize(size), (size.height > size.width) ? @"Por" : @"Land");
    [self.view layoutIfNeeded];
    
    [self setVidOrientation:nil];    // Update the camera rotation
    
    [self.previewView setNeedsDisplay]; // Will call drawRect
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    NSLog(@"%s", __FUNCTION__);
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:
     ^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // willRotateToInterfaceOrientation
     }
                                 completion:
     ^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // didRotateFromInterfaceOrientation
        [self didRotate:size];
     }];
}

#pragma mark -

- (void) startCameraStream
{
    //NSLog(@"%s", __FUNCTION__);
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
                    NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];

                    NSString *message = [NSString stringWithFormat:NSLocalizedString( @"%@ doesn't have permission to use the camera, please change privacy settings", "Alert message when the user has denied access to the camera" ), bundleName];

                    UIAlertController *alertController =
                    [UIAlertController alertControllerWithTitle:bundleName
                                                        message:message
                                                 preferredStyle:UIAlertControllerStyleAlert];

                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", "Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];

                    // Provide quick access to Settings.
                    UIAlertAction *settingsAction =
                    [UIAlertAction actionWithTitle:NSLocalizedString( @"Settings", "Alert button to open Settings" )
                                             style:UIAlertActionStyleDefault
                                           handler:^( UIAlertAction *action ) {
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
                    NSString *message = NSLocalizedString( @"Unable to capture media", "Alert message when something goes wrong during capture session configuration" );

                    UIAlertController *alertController =
                    [UIAlertController alertControllerWithTitle:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]
                                                        message:message
                                                 preferredStyle:UIAlertControllerStyleAlert];

                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", "Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];

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
    AVCaptureConnection *conn = self.previewView.videoPreviewLayer.connection;
    conn.enabled = NO;

    dispatch_async( self.sessionQueue, ^{
        if ( self.setupResult == AVCamSetupResultSuccess ) {
            [self.session stopRunning];
            [self removeObservers];
        }
    } );
}

- (void)setVidOrientation:(AVCaptureConnection *)connection
{
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
        //AVCaptureConnection *connection = self.previewView.videoPreviewLayer.connection;

        AVCaptureConnection *conn;
//        if (connection)
//            conn = connection;
//        else
            conn = self.previewView.videoPreviewLayer.connection;

        if ([conn isVideoOrientationSupported])
        {
            UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
            if (statusBarOrientation == UIInterfaceOrientationPortrait)  // 1 ok
            {
                [conn setVideoOrientation: AVCaptureVideoOrientationPortrait];
            }
            else if (statusBarOrientation == UIInterfaceOrientationLandscapeRight)  // 3 ok
            {
                [conn setVideoOrientation: AVCaptureVideoOrientationLandscapeRight];
            }
            else if (statusBarOrientation == UIInterfaceOrientationLandscapeLeft)  // 4
            {
                [conn setVideoOrientation: AVCaptureVideoOrientationLandscapeLeft]; //upside down
                //[connection setVideoOrientation: AVCaptureVideoOrientationLandscapeRight];
            }
            else
            {
                [conn setVideoOrientation: AVCaptureVideoOrientationPortrait];
            }
        }
        
        self.previewView.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill; // Preserve aspect ratio; fill layer bounds.
    } );
}

- (void)configureSession
{
    //NSLog(@"%s setupResult %ld", __FUNCTION__, (long)self.setupResult);
    
    if ( self.setupResult != AVCamSetupResultSuccess ) {
        NSLog(@"%s line %d, cannot configure session", __FUNCTION__, __LINE__);
        return;
    }
    
    NSError *error = nil;
    
    [self.session beginConfiguration];
    self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    
    ///
    AVCaptureDevice *videoDevice =
        [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
                                           mediaType:AVMediaTypeVideo
                                            position:AVCaptureDevicePositionBack];
    if ( !videoDevice ) {
        // TODO: Possibly try another camera
        //NSLog(@"No videoDevice\n%s:%d", __FILE__, __LINE__);
        [self.session commitConfiguration]; // To prevent crash with the simulator
        return;
    }

    // Lower the frame rate
    if ( [videoDevice lockForConfiguration:&error] ) {
        @try {
            // See AVCaptureDeviceFormat videoSupportedFrameRateRanges property
            [videoDevice setActiveVideoMinFrameDuration:CMTimeMake(1, 8)];  // 1/8 second
            [videoDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, 4)];  // 1/4 second
        }
        @catch(NSException *exception)
        {
            NSLog(@"%s %d, Exception: %@", __FILE__, __LINE__, exception);
        }
        @finally {
            [videoDevice unlockForConfiguration];
        }
    }
    else {
        NSLog( @"Could not lock video device for configuration: %@", error.localizedDescription );
    }
    
    ///
    AVCaptureDeviceInput *cameraDeviceInput =
        [AVCaptureDeviceInput deviceInputWithDevice:videoDevice
                                              error:&error];
    if ( ! cameraDeviceInput ) {
        NSLog( @"Could not create camera device input: %@", error );
        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.session commitConfiguration];
        return;
    }
    
    if (! [self.session canAddInput:cameraDeviceInput] )
    {
        NSLog( @"Could not add camera device input to the session" );
        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.session commitConfiguration];
        return;
    }

    [self.session addInput:cameraDeviceInput];
    self.videoDeviceInput = cameraDeviceInput;
    [self setVidOrientation: nil];
    
    ///
    AVCaptureVideoDataOutput *videoDataOutput = [AVCaptureVideoDataOutput new];
    if (![self.session canAddOutput:videoDataOutput])
    {
        NSLog(@"Could not add video output to the session");
        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.session commitConfiguration];
        return;
    }

    videoDataOutput.videoSettings = nil;
    videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    [videoDataOutput setSampleBufferDelegate:self.delegate
                                       queue:self.sessionQueue];

    [self.session addOutput:videoDataOutput];
    self.backgroundRecordingID = UIBackgroundTaskInvalid;
    
    ///
    [self.session commitConfiguration];
    
    //[self setVideoOrientation:self.previewView.videoPreviewLayer.connection];
}

#pragma mark - KVO and Notifications

- (void)addObservers
{
//    [self.session addObserver:self
//                   forKeyPath:@"running"
//                      options:NSKeyValueObservingOptionNew
//                      context:SessionRunningContext];
    
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
#ifdef DEBUG_ISSUE_102_VERBOSE
    NSLog(@"%s", __FUNCTION__);
#endif
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
//    [self.session removeObserver:self
//                      forKeyPath:@"running"
//                         context:SessionRunningContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
//    if ( context == SessionRunningContext )
//   {
//        BOOL isSessionRunning = [change[NSKeyValueChangeNewKey] boolValue];
//        BOOL livePhotoCaptureSupported = self.photoOutput.livePhotoCaptureSupported;
//        BOOL livePhotoCaptureEnabled = self.photoOutput.livePhotoCaptureEnabled;
//        BOOL depthDataDeliverySupported = self.photoOutput.depthDataDeliverySupported;
//        BOOL depthDataDeliveryEnabled = self.photoOutput.depthDataDeliveryEnabled;
//
//        dispatch_async( dispatch_get_main_queue(), ^{
//
//        } );
//    }
//    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode
       exposeWithMode:(AVCaptureExposureMode)exposureMode
        atDevicePoint:(CGPoint)point
monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
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

#pragma mark - IBAction

- (IBAction)cancelCamera:(id)sender
{
#ifdef DEBUG_ISSUE_102_VERBOSE
    NSLog(@"%s", __FUNCTION__);
#endif
    //[self stopCameraStream]; // will be called in viewDidDisappear
    [self dismissViewControllerAnimated:NO completion:NULL];
}

#pragma mark - UIGestureRecognizerDelegate

- (IBAction) handleTap:(UITapGestureRecognizer *)gesture
{
    //NSLog(@"%s is running: %d", __FUNCTION__, self.session.isRunning);

#ifdef TAP_TO_END_CARD_OCR
    if (self.session.isRunning) {
        [self stopCameraStream];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"lastVideoFrameNotification"
                                                            object:nil];
    }
    
    [self dismissViewControllerAnimated:NO completion:NULL];
#endif
}

@end
