//
//  FullTextViewController.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 23 Jul 2019.
//  Copyright © 2019 Ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FullTextViewController : UIViewController <WKNavigationDelegate>
{
    UISearchBar *searchField;
    //WKWebView *webView;
    NSString *htmlAnchor;
}

@property (nonatomic, retain) IBOutlet UISearchBar *searchField;
@property (nonatomic, retain) IBOutlet WKWebView *webView;
@property (nonatomic, copy) NSString *htmlStr;
@property (strong, nonatomic) NSString *productURL;

+ (FullTextViewController *)sharedInstance;

- (instancetype) initWithNibName:(NSString *)nibNameOrNil
                          bundle:(NSBundle *)nibBundleOrNil
                           title:(NSString *)title
                        andParam:(int)numRevealButtons;

- (void) updateFullTextSearchView:(NSString *)contentStr;
- (void) ftOverviewDidChangeSelection:(NSNotification *)aNotification;

@end

NS_ASSUME_NONNULL_END
