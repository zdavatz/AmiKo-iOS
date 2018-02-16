//
//  MLPatientDbListViewController.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 13 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLBaseListViewController.h"

@interface MLPatientDbListViewController : MLBaseListViewController <UIGestureRecognizerDelegate>

- (IBAction) handleLongPress:(UILongPressGestureRecognizer *)gesture;
- (void) removeItem:(NSUInteger)rowIndex;

@end
