//
//  CameraViewController.h
//  ocrTest
//
//  Created by Alex Bettarini on 26 Jun 2018
//  Copyright © 2018 Alex Bettarini. All rights reserved.
//

#import <UIKit/UIKit.h>
@import AVFoundation;
#import "MLPreviewView.h"

@interface CameraViewController : UIViewController <AVCapturePhotoCaptureDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet MLPreviewView *previewView;

- (void) addObservers;
- (void) startCameraStream;
- (void) stopCameraStream;

- (IBAction)cancelCamera:(id)sender;
- (IBAction) handleTap:(UITapGestureRecognizer *)gesture;

@end
