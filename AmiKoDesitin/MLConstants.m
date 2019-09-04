/* 
 
 Copyright (c) 2013 Max Lungarella <cybrmx@gmail.com>
 
 Created on 11/08/2013.
 
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

#import "MLConstants.h"

// TODO: define APP_NAME from the Info.plist file, like this:
//NSString *APP_NAME = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];

#if defined (AMIKO_DESITIN)
NSString* const APP_NAME = @"AmiKoDesitin";
NSString* const APP_ID = @"687642725";
#elif defined (COMED_DESITIN)
NSString* const APP_NAME = @"CoMedDesitin";
NSString* const APP_ID = @"712891884";
#elif defined (AMIKO)
NSString* const APP_NAME = @"iAmiKo";
NSString* const APP_ID = @"687642725";
#elif defined (COMED)
NSString* const APP_NAME = @"iCoMed";
NSString* const APP_ID = @"712891884";
#else
NSString* const APP_NAME = @"iAmiKo";
NSString* const APP_ID = @"687642725";
#endif

NSString* const PILLBOX_ODDB_ORG = @"http://pillbox.oddb.org/";

/** iPad
    Non-Retina : 768 x 1024
    Retina     : 1536 x 2048
*/

const int RearViewFullWidth_Portrait_iPad = 768;
const int RearViewFullWidth_Landscape_iPad = 1024;

// Portrait
const int RearViewRevealWidth_Portrait_iPad = 560;              // 768 - 208 = 560
const int RearViewRevealOverdraw_Portrait_iPad = 208;
const int RightViewRevealWidth_Portrait_iPad = 208;

// Landscape
const int RearViewRevealWidth_Landscape_iPad = 816;             // 1024 - 208 = 816

/** iPhone resolutions in pixels
    iPhone 3GS :  320 x  480
    iPhone 4   :  640 x  960 ->  640/2 = 320-60 = 260
    iPhone 5   :  640 x 1136 ->  640/2 = 320-60 = 260
    iPhone 6   :  750 x 1334 ->  750/2 = 375-60 = 315
    iPhone 6+  : 1242 x 2208 -> 1242/2 = 621-60 = 561
*/

// Portrait
const int RearViewRevealWidth_Portrait_iPhone = 260;            // 260 + 60 = 320 x 2 = 640
const int RearViewRevealWidth_Portrait_iPhone_6 = 315;
const int RearViewRevealWidth_Portrait_iPhone_6P = 561;
const int RearViewRevealOverdraw_Portrait_iPhone = 60;
const int RightViewRevealWidth_Portrait_iPhone = 180;

// Landscape
const int RearViewRevealWidth_Landscape_iPhone = 420;           // 420 + 60 = 480 x 2 = 960
const int RearViewRevealWidth_Landscape_iPhone_Retina = 508;    // 508 + 60 = 568 x 2 = 1136
const int RearViewRevealOverdraw_Landscape_iPhone_Retina = 60;

/** Width and height in points (units)
 */
static int WidthInPoints;
static int HeightInPoints;

@implementation MLConstants

/** Needs to be initialized
 */
+ (void) start
{
    WidthInPoints = [[UIScreen mainScreen] bounds].size.width;
    HeightInPoints = [[UIScreen mainScreen] bounds].size.height;
}

//+ (float) iosVersion
//{
//    return [[UIDevice currentDevice].systemVersion floatValue];
//}

+ (int) displayWidthInPoints
{
    return WidthInPoints;
}

+ (int) displayHeightInPoints
{
    return HeightInPoints;
}

+ (int) rearViewRevealWidthPortrait
{
    return (int)(WidthInPoints - RearViewRevealOverdraw_Portrait_iPhone);
}

+ (int) rearViewRevealWidthLandscape
{
    return (int)(HeightInPoints- RearViewRevealOverdraw_Landscape_iPhone_Retina);
}

+ (int) rearViewRevealOverdrawPortrait
{
    return RearViewRevealOverdraw_Portrait_iPhone;
}

+ (int) rearViewRevealOverdrawLandscape
{
    return RearViewRevealOverdraw_Landscape_iPhone_Retina;
}

+ (NSString *) appOwner
{
    if ([APP_NAME isEqualToString:@"AmiKoDesitin"] ||
        [APP_NAME isEqualToString:@"CoMedDesitin"])
        return @"desitin";

    if ([APP_NAME isEqualToString:@"iAmiKo"] ||
        [APP_NAME isEqualToString:@"iCoMed"])
        return @"ywesee";

    return nil;
}

+ (NSString *) databaseLanguage
{
    if ([APP_NAME isEqualToString:@"iAmiKo"] ||
        [APP_NAME isEqualToString:@"AmiKoDesitin"])
        return @"de";
    
    if ([APP_NAME isEqualToString:@"iCoMed"] ||
        [APP_NAME isEqualToString:@"CoMedDesitin"])
        return @"fr";
    
    return nil;
}

+ (NSString *) databaseUpdateKey
{
    if ([[MLConstants databaseLanguage] isEqualToString:@"de"])  // AmiKoDesitin
        return @"germanDBLastUpdate";

    if ([[MLConstants databaseLanguage] isEqualToString:@"fr"]) // CoMedDesitin
        return @"frenchDBLastUpdate";

    NSLog(@"Invalid DB update key");
    return @"noLanguageDBLastUpdate";
}

+ (NSString *) notSpecified
{
    if ([APP_NAME isEqualToString:@"iAmiKo"] ||
        [APP_NAME isEqualToString:@"AmiKoDesitin"])
        return @"k.A.";
    
    if ([APP_NAME isEqualToString:@"iCoMed"] ||
        [APP_NAME isEqualToString:@"CoMedDesitin"])
        return @"n.s.";
    
    return nil;
}

@end
