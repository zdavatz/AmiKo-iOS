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

#import "MLSimpleTableCell.h"

@implementation MLSimpleTableCell
{
    // Instance variable declarations go here
}

@synthesize checked;

#pragma mark - View lifecycle

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    // - grab bound for contentView
    // CGRect contentViewBound = self.contentView.bounds;
    // - grab the frame for the imageView
    // CGRect imageViewFrame = self.imageView.frame;
    // - change x position
    // imageViewFrame.origin.x = contentViewBound.size.width - imageViewFrame.size.width;
    // - assign the new frame
    self.imageView.frame = CGRectMake(12, 4, 22, 22);//imageViewFrame;
}

#pragma mark - Property methods

#pragma mark - Private methods

- (void) refreshCheckboxButtonImage
{}

- (void) toggleChecked
{
    self.checked =  !self.checked;
}

/** Override all touch-related methods
 */
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint firstTouch = [touch locationInView:touch.view];
    
    // NSLog(@"x=%f, y=%f", firstTouch.x, firstTouch.y);
    
    if (firstTouch.x>40)
        [super touchesBegan:touches withEvent:event];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
}

@end
