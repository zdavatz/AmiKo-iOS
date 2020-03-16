//
//  videoViewController.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 11 Jul 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "videoViewController.h"
#import "avcamtypes.h"

static void * SessionRunningContext = &SessionRunningContext;

#pragma mark -

@implementation VideoPreviewView

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

#pragma mark -

@interface videoViewController ()

@property (nonatomic) AVCamSetupResult setupResult;
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput; // .device
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;

@end

#pragma mark -

@implementation videoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.session = [AVCaptureSession new];
    self.previewView.session = self.session;
    self.sessionQueue = dispatch_queue_create( "video session queue", DISPATCH_QUEUE_SERIAL );
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
    
    [self.previewView setSession:self.session];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self startVideoStream];
}

- (void)viewDidDisappear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    [self stopVideoStream];
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

#pragma mark - Rotation

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)didRotate:(NSNotification *)notification
{
    [self.view layoutIfNeeded];
    
    UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
    AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
    if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
        initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
        self.previewView.videoPreviewLayer.connection.videoOrientation = initialVideoOrientation;
    }
    
    [self.previewView setNeedsDisplay];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:
     ^(id<UIViewControllerTransitionCoordinatorContext> context) {
         // willRotateToInterfaceOrientation
     }
                                 completion:
     ^(id<UIViewControllerTransitionCoordinatorContext> context) {
         // didRotateFromInterfaceOrientation would go here.
         [self didRotate:nil];
     }];
}

#pragma mark -

- (void)configureSession
{
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
        NSLog(@"No videoDevice\n%s:%d", __FILE__, __LINE__);
        [self.session commitConfiguration];
        return;
    }

    // Lower the frame rate
    if ( [videoDevice lockForConfiguration:&error] ) {
        [videoDevice setActiveVideoMinFrameDuration:CMTimeMake(1, 8)];  // 1/8 second
        [videoDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, 4)];  // 1/4 second
        [videoDevice unlockForConfiguration];
    }
    else {
        NSLog( @"Could not lock video device for configuration: %@", error.localizedDescription );
    }

    ///
    AVCaptureDeviceInput *videoDeviceInput =
        [AVCaptureDeviceInput deviceInputWithDevice:videoDevice
                                              error:&error];
    if ( !videoDeviceInput ) {
        NSLog( @"Could not create video device input: %@", error.localizedDescription );
        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.session commitConfiguration];
        return;
    }
    
    if (![self.session canAddInput:videoDeviceInput])
    {
        NSLog( @"Could not add video device input to the session" );
        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.session commitConfiguration];
        return;
    }

    [self.session addInput:videoDeviceInput];
    self.videoDeviceInput = videoDeviceInput;
    
    dispatch_async( dispatch_get_main_queue(), ^{
        UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
        AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
        if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
            initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
        }
        self.previewView.videoPreviewLayer.connection.videoOrientation = initialVideoOrientation;
#if 1
        // The image is stretched, but at least we get the toolbar.
        // Luckily, barcode recognition still works with a distorted image.
        self.previewView.videoPreviewLayer.videoGravity = AVLayerVideoGravityResize;
#else
        // Fill the screen
        // In landscape orientation the toolbar is no longer visible.
        // (Strange thing is that it works for the card OCR preview)
        self.previewView.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
#endif
    });
    
    ///
    self.videoDataOutput = [AVCaptureVideoDataOutput new];
    if (![self.session canAddOutput:self.videoDataOutput])
    {
        NSLog( @"Could not add video output to the session" );
        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.session commitConfiguration];
        return;
    }

    [self.session addOutput:self.videoDataOutput];
    _videoDataOutput.videoSettings = nil;
    _videoDataOutput.alwaysDiscardsLateVideoFrames = NO;
    [_videoDataOutput setSampleBufferDelegate:self.delegate
                                        queue:self.sessionQueue];
  
    ///
    [self.session commitConfiguration];
}

- (void)startVideoStream
{
    dispatch_sync( self.sessionQueue, ^{
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
                NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
                NSString *message = [NSString stringWithFormat:NSLocalizedString( @"%@ doesn't have permission to use the camera, please change privacy settings", "Alert message when the user has denied access to the camera" ), bundleName];
                NSLog(@"%@", message);
                break;
            }
            case AVCamSetupResultSessionConfigurationFailed:
            {
                NSString *message = NSLocalizedString( @"Unable to capture media", "Alert message when something goes wrong during capture session configuration" );
                NSLog(@"%@", message);
                break;
            }
        }
    } );
}

- (void)stopVideoStream
{
    //dispatch_sync( self.sessionQueue, ^{
        if ( self.setupResult == AVCamSetupResultSuccess ) {
            [self.session stopRunning];
            self.sessionRunning = self.session.isRunning;
            [self removeObservers];
        }
    //} );
}

#pragma mark - KVO and Notifications

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
    
    [self.session
     removeObserver:self
     forKeyPath:@"running"
     context:SessionRunningContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ( context == SessionRunningContext ) {
//        BOOL isSessionRunning = [change[NSKeyValueChangeNewKey] boolValue];
//        BOOL livePhotoCaptureSupported = self.photoOutput.livePhotoCaptureSupported;
//        BOOL livePhotoCaptureEnabled = self.photoOutput.livePhotoCaptureEnabled;
//        BOOL depthDataDeliverySupported = self.photoOutput.depthDataDeliverySupported;
//        BOOL depthDataDeliveryEnabled = self.photoOutput.depthDataDeliveryEnabled;
//
//        dispatch_async( dispatch_get_main_queue(), ^{
//
//        } );
    }
    else {
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
    NSLog(@"%s", __FUNCTION__);
    [self dismissViewControllerAnimated:NO completion:NULL];
}

@end
