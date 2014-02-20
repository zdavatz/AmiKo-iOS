/*
 
 Copyright (c) 2013 Max Lungarella <cybrmx@gmail.com>
 
 Created on 11/08/2013.
 
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

#import <Foundation/Foundation.h>

#if defined (AMIKO_DESITIN)
extern NSString* const APP_NAME;
extern NSString* const APP_ID;
#elif defined (COMED_DESITIN)
extern NSString* const APP_NAME;
extern NSString* const APP_ID;
#elif defined (AMIKO)
extern NSString* const APP_NAME;
extern NSString* const APP_ID;
#elif defined (COMED)
extern NSString* const APP_NAME;
extern NSString* const APP_ID;
#else
extern NSString* const APP_NAME;
extern NSString* const APP_ID;
#endif

extern const int RearViewFullWidth_Portrait_iPad;
extern const int RearViewFullWidth_Landscape_iPad;

// Portrait
extern const int RearViewRevealWidth_Portrait_iPad;
extern const int RearViewRevealOverdraw_Portrait_iPad;
extern const int RightViewRevealWidth_Portrait_iPad;

// Landscape
extern const int RearViewRevealWidth_Landscape_iPad;

// Portrait
extern const int RearViewRevealWidth_Portrait_iPhone;
extern const int RearViewRevealOverdraw_Portrait_iPhone;
extern const int RightViewRevealWidth_Portrait_iPhone;

// Landscape
extern const int RearViewRevealWidth_Landscape_iPhone;
extern const int RearViewRevealWidth_Landscape_iPhone_Retina;
extern const int RearViewRevealOverdraw_Landscape_iPhone_Retina;
