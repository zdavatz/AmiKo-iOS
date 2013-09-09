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

#import "MLConstants.h"

/** iPad
    Non-Retina : 768 x 1024
    Retina     : 1536 x 2048
*/

const int RearViewFullWidth_Portrait_iPad = 768;
const int RearViewFullWidth_Landscape_iPad = 1024;

// Portrait
const int RearViewRevealWidth_Portrait_iPad = 648;              // 768 - 120 = 648
const int RearViewRevealOverdraw_Portrait_iPad = 120;
const int RightViewRevealWidth_Portrait_iPad = 180;

// Landscape
const int RearViewRevealWidth_Landscape_iPad = 904;             // 1024 - 120 = 904

/** iPhone
    Non-Retina : 320 x 480
    3.5''      : 640 x 960
    4''        : 640 x 1136
*/

// Portrait
const int RearViewRevealWidth_Portrait_iPhone = 260;            // 260 + 60 = 320 x 2 = 640
const int RearViewRevealOverdraw_Portrait_iPhone = 60;
const int RightViewRevealWidth_Portrait_iPhone = 180;

// Landscape
const int RearViewRevealWidth_Landscape_iPhone = 420;           // 420 + 60 = 480 x 2 = 960
const int RearViewRevealWidth_Landscape_iPhone_Retina = 508;    // 508 + 60 = 568 x 2 = 1136
const int RearViewRevealOverdraw_Landscape_iPhone_Retina = 60;
