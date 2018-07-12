//
//  CameraViewController.h
//  AmiKoDesitin
//
//  Created by Alex Bettarini on 26 Jun 2018
//  Copyright © 2018 Alex Bettarini. All rights reserved.
//

#import <UIKit/UIKit.h>
@import AVFoundation;
#import "PreviewView.h"

@interface CameraViewController : UIViewController <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet PreviewView *previewView;
@property (nonatomic, weak) id<AVCapturePhotoCaptureDelegate> delegate;

- (void) addObservers;
- (void) startCameraStream;
- (void) stopCameraStream;

- (IBAction) cancelCamera:(id)sender;
- (IBAction) handleTap:(UITapGestureRecognizer *)gesture;

@end
