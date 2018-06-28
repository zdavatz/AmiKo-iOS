//
//  ContactsListViewController.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 8 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactsListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
{
    IBOutlet UISearchBar *theSearchBar;
    IBOutlet UITableView *mTableView;
}

@property (nonatomic, retain) IBOutlet UISearchBar *theSearchBar;

//- (IBAction) searchDatabase:(id)sender;

- (NSArray *) getAllContacts;
- (NSArray *) addAllContactsToArray:(NSMutableArray *)arrayOfContacts;

@end
