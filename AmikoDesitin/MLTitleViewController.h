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

@interface MLTitleViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    IBOutlet UITableView *myMenuView;
    NSString *javaScript;
}

@property (nonatomic, retain) IBOutlet UITableView *myMenuView;
@property (nonatomic, copy) NSString *javaScript;

- (instancetype) initWithNibName:(NSString *)nibNameOrNil
                          bundle:(NSBundle *)nibBundleOrNil
                        withMenu:(NSArray *)sectionTitles;

- (instancetype) initWithMenu:(NSArray *)sectionTitles
                   sectionIds:(NSArray *)sectionIds
                  andLanguage:(NSString *)appLanguage;

- (void) setSectionTitles:(NSArray *)titles andIds:(NSArray *)ids;

@end
