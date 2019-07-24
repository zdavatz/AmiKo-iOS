//
//  AmkListViewController.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 30 Jan 2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AmkListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>
{
    IBOutlet UITableView *myTableView;
}

@property (nonatomic, retain) IBOutlet UITableView *myTableView;

- (IBAction) handleLongPress:(UILongPressGestureRecognizer *)gesture;

- (void) removeFromListByFilename:(NSString *)path;
- (void) removeItem:(NSUInteger)rowIndex;
- (void) refreshList;

@end
