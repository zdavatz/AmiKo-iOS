//
//  PrescriptionViewController.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 22 Jan 2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import <MessageUI/MessageUI.h>

#import "Prescription.h"

@interface PrescriptionViewController : UIViewController
    <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, UITextViewDelegate
//, MFMailComposeViewControllerDelegate
>
{
    IBOutlet UITableView *infoView;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *interactionButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendButton;
    
@property (nonatomic, retain) IBOutlet UITableView *infoView;
@property (atomic) Prescription *prescription;
@property (nonatomic) bool editedMedicines; // "dirty" flag

+ (PrescriptionViewController *)sharedInstance;

- (IBAction) newPrescription:(id)sender;
- (IBAction) checkForInteractions:(id)sender;
- (IBAction) savePrescription:(id)sender;
- (IBAction) sendPrescription:(id)sender;
- (IBAction) showPatientDbList:(id)sender;

- (IBAction) myRightRevealToggle:(id)sender;
- (IBAction) handleLongPress:(UILongPressGestureRecognizer *)gesture;

- (NSURL *) prescriptionUrlWithHash: (NSString *)hash;
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
