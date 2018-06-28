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

#import "CameraViewController.h"

#pragma mark - class extension

@interface MLPatientViewController () <AVCapturePhotoCaptureDelegate, UIGestureRecognizerDelegate, G8TesseractDelegate>

@property (nonatomic) CameraViewController *camVC;

@end

#pragma mark - category

@interface MLPatientViewController (smartCard)

- (void) startCameraLivePreview;

@end
