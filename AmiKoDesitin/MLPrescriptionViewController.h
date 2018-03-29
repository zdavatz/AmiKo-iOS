//
//  MLPrescriptionViewController.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 22 Jan 2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MLPrescription.h"

@interface MLPrescriptionViewController : UIViewController
    <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, UITextFieldDelegate>
{
    IBOutlet UITableView *infoView;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *interactionButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendButton;
    
@property (nonatomic, retain) IBOutlet UITableView *infoView;
@property (atomic) MLPrescription *prescription;
@property (nonatomic) bool editedMedicines; // "dirty" flag

+ (MLPrescriptionViewController *)sharedInstance;

- (IBAction) newPrescription:(id)sender;
- (IBAction) checkForInteractions:(id)sender;
- (IBAction) savePrescription:(id)sender;
- (IBAction) sendPrescription:(id)sender;
- (IBAction) showPatientDbList:(id)sender;

- (IBAction) myRightRevealToggle:(id)sender;

- (NSURL *) prescriptionUrlWithHash: (NSString *)hash;
- (BOOL) validatePrescription;
- (void) overwritePrescription;
- (void) saveNewPrescription;

- (NSString *) makeNewUniqueHash;
- (UILabel *)makeLabel:(NSString *)text textColor:(UIColor *)color;

- (void)amkListDidChangeSelection:(NSNotification *)aNotification;
- (void)amkDeleted:(NSNotification *)aNotification;
- (void)patientDbListDidChangeSelection:(NSNotification *)aNotification;

- (void)addMedication:(MLProduct *)p;
- (IBAction) handleLongPress:(UILongPressGestureRecognizer *)gesture;

@end
