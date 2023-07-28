//
//  MLHINOAuthViewController.m
//  AmikoDesitin
//
//  Created by b123400 on 2023/07/27.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLHINOAuthViewController.h"
#import <WebKit/WebKit.h>
#import "MLHINTokens.h"
#import "MLHINClient.h"

@interface MLHINOAuthViewController () <WKNavigationDelegate>
@property (weak, nonatomic) IBOutlet WKWebView *webView;
@property (assign, nonatomic) BOOL hasReceivedToken;

@end

@implementation MLHINOAuthViewController

- (instancetype)init {
    if (self = [super initWithNibName:@"MLHINOAuthViewController" bundle:nil]) {
        
    }
    return self;
}

- (NSURL *)authURL {
    @throw [NSException exceptionWithName:@"Subclass must override authURL" reason:nil userInfo:nil];
}

- (void)receivedTokens:(MLHINTokens *)tokens {
    @throw [NSException exceptionWithName:@"Subclass must override receivedTokens:" reason:nil userInfo:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.loadingSpinner = [[UIActivityIndicatorView alloc] init];
    self.loadingSpinner.hidesWhenStopped = YES;
    [self.loadingSpinner stopAnimating];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.loadingSpinner];

    self.webView.navigationDelegate = self;
    NSURLRequest *request = [NSURLRequest requestWithURL:self.authURL];
    [self.webView loadRequest:request];
}

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    typeof(self) __weak _self = self;
    if ([url.host isEqual:@"localhost"] && [url.port isEqual:@(8080)] && [url.path isEqual:@"/callback"]) {
        decisionHandler(WKNavigationActionPolicyCancel);
        _self.hasReceivedToken = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_self.loadingSpinner startAnimating];
            [_self displayStatus:NSLocalizedString(@"Fetching Access Token", @"")];
        });
        NSLog(@"url: %@", url);
//    http://localhost:8080/callback?state=teststate&code=xxxxxx
        NSURLComponents *components = [NSURLComponents componentsWithURL:url
                                                 resolvingAgainstBaseURL:NO];
        for (NSURLQueryItem *query in [components queryItems]) {
            if ([query.name isEqual:@"code"]) {
                [[MLHINClient shared] fetchAccessTokenWithAuthCode:query.value
                                                        completion:^(NSError * _Nullable error, MLHINTokens * _Nullable tokens) {
                    if (error) {
                        [_self displayError:error];
                        return;
                    }
                    if (!tokens) {
                        [_self displayError:[NSError errorWithDomain:@"com.ywesee.AmikoDesitin"
                                                                code:0
                                                            userInfo:@{
                            NSLocalizedDescriptionKey: @"Invalid token response"
                        }]];
                    }
                    [_self displayStatus:NSLocalizedString(@"Received Access Token", @"")];
                    [_self receivedTokens:tokens];
                }];
                break;
            }
        }
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if (!self.hasReceivedToken) {
        [self.loadingSpinner startAnimating];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (!self.hasReceivedToken) {
        [self.loadingSpinner stopAnimating];
    }
}

- (void)displayError:(NSError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"")
                                                                                             message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:NO completion:nil];
}

- (void)displayStatus:(NSString *)status {
    if ([NSThread isMainThread]) {
        self.title = status;
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self displayStatus:status];
        });
    }
}

@end
