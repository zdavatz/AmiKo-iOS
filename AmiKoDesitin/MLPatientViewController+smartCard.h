//
//  MLPatientViewController+smartCard.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 15/06/2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLPatientViewController.h"
#import "MLPreviewView.h"
#import <TesseractOCR/TesseractOCR.h>

typedef NS_ENUM( NSInteger, AVCamSetupResult ) {
    AVCamSetupResultSuccess,
    AVCamSetupResultCameraNotAuthorized,
    AVCamSetupResultSessionConfigurationFailed
};

typedef NS_ENUM( NSInteger, AVCamLivePhotoMode ) {
    AVCamLivePhotoModeOn,
    AVCamLivePhotoModeOff
};

typedef NS_ENUM( NSInteger, AVCamDepthDataDeliveryMode ) {
    AVCamDepthDataDeliveryModeOn,
    AVCamDepthDataDeliveryModeOff
};

#pragma mark - class extension

@interface MLPatientViewController () <AVCapturePhotoCaptureDelegate, UIGestureRecognizerDelegate, G8TesseractDelegate>

@property (nonatomic) AVCaptureSession *session;

@property (nonatomic, weak) IBOutlet MLPreviewView *previewView;

@property (nonatomic) AVCamSetupResult setupResult;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;

@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureDeviceDiscoverySession *videoDeviceDiscoverySession;
@property (nonatomic) AVCamLivePhotoMode livePhotoMode;
@property (nonatomic) AVCamDepthDataDeliveryMode depthDataDeliveryMode;
@property (nonatomic) AVCapturePhotoOutput *photoOutput;
@property (nonatomic) NSInteger inProgressLivePhotoCapturesCount;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;

@end

#pragma mark - category

@interface MLPatientViewController (smartCard)

- (void) initCamera;
- (void) startCameraStream;
- (void) stopCameraStream;

- (void) startCameraLivePreview;

@end
