/*
 
 Copyright (c) 2015 Max Lungarella <cybrmx@gmail.com>
 
 Created on 27/10/2015.
 
 This file is part of AmiKoDesitin.
 
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

#import <Foundation/Foundation.h>

@interface MLUtility : NSObject

+ (BOOL) checkAppVersion;
+ (NSNumber*) timeIntervalInSecondsSince1970:(NSDate *)date;
+ (double) timeIntervalSinceLastDBSync;
+ (void) updateDBCheckedTimestamp;

+ (NSString *) currentTime;
+ (NSString *) prettyTime;
+ (NSString*) encodeStringToBase64:(NSString*)string;

+ (NSString *) documentsDirectory;
+ (NSString *) amkBaseDirectory;
+ (NSString *) amkDirectory;
+ (NSString *) amkDirectoryForPatient:(NSString*)uid;

+ (BOOL) emailValidator:(NSString *)msg;

+ (NSString *) getColorCss;
@end

