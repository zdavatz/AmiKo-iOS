//
//  PatientViewController+smartCard.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 15/06/2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "PatientViewController.h"
#import "PreviewView.h"
#import <TesseractOCR/TesseractOCR.h>

#import "CameraViewController.h"

#pragma mark - class extension

@interface PatientViewController () <AVCapturePhotoCaptureDelegate, G8TesseractDelegate>

@property (nonatomic) CameraViewController *cameraVC;

@end

#pragma mark - category

@interface PatientViewController (smartCard)

- (void) startCameraLivePreview;

@end
