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

#import "MLSearchWebView.h"

@implementation UIWebView (MLSearchWebView)

- (NSInteger) highlightAllOccurencesOfString: (NSString*)str
{
    // Load JavaScript file
    NSString *path = [[NSBundle mainBundle] pathForResource:@"MLSearchWebView" ofType:@"js"];
    NSString *jsCode = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];

    // Inject it into webpage
    [self stringByEvaluatingJavaScriptFromString:jsCode];
    
    // Call Javascript function
    NSString *startSearch = [NSString stringWithFormat:@"MyApp_HighlightAllOccurencesOfString('%@')", str];
    [self stringByEvaluatingJavaScriptFromString:startSearch];
    
    // Access variable defined in Javascript code
    NSString *result = [self stringByEvaluatingJavaScriptFromString:@"MyApp_SearchResultCount"];
       
    // Return
    return [result integerValue];
}

- (void) moveToStart
{
    [self nextHighlight:0];
}

- (void) nextHighlight:(int)index
{
    if (index<0)
        index = 0;
    NSString *scrollPosition = [NSString stringWithFormat:@"MyArr[%d].scrollIntoView()", index];
    [self stringByEvaluatingJavaScriptFromString:scrollPosition];
}

- (void) removeAllHighlights
{
    [self stringByEvaluatingJavaScriptFromString:@"MyApp_RemoveAllHighlights()"];
}

@end
