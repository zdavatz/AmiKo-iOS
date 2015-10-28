/*
 
 Copyright (c) 2015 Max Lungarella <cybrmx@gmail.com>
 
 Created on 27/10/2015.
 
 This file is part of AMiKoDesitin.
 
 AmiKoDesitin is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 
 ------------------------------------------------------------------------ */

#import "MLAppInfo.h"

@implementation MLAppInfo

+ (int) checkVersion
{
    // Retrieve bundle root path, e.g. /var/mobile/Applications/<GUID>/<AppName>.app
    NSString *bundleRoot = [[NSBundle mainBundle] bundlePath];
    // Handle to file manager, initialize
    NSFileManager *manager = [NSFileManager defaultManager];
    NSDictionary* attrs = [manager attributesOfItemAtPath:bundleRoot error:nil];
#ifdef DEBUG
    NSLog(@"App creation date: %@", [attrs fileCreationDate]);
    NSLog(@"App modification date (unless bundle changed by code): %@", [attrs fileModificationDate]);
#endif
    // e.g /var/mobile/Applications/<GUID>
    NSString *rootPath = [bundleRoot substringToIndex:[bundleRoot rangeOfString:@"/" options:NSBackwardsSearch].location];
    attrs = [manager attributesOfItemAtPath:rootPath error:nil];
#ifdef DEBUG
    NSLog(@"App installation date (or first reinstalled after deletion): %@", [attrs fileCreationDate]);
#endif
    
    return 0;
}

@end