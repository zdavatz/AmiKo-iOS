//
//  videoViewController.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 11 Jul 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "videoViewController.h"
#import "avcamtypes.h"

#pragma mark -
////////////////////////////////////////////////////////////////////////////////

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
////////////////////////////////////////////////////////////////////////////////

@interface videoViewController ()

@property (nonatomic, strong) dispatch_queue_t videoDataOutputQueue;
@property (nonatomic) AVCamSetupResult setupResult;
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;
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
    
    self.videoDataOutputQueue = dispatch_queue_create( "capturesession.videodata", DISPATCH_QUEUE_SERIAL );
    
    
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
    //NSLog(@"%s", __FUNCTION__);
    [super viewWillAppear:animated];
    [self startRunning];
}

- (void)viewDidDisappear:(BOOL)animated
{
    //NSLog(@"%s", __FUNCTION__);
    [self stopRunning];
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

- (void)didRotate:(NSNotification *)notification
{
    //NSLog(@"%s %@", __FUNCTION__, notification);
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
    //NSLog(@"%s", __FUNCTION__);
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
        return;
    }
    
    NSError *error = nil;
    
    [self.session beginConfiguration];
    self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    
    ////////////////////////////////////////////////////////////////////////////
    AVCaptureDevice *videoDevice =
    [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
                                       mediaType:AVMediaTypeVideo
                                        position:AVCaptureDevicePositionBack];
    if ( !videoDevice ) {
        NSLog(@"No videoDevice");
        [self.session commitConfiguration];
        return;
    }

    // Lower the frame rate
    if ( [videoDevice lockForConfiguration:&error] ) {
        [videoDevice setActiveVideoMinFrameDuration:CMTimeMake(1, 8)];
        [videoDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, 4)];
        [videoDevice unlockForConfiguration];
    }
    else {
        NSLog( @"Could not lock video device for configuration: %@", error );
    }

    ////////////////////////////////////////////////////////////////////////////
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if ( ! videoDeviceInput ) {
        NSLog( @"Could not create video device input: %@", error );
        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.session commitConfiguration];
        return;
    }
    
    if ([self.session canAddInput:videoDeviceInput])
    {
        [self.session addInput:videoDeviceInput];
        self.videoDevice = videoDeviceInput.device;
        
        dispatch_async( dispatch_get_main_queue(), ^{
            UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
            AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
            if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
                initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
            }

            self.previewView.videoPreviewLayer.connection.videoOrientation = initialVideoOrientation;
            self.previewView.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        });
    }
    else {
        NSLog( @"Could not add video device input to the session" );
        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.session commitConfiguration];
        return;
    }
    
    ////////////////////////////////////////////////////////////////////////////
    self.videoDataOutput = [AVCaptureVideoDataOutput new];
    
    if ( [self.session canAddOutput:self.videoDataOutput] )
    {
        [self.session addOutput:self.videoDataOutput];

        _videoDataOutput.videoSettings = nil;
        _videoDataOutput.alwaysDiscardsLateVideoFrames = NO;

        [_videoDataOutput setSampleBufferDelegate:self.delegate
                                            queue:self.sessionQueue];
    }
    else {
        NSLog( @"Could not add video output to the session" );
        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.session commitConfiguration];
        return;
    }
  
    ////////////////////////////////////////////////////////////////////////////
    [self.session commitConfiguration];
}

- (void)startRunning
{
    dispatch_sync( self.sessionQueue, ^{
        switch ( self.setupResult )
        {
            case AVCamSetupResultSuccess:
            {
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

- (void)stopRunning
{
    dispatch_sync( self.sessionQueue, ^{
        if ( self.setupResult == AVCamSetupResultSuccess ) {
            [self.session stopRunning];
        }
    } );
}

#pragma mark - IBAction

- (IBAction)cancelCamera:(id)sender
{
    NSLog(@"%s", __FUNCTION__);
    [self dismissViewControllerAnimated:NO completion:NULL];
}

@end
