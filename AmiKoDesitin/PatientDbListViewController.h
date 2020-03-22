//
//  PatientDbListViewController.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 13 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "BaseListViewController.h"

@interface PatientDbListViewController : BaseListViewController <UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate>

+ (PatientDbListViewController *)sharedInstance;
- (IBAction) handleLongPress:(UILongPressGestureRecognizer *)gesture;
- (void) removeItem:(NSUInteger)rowIndex;

@end
