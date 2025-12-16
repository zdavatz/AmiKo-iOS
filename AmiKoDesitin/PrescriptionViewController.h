//
//  PrescriptionViewController.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 22 Jan 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Prescription.h"
@import AVFoundation;
#import "VideoViewController.h"

#define ppi             72.0
#define mm2inch         (1/25.4)
#define inch2pix(x)     (x * ppi)
#define mm2pix(x)       inch2pix(x*mm2inch)

@interface PrescriptionViewController : UIViewController
    <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, UITextViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, UIPrintInteractionControllerDelegate, NSFilePresenter>
{
    AVCaptureSession *captureSession;
    AVCaptureVideoDataOutput *captureOutput;
    dispatch_queue_t queue;

    IBOutlet UITableView *infoView;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *interactionButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendButton;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (nonatomic, retain) IBOutlet UITableView *infoView;
@property (atomic) Prescription *prescription;
@property (nonatomic) bool editedMedicines; // "dirty" flag

@property (nonatomic) VideoViewController *videoVC;
@property (nonatomic, retain) UIPrinter *SavedPrinter;


@property (nonatomic, retain) IBOutlet UIView *medicineLabelView;
@property (nonatomic, retain) IBOutlet UILabel *labelDoctor;
@property (nonatomic, retain) IBOutlet UILabel *labelPatient;
@property (nonatomic, retain) IBOutlet UILabel *labelMedicine;
@property (nonatomic, retain) IBOutlet UILabel *labelComment;
@property (nonatomic, retain) IBOutlet UILabel *labelPrice;
@property (nonatomic, retain) IBOutlet UILabel *labelSwissmed;

+ (PrescriptionViewController *)sharedInstance;

- (IBAction) newPrescription:(id)sender;
- (IBAction) checkForInteractions:(id)sender;
- (IBAction) savePrescription:(id)sender;
- (IBAction) sendPrescription:(id)sender;
- (IBAction) showPatientDbList:(id)sender;

- (IBAction) myRightRevealToggle:(id)sender;
- (IBAction) handleLongPress:(UILongPressGestureRecognizer *)gesture;

- (NSString *)getPlaceDateForPrinting;
- (void) printMedicineLabel; //:(NSIndexPath *)indexPath;

- (BOOL) validatePrescription;
- (void) overwritePrescription;
- (void) saveNewPrescription;

- (NSString *) makeNewUniqueHash;
- (UILabel *)makeLabel:(NSString *)text textColor:(UIColor *)color;

- (void)amkListDidChangeSelection:(NSNotification *)aNotification;
- (void)amkDeleted:(NSNotification *)aNotification;
- (void)patientDbListDidChangeSelection:(NSNotification *)aNotification;

- (void)addMedication:(Product *)p;
- (void)sharePrescription:(NSURL *)url;

@end
