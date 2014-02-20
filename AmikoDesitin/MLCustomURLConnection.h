//
//  MLCustomURLConnection.h
//  AmikoDesitin
//
//  Created by Max on 19/02/2014.
//  Copyright (c) 2014 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MLCustomURLConnection : NSURLConnection <NSURLConnectionDataDelegate>

- (void) downloadFileWithName:(NSString *)file andModal:(bool)modal;

@end
