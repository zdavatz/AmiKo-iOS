//
//  MLPatientDBAdapter.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 5 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MLPatientDBAdapter : NSObject

- (BOOL) openDatabase:(NSString *)dbName;
- (void) closeDatabase;

@end
