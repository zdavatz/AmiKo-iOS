//
//  FullTextOverviewVC.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 24/07/2019.
//  Copyright © 2019 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Used in Notification dictionary
#define KEY_FT_ROW           @"key_row"
#define KEY_FT_TEXT          @"key_text"   // Unused: we need the shorter one instead

@interface FullTextOverviewVC : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    //NSMutableArray *ftResults;
    IBOutlet UITableView *myTableView;
}

@property (nonatomic, retain) IBOutlet UITableView *myTableView;
@property (nonatomic, retain) NSArray *ftResults;

+ (FullTextOverviewVC *)sharedInstance;
- (void)setPaneWidth;

@end

NS_ASSUME_NONNULL_END
