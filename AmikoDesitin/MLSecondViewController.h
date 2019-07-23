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

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "MLDBAdapter.h"
#import "MLTitleViewController.h"

@interface MLSecondViewController : UIViewController <UISearchBarDelegate, UIWebViewDelegate, MFMailComposeViewControllerDelegate>
{
    UISearchBar *searchField;
    UIWebView *webView;
    UILabel *findCounter;
    UIView *findPanel;
    NSString *htmlStr;
    NSString *htmlAnchor;
}

// Note: "strong" is a replacement for retain, it comes with ARC
@property (nonatomic, retain) IBOutlet UISearchBar *searchField;
@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet UILabel *findCounter;
@property (nonatomic, retain) IBOutlet UIView *findPanel;
@property (nonatomic, copy) NSString *htmlStr;
@property (nonatomic, weak) MLDBAdapter *dbAdapter;
@property (nonatomic, strong) NSMutableDictionary *medBasket;   // important: strong
@property (nonatomic, weak) MLTitleViewController *titleViewController;

- (IBAction) moveToNextHighlight:(id)sender;
- (IBAction) moveToPrevHighlight:(id)sender;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil title:(NSString *)title andParam:(int)numRevealButtons;
- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil withString:(NSString *)html;

@end
