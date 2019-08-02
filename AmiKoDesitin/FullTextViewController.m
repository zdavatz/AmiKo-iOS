//
//  FullTextViewController.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 23 Jul 2019.
//  Copyright © 2019 Ywesee GmbH. All rights reserved.
//

#import "FullTextViewController.h"
#import "SWRevealViewController.h"
#import "MLUtility.h"
#import "MLViewController.h"

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
        sharedObject = [self new];
    });
    
    return sharedObject;
}

- (void) viewWillAppear:(BOOL)animated
{
    if (self.htmlStr) {
        NSURL *mainBundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
#ifdef DEBUG
        NSLog(@"%s %s, mainBundleURL: %@", __FILE__, __FUNCTION__, mainBundleURL);
#endif
        // Loads HTML directly into webview
        [self.webView loadHTMLString:self.htmlStr
                             baseURL:mainBundleURL];
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
    self.webView.UIDelegate = self;
    self.webView.navigationDelegate = self;
    //self.webView.scrollView.zoomScale = 3.0;
#if 1
    WKWebViewConfiguration *config = self.webView.configuration;
    WKUserContentController *wkUController = config.userContentController;
    NSLog(@"%lu userScripts: %@", (unsigned long)[wkUController.userScripts count], wkUController.userScripts);
    
    // TODO
    NSString *jsString = @"";
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource: jsString
                                                      injectionTime: WKUserScriptInjectionTimeAtDocumentEnd
                                                   forMainFrameOnly:YES];
    [wkUController addUserScript:userScript];
    
    // Add a script message handler for receiving "MyEvent" event notifications
    // posted from the JS document using
    // window.webkit.messageHandlers.MyEvent.postMessage script message
    // window.webkit.messageHandlers.<name>.postMessage(<messageBody>)
    [wkUController addScriptMessageHandler:self name:@"MyEvent"];

    [wkUController addScriptMessageHandler:self name:@"callbackHandler"];
    
    [wkUController addScriptMessageHandler:self name:@"buttonClicked"];
#else
    WKPreferences *prefs = [WKPreferences new];
    prefs.javaScriptEnabled = YES;    // Already done in IB
    prefs.minimumFontSize = 2;        // Can also be set in IB
    
    // Create a configuration for the preferences
    WKWebViewConfiguration *config = [WKWebViewConfiguration new];
    config.preferences = prefs;
#endif
    
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
}

