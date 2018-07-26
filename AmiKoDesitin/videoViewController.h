//
//  videoViewController.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 11 Jul 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#pragma mark -
////////////////////////////////////////////////////////////////////////////////

@interface VideoPreviewView : UIView

@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic) AVCaptureSession *session;

@end

#pragma mark -
////////////////////////////////////////////////////////////////////////////////

@interface videoViewController : UIViewController

@property (weak, nonatomic) IBOutlet VideoPreviewView *previewView;
@property (nonatomic, weak) id<AVCaptureVideoDataOutputSampleBufferDelegate> delegate;

- (void)startVideoStream;
- (void)stopVideoStream;
- (IBAction)cancelCamera:(id)sender;

@end
