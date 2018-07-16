//
//  videoViewController.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 11 Jul 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "videoViewController.h"

@interface videoViewController ()

@property (nonatomic, strong) dispatch_queue_t videoDataOutputQueue;

// See IDCaptureSessionCoordinator
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@end

@implementation videoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // See IDCaptureSessionCoordinator
    self.sessionQueue = dispatch_queue_create( "video session queue", DISPATCH_QUEUE_SERIAL );
    self.captureSession = [AVCaptureSession new];
    
    
    self.videoDataOutputQueue = dispatch_queue_create( "capturesession.videodata", DISPATCH_QUEUE_SERIAL );
    
    dispatch_async( self.sessionQueue, ^{
        [self configureSession];
    } );
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"%s", __FUNCTION__);
    [super viewWillAppear:animated];
    
#if 1 // see configureInterface
    AVCaptureVideoPreviewLayer *previewLayer = self.videoPreviewLayer;
    previewLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:previewLayer atIndex:0];
#endif

    [self startRunning];
}

- (void)viewDidDisappear:(BOOL)animated
{
    NSLog(@"%s", __FUNCTION__);
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
    NSLog(@"%s", __FUNCTION__);
    return NO;
}

- (void)configureSession
{
    //NSLog(@"%s", __FUNCTION__);
    NSError *error = nil;
    
    [self.captureSession beginConfiguration];
    self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    
    ////////////////////////////////////////////////////////////////////////////
    AVCaptureDevice *videoDevice =
    [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
                                       mediaType:AVMediaTypeVideo
                                        position:AVCaptureDevicePositionBack];
    if ( !videoDevice ) {
        NSLog(@"No videoDevice");
        return;
    }

#ifdef DEBUG
    NSLog(@"videoSupportedFrameRateRanges %@", videoDevice.activeFormat.videoSupportedFrameRateRanges);
    NSLog(@"Line %d, min %f, max %f", __LINE__,
          CMTimeGetSeconds(videoDevice.activeVideoMinFrameDuration),
          CMTimeGetSeconds(videoDevice.activeVideoMaxFrameDuration));
#endif

    // Lower the frame rate
    if ( [videoDevice lockForConfiguration:&error] ) {
        [videoDevice setActiveVideoMinFrameDuration:CMTimeMake(1, 8)];
        [videoDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, 4)];
        [videoDevice unlockForConfiguration];
    }
    else {
        NSLog( @"Could not lock video device for configuration: %@", error );
    }

#ifdef DEBUG
    NSLog(@"Line %d, min %f, max %f", __LINE__,
          CMTimeGetSeconds(videoDevice.activeVideoMinFrameDuration),
          CMTimeGetSeconds(videoDevice.activeVideoMaxFrameDuration));
#endif

    ////////////////////////////////////////////////////////////////////////////
    AVCaptureDeviceInput *cameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if ( ! cameraDeviceInput ) {
        NSLog( @"Could not create video device input: %@", error );
        //self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.captureSession commitConfiguration];
        return;
    }
    
    if ([self.captureSession canAddInput:cameraDeviceInput]) {
        [self.captureSession addInput:cameraDeviceInput];

        self.cameraDevice = cameraDeviceInput.device;  // TBC
        
        // FIXME:
//        dispatch_async( dispatch_get_main_queue(), ^{
//            self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//        });
    }
    
    ////////////////////////////////////////////////////////////////////////////
    self.videoDataOutput = [AVCaptureVideoDataOutput new];
    
    if ( [self.captureSession canAddOutput:self.videoDataOutput] ) {
        [self.captureSession addOutput:self.videoDataOutput];

        _videoDataOutput.videoSettings = nil;
        _videoDataOutput.alwaysDiscardsLateVideoFrames = NO;

        [_videoDataOutput setSampleBufferDelegate:self.delegate
                                            queue:self.sessionQueue];
    }
  
    ////////////////////////////////////////////////////////////////////////////
    [self.captureSession commitConfiguration];
}

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer
{
#if 0
    return (AVCaptureVideoPreviewLayer *)self.previewView.layer;
#else
    if (!_videoPreviewLayer && _captureSession)
        _videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];

    return _videoPreviewLayer;
#endif
}

- (void)startRunning
{
    dispatch_sync( self.sessionQueue, ^{
        [self.captureSession startRunning];
    } );
}

- (void)stopRunning
{
    dispatch_sync( self.sessionQueue, ^{
        [self.captureSession stopRunning];
    } );
}

#pragma mark - previewView

+ (Class)layerClass
{
    NSLog(@"%s line %d", __FUNCTION__, __LINE__);
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session
{
    return self.videoPreviewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session
{
    NSLog(@"%s", __FUNCTION__);
    self.videoPreviewLayer.session = session;
}

#pragma mark - IBAction

- (IBAction)cancelCamera:(id)sender
{
    NSLog(@"%s", __FUNCTION__);
    [self dismissViewControllerAnimated:NO completion:NULL];
}

@end
