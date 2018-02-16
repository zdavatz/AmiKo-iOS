//
//  MLBaseListViewController.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 13 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MLBaseListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
{
    NSString *tableIdentifier;
    UIColor *textColor;
    NSNotificationName notificationName;

    NSArray *mFilteredArray;
    BOOL mSearchFiltered;
    
    IBOutlet UISearchBar *theSearchBar;
    IBOutlet UITableView *mTableView;
}

@property (nonatomic, retain) IBOutlet UISearchBar *theSearchBar;
@property (retain) NSArray *mArray;

// To be overloaded by subclasses
- (NSString *) getTextAtRow:(NSInteger)row;
- (id) getItemAtRow:(NSInteger)row;

@end
