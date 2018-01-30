//
//  MLPrescriptionViewController.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 22 Jan 2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MLPatient.h"
#import "MLOperator.h"
#import "MLProduct.h"

@interface MLPrescriptionViewController : UIViewController
    <UITableViewDelegate, UITableViewDataSource>
{
    IBOutlet UITableView *infoView;
}

@property (nonatomic, retain) IBOutlet UITableView *infoView;

@property (atomic) NSString *placeDate;
@property (atomic) MLOperator *doctor;
@property (atomic) MLPatient *patient;
@property (atomic) NSMutableArray *medications;

- (IBAction) newPrescription:(id)sender;
- (IBAction) checkForInteractions:(id)sender;
- (IBAction) savePrescription:(id)sender;
- (IBAction) sendPrescription:(id)sender;

- (void) overwritePrescription;
- (void) saveNewPrescription;
- (void) readPrescription:(NSURL *)url;

- (UILabel *)makeLabel:(NSString *)text textColor:(UIColor *)color;

- (void)amkListDidChangeSelection:(NSNotification *)aNotification;

@end
