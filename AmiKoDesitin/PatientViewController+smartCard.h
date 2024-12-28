//
//  PatientViewController+smartCard.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 15/06/2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "PatientViewController.h"

#define NUMBER_OF_BOXES_FOR_OCR   5

#import "CameraViewController.h"

struct scannedResults {
    NSString *familyName;
    NSString *givenName;
    NSString *cardNumberString;
    NSString *dateString;
    NSString *sexString;
    NSString *bagNumber;
    NSString *ahvNumber;
};

#pragma mark - class extension

@interface PatientViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    BOOL videoCaptureFinished;
    struct scannedResults savedOcr;
}

@property (nonatomic) CameraViewController *cameraVC;

@end

#pragma mark - category

@interface PatientViewController (smartCard)

- (void)startCameraLivePreview;
- (void)lastVideoFrame:(NSNotification *)notification;
- (BOOL)validateOcrResults:(NSArray *)ocrResults;

@end