- (void) updateFullTextSearchView:(NSString *)contentStr
{
#ifdef DEBUG
    NSLog(@"%s line %d, contentStr:\n\n\n%@\n\n\n", __FUNCTION__, __LINE__,
          [contentStr substringToIndex:MIN(500,[contentStr length])]);
#endif

    NSString *colorCss = [MLUtility getColorCss];
    
    // Load style sheet from file
    NSString *fullTextCssPath = [[NSBundle mainBundle] pathForResource:@"fulltext_style" ofType:@"css"];
    NSString *fullTextCss = [NSString stringWithContentsOfFile:fullTextCssPath
                                                      encoding:NSUTF8StringEncoding
                                                         error:nil];

    // Load JavaScript from file TODO: don't need this
    NSString *jscriptPath = [[NSBundle mainBundle] pathForResource:@"main_callbacks" ofType:@"js"];
    NSString *jscriptStr = [NSString stringWithContentsOfFile:jscriptPath
                                                     encoding:NSUTF8StringEncoding
                                                        error:nil];
    
    NSString *html = [NSString stringWithFormat:@"<html><head><meta charset=\"utf-8\" /><meta name=\"supported-color-schemes\" content=\"light dark\" />"];
    htmlStr = [html stringByAppendingFormat:@"<script type=\"text/javascript\">%@</script><style type=\"text/css\">%@</style><style type=\"text/css\">%@</style></head><body><div id=\"fulltext\">%@</body></div></html>",
               jscriptStr,
               colorCss,
               fullTextCss,
               contentStr];
    
    // Loads HTML directly into webview
    NSURL *mainBundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    [self.webView loadHTMLString:htmlStr baseURL:mainBundleURL];
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

- (void)triggerJS:(NSString *)jsString
          webView:(WKWebView *)webView
{
#ifdef DEBUG
    NSLog(@"%s %d, jsString: %@", __FUNCTION__, __LINE__, jsString);
#endif
    
    [webView evaluateJavaScript:jsString
              completionHandler:^(NSString *result, NSError *error){
                  if (error != nil) {
                      NSLog(@"JS runtime error:%@", error.localizedDescription);
                      return;
                  }
                  NSLog(@"output result size %lu, %@",
                        (unsigned long)[result length],
                        [result substringToIndex:MIN(300,[result length])]);
              }];
}

#pragma mark - WKUIDelegate methods

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler
{
#ifdef DEBUG
    NSLog(@"%s, defaultText: %@", __FUNCTION__, defaultText);
#endif
    completionHandler(defaultText);
}


#pragma mark - WKNavigationDelegate methods

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURL *url = navigationAction.request.URL;
    
#ifdef DEBUG
    NSLog(@"%s, url: %@, scheme: <%@>", __FUNCTION__, url, url.scheme);
    
    if (webView != self.webView) {
        NSLog(@"%s, %d", __FUNCTION__, __LINE__);
        return;
    }
#endif
    
#if 0
    if ([navigationAction.request.URL.relativeString hasPrefix:@"http://click.adzcore.com/"]) {
        //[[UIApplication sharedApplication] openURL:url];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
#endif
    
    if ([url.scheme isEqualToString:@"file"]) {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
    else {
        NSLog(@"TODO: switch to Fachinfo, with highlighted keywords");
        decisionHandler(WKNavigationActionPolicyCancel);

        UIViewController *nc_rear = self.revealViewController.rearViewController;
        MLViewController *vc_rear = [nc_rear.childViewControllers firstObject];
        //[vc_rear switchToAipsViewFromFulltext: @"test"];
        
        //- (IBAction)jsTrigger:(id)sender
        // window.webkit.messageHandlers.<name>.postMessage(<messageBody>)
        //[self triggerJS:@"window.webkit.messageHandlers.callbackHandler.postMessage('Hello Native!');" webView:self.webView];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
 
    //[self triggerJS:@"document.body.innerHTML" webView:webView];
}

#pragma mark - WKScriptMessageHandler methods

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message
{
#ifdef DEBUG
    NSLog(@"%s line %d, message.name: %@", __FUNCTION__, __LINE__, message.name);
    NSLog(@"%s line %d, message.body: %@", __FUNCTION__, __LINE__, message.body);

    if ([message.name isEqual: @"callbackHandler"]) {
        NSLog(@"%@", [NSString stringWithFormat:@"%@", message.body]);
    }
    else if ([message.name isEqual: @"MyEvent"]) {
        // message.body is the obj-C object
    }
    else
#endif
        if ([message.name isEqual: @"buttonClicked"]) {

        id messageDictionary = message.body;
        //NSLog(@"%s %d, messageBody %@",__func__, __LINE__, messageBody);
        if ([messageDictionary isKindOfClass:[NSDictionary class]]) {
#ifdef DEBUG
            NSString* eanCode = messageDictionary[@"EanCode"];
            NSLog(@"%s line %d, EanCode: %@",__func__, __LINE__, eanCode);
            NSLog(@"%s line  %d, Anchor: %@",__func__, __LINE__, messageDictionary[@"Anchor"]);
#endif

            // Post message to switchToAips
            UIViewController *nc_rear = self.revealViewController.rearViewController;
            MLViewController *vc_rear = [nc_rear.childViewControllers firstObject];
            [vc_rear switchToAipsViewFromFulltext: messageDictionary];
        }
    }
}

@end
