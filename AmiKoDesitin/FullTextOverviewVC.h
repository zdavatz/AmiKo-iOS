//
//  FullTextOverviewVC.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 24/07/2019.
//  Copyright © 2019 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FullTextOverviewVC : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    //NSMutableArray *ftResults;
    IBOutlet UITableView *myTableView;
}

@property (nonatomic, retain) IBOutlet UITableView *myTableView;
@property (nonatomic, retain) NSArray *ftResults;

+ (FullTextOverviewVC *)sharedInstance;

@end

NS_ASSUME_NONNULL_END
