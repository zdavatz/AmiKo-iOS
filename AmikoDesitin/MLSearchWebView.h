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

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

// Defines a category!
@interface WKWebView (MLSearchWebView)

- (NSInteger) highlightAllOccurencesOfString:(NSString*)str;
- (void) moveToStart;
- (void) nextHighlight:(int)index;
- (void) removeAllHighlights;

@end
