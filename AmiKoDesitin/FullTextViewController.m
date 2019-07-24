//
//  FullTextViewController.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 23 Jul 2019.
//  Copyright © 2019 Ywesee GmbH. All rights reserved.
//

#import "FullTextViewController.h"
#import "SWRevealViewController.h"

@interface FullTextViewController ()

@end

@implementation FullTextViewController
{
    int mNumRevealButtons;
    BOOL mIsFindPanelVisible;
    NSString *mTitle;
    NSString *mCurrentSearch;
}

@synthesize searchField;
//@synthesize webView;
@synthesize htmlStr;

+ (FullTextViewController *)sharedInstance
{
    __strong static id sharedObject = nil;
    
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedObject = [[self alloc] init];
    });
    
    return sharedObject;
}

- (void) viewWillAppear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"%s %s", __FILE__, __FUNCTION__);
#endif
    
    // TODO
    if (self.htmlStr) {
#ifdef DEBUG
        //NSLog(@"%s %d %@", __FILE__, __LINE__, self.htmlStr);
#endif

#if 0
        [self updateWebView];
#else
        NSURL *mainBundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
        // Loads html directly into webview
#if 0 //def DEBUG
        NSString *temp = @"<html><head></head><body>Hello!</body></html>";
#else
        NSString *temp = self.htmlStr;
#endif
        [self.webView loadHTMLString:temp
                             baseURL:mainBundleURL];
#endif
    }
    
    // Create objc - js bridge
    //[self createJSBridge];
}

- (void)viewDidLoad
{
#ifdef DEBUG
    NSLog(@"%s %s", __FILE__, __FUNCTION__);
#endif

    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.
    self.title = mTitle;
    
    // SWRevealViewController extends UIViewController!
    SWRevealViewController *revealController = [self revealViewController];
    
    [self.navigationController.navigationBar addGestureRecognizer:revealController.panGestureRecognizer];
    
    self.navigationController.navigationBar.backgroundColor = VERY_LIGHT_GRAY_COLOR;// MAIN_TINT_COLOR;
    self.navigationController.navigationBar.barTintColor = VERY_LIGHT_GRAY_COLOR;
    self.navigationController.navigationBar.translucent = NO;

    {
        UIBarButtonItem *revealButtonItem =
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                         style:UIBarButtonItemStylePlain
                                        target:revealController
                                        action:@selector(revealToggle:)];
        self.navigationItem.leftBarButtonItem = revealButtonItem;
    }
    
    {
        UIBarButtonItem *rightRevealButtonItem =
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                         style:UIBarButtonItemStylePlain
                                        target:revealController
                                        action:@selector(rightRevealToggle:)];
        self.navigationItem.rightBarButtonItem = rightRevealButtonItem;
    }
    
    // TODO: see MLSecondViewController
}

- (id) initWithNibName:(NSString *)nibNameOrNil
                bundle:(NSBundle *)nibBundleOrNil
                 title:(NSString *)title
              andParam:(int)numRevealButtons
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    self = [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    mCurrentSearch = @"";
    [self resetSearchField];
    
    mNumRevealButtons = numRevealButtons;
    mTitle = title;
    
    mIsFindPanelVisible = YES;
    
    return self;
}

- (void) resetSearchField
{
#if 0 // TODO:
    if (mCurrentSearch)
        [searchField setText:mCurrentSearch];
    else
        [searchField setText:@""];
    
    if ([self.htmlStr isEqualToString:@"Interactions"])
        [searchField setPlaceholder:[NSString stringWithFormat:NSLocalizedString(@"Search in interactions", nil)]];
    else
        [searchField setPlaceholder:[NSString stringWithFormat:NSLocalizedString(@"Search in technical info", nil)]];
    
    if ([mTitle isEqualToString:@"About"])
        [searchField setPlaceholder:NSLocalizedString(@"Search in report", nil)];
#endif
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) showFindPanel:(BOOL)visible
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
}

#pragma mark - WKNavigationDelegate methods

#if 0
#pragma mark - UIWebViewDelegate methods

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    
    return YES;
}

- (void) webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void) webViewDidFinishLoad:(UIWebView *)webView
{
#if 0
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
    
    self.webView.scalesPageToFit = NO;  // YES
    self.webView.scrollView.zoomScale = 3.0;
    
    // Hide find panel (webview is the superview of the panel)
    [self showFindPanel:NO];
#endif
}
#endif

@end
