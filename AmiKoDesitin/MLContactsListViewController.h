//
//  MLContactsListViewController.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 8 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MLContactsListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

- (NSArray *) getAllContacts;
- (NSArray *) addAllContactsToArray:(NSMutableArray *)arrayOfContacts;

@end
