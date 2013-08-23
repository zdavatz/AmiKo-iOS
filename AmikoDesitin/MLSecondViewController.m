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

#import "MLSecondViewController.h"

#import "MLConstants.h"

#import "SWRevealViewController.h"
#import "MLSearchWebView.h"

// Class extension
@interface MLSecondViewController ()
@end

@implementation MLSecondViewController
{
    int mNumRevealButtons;
    NSString *mTitle;
}

@synthesize searchField;
@synthesize webView;
@synthesize htmlStr;

- (void) dealloc
{
    NSLog(@"%s", __FUNCTION__);

    htmlAnchor = nil;    
    self.searchField = nil;
    self.htmlStr = nil;
    
    self.webView.delegate = nil;
    [webView removeFromSuperview];
    self.webView = nil;
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil title:(NSString *)title andParam:(int)numRevealButtons
{
    self = [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    mNumRevealButtons = numRevealButtons;
    mTitle = title;
    
    return self;
}

- (id) initWithNibName: (NSString *)nibNameOrNil bundle: (NSBundle *)nibBundleOrNil withString: (NSString *)html
{
    self = [super init];

    htmlStr = [[NSString alloc] initWithString:html];
    
    return self;
}

/** This is the observing class
*/
- (void) observeValueForKeyPath: (NSString *)keyPath ofObject: (id)object change: (NSDictionary *)change context:(void *)context
{
    // [self addObserver:self forKeyPath:@"javaScript" options:0 context:@"javaScriptChanged"];
    if ([keyPath isEqualToString:@"javaScript"]) {
        htmlAnchor = [NSString stringWithString:[change objectForKey:@"new"]];
        [self.webView stopLoading];
        [self.webView stringByEvaluatingJavaScriptFromString:htmlAnchor];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void) willRotateToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPad;
        } else {
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPad;
        }
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            // Add search bar as title view to navigation bar
            self.searchField = [[UISearchBar alloc] initWithFrame:CGRectMake(-5.0, 0.0, 320.0, 32.0)];
            self.searchField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 310.0, 32.0)];
            searchBarView.autoresizingMask = 0;
            self.searchField.delegate = self;
            [searchBarView addSubview:self.searchField];
            self.navigationItem.titleView = searchBarView;
            //
            if (self.view.bounds.size.height<500)
                self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPhone;
            else {
                self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPhone_Retina;
                self.revealViewController.rearViewRevealOverdraw = RearViewRevealOverdraw_Portrait_iPhone;
            }
        }
        else {
            // Add search bar as title view to navigation bar
            self.searchField = [[UISearchBar alloc] initWithFrame:CGRectMake(-5.0, 0.0, 320.0, 44.0)];
            self.searchField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 310.0, 44.0)];
            searchBarView.autoresizingMask = 0;
            self.searchField.delegate = self;
            [searchBarView addSubview:self.searchField];
            self.navigationItem.titleView = searchBarView;
            //
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPhone;
        }
    }
}

- (void) viewWillAppear: (BOOL)animated
{
    [super viewWillAppear:animated];
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPad;
        } else {
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPad;
        }
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
            // Add search bar as title view to navigation bar
            self.searchField = [[UISearchBar alloc] initWithFrame:CGRectMake(-5.0, 0.0, 320.0, 32.0)];
            self.searchField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 310.0, 32.0)];
            searchBarView.autoresizingMask = 0;
            self.searchField.delegate = self;
            [searchBarView addSubview:searchField];
            self.navigationItem.titleView = searchBarView;
            //
            if (self.view.bounds.size.height<500)
                self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPhone;
            else {
                self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPhone_Retina;
            }
        }
        else {
            // Add search bar as title view to navigation bar
            self.searchField = [[UISearchBar alloc] initWithFrame:CGRectMake(-5.0, 0.0, 320.0, 44.0)];
            self.searchField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 310.0, 44.0)];
            searchBarView.autoresizingMask = 0;
            self.searchField.delegate = self;
            [searchBarView addSubview:searchField];
            self.navigationItem.titleView = searchBarView;
            //
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPhone;
            self.revealViewController.rearViewRevealOverdraw = RearViewRevealOverdraw_Portrait_iPhone;            
        }
    }
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"%s", __FUNCTION__);
    
    self.title = NSLocalizedString(mTitle, nil);
    // Do any additional setup after loading the view from its nib.

    SWRevealViewController *revealController = [self revealViewController];
    
    [self.navigationController.navigationBar addGestureRecognizer:revealController.panGestureRecognizer];
    
    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                                                         style:UIBarButtonItemStyleBordered
                                                                        target:revealController
                                                                        action:@selector(revealToggle:)];
    self.navigationItem.leftBarButtonItem = revealButtonItem;
    
    if( mNumRevealButtons==2 ) {
        UIBarButtonItem *rightRevealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                                                                  style:UIBarButtonItemStyleBordered
                                                                                 target:revealController
                                                                                 action:@selector(rightRevealToggle:)];
        self.navigationItem.rightBarButtonItem = rightRevealButtonItem;
    }
    
    // PanGestureRecognizer goes here ... could be also placed in the other Views but this is the main view!
    // [self.navigationController.navigationBar addGestureRecognizer:revealController.panGestureRecognizer];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        // Add search bar as title view to navigation bar
        self.searchField = [[UISearchBar alloc] initWithFrame:CGRectMake(-5.0, 0.0, 320.0, 44.0)];
        self.searchField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 310.0, 44.0)];
        searchBarView.autoresizingMask = 0;
        self.searchField.delegate = self;
        [searchBarView addSubview:self.searchField];
        self.navigationItem.titleView = searchBarView;
    }
    
    self.webView.delegate = self;

    if (self.htmlStr != nil) {
        NSURL *mainBundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
        [self.webView loadHTMLString:self.htmlStr baseURL:mainBundleURL];
    }
    
    // PanGestureRecognizer goes here 
    [self.view addGestureRecognizer:revealController.panGestureRecognizer];    
}

- (void) viewDidAppear: (BOOL)animated
{
    [super viewDidAppear:animated];
    [self.webView reload];
}

- (void) viewDidUnload
{
    self.webView = nil;
}

- (void) searchBarSearchButtonClicked: (UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void) searchBar: (UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText length] > 2) {
        [self.webView highlightAllOccurencesOfString:searchText];
    }
    else
        [self.webView removeAllHighlights];
}

- (void) webViewDidFinishLoad: (UIWebView *)webView
{
    // Check this out!
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        int fontSize = 80;
        NSString *jsString = [[NSString alloc] initWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%d%%'", fontSize];
        [self.webView stringByEvaluatingJavaScriptFromString:jsString];
    }
    // NSString *res =
    [self.webView stringByEvaluatingJavaScriptFromString:htmlAnchor];
    // int height =
    [[self.webView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight;"] intValue];
    
    self.webView.scalesPageToFit = YES;
    self.webView.scrollView.zoomScale = 3.0;
}

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    return YES;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
 
    NSLog(@"%s", __FUNCTION__);
    // Dispose of any resources that can be recreated.
}

@end
