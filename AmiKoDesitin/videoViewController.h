//
//  videoViewController.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 11 Jul 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface videoViewController : UIViewController

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *cameraDevice;

@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;

@property (nonatomic, weak) id<AVCaptureVideoDataOutputSampleBufferDelegate> delegate;

//@property (weak, nonatomic) IBOutlet UIView *previewView;

- (void)startRunning;
- (void)stopRunning;

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer;

- (IBAction)cancelCamera:(id)sender;

@end
