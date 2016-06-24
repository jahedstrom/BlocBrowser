//
//  ViewController.m
//  BlocBrowser
//
//  Created by Jonathan on 6/16/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "AwesomeFloatingToolbar.h"

#define kWebBroswerBackString NSLocalizedString(@"Back", @"Back Command")
#define kWebBroswerForwardString NSLocalizedString(@"Forward", @"Forward Command")
#define kWebBroswerStopString NSLocalizedString(@"Stop", @"Stop Command")
#define kWebBroswerRefreshString NSLocalizedString(@"Refresh", @"Reload Command")

@interface ViewController () <WKNavigationDelegate, UITextFieldDelegate, AwesomeFloatingToolbarDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) AwesomeFloatingToolbar *awesomeToolbar;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation ViewController

#pragma mark - UIViewController

- (void)loadView {
    UIView *mainView = [UIView new];
    
    self.webView = [[WKWebView alloc] init];
    self.webView.navigationDelegate = self;
    
    self.textField = [[UITextField alloc] init];
    self.textField.keyboardType = UIKeyboardTypeURL;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.placeholder = NSLocalizedString(@"Website URL", @"Placeholder text for web browser URL field");
    self.textField.backgroundColor = [UIColor colorWithWhite:220/255.0f alpha:1];
    self.textField.delegate = self;
    
    self.awesomeToolbar = [[AwesomeFloatingToolbar alloc] initWithFourTitles:@[kWebBroswerBackString, kWebBroswerForwardString, kWebBroswerStopString, kWebBroswerRefreshString]];
    self.awesomeToolbar.delegate = self;
    
    for (UIView *viewToAdd in @[self.webView, self.textField, self.awesomeToolbar]) {
        [mainView addSubview:viewToAdd];
    }
    
    self.view = mainView;
}

- (void)viewDidLoad {
    
    NSLog(@"viewDidLoad method called");

    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    // First, calculate some dimensions.
    static const CGFloat itemHeight = 50;
    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat browserHeight = CGRectGetHeight(self.view.bounds) - itemHeight;
    
    // Now, assign the frames
    self.textField.frame = CGRectMake(0, 0, width, itemHeight);
    self.webView.frame = CGRectMake(0, CGRectGetMaxY(self.textField.frame), width, browserHeight);
    
    self.awesomeToolbar.frame = CGRectMake(50, 100, 280, 60);
    
    // can't see anything will testing so set the toolbar background to black..
//    self.awesomeToolbar.backgroundColor = [UIColor blackColor];
//    if (self.webView.opaque) {
//        self.webView.opaque = NO;
//        self.view.backgroundColor = [UIColor blackColor];
//    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    NSString *URLString = textField.text;
    
    NSURL *URL;
    
    // basic regex search to see if user submitted string has a domain name suffix
    NSRange suffix = [URLString rangeOfString:@"\\.([a-z]{3})" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch];
    
    // Check for spaces in incoming text or no domain name? then perform search
    if ([URLString containsString:@" "] || suffix.location == NSNotFound) {
        NSLog(@"%@", URLString);
        NSString *removeSpaces = [URLString stringByReplacingOccurrencesOfString:@" " withString:@"+"];
        NSLog(@"%@", removeSpaces);
        URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.google.com/search?q=%@", removeSpaces]];
    } else if (!URL.scheme) {
        // The user didn't type in http: or https:
        URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", URLString]];
    } else {
        URL = [NSURL URLWithString:URLString];
    }

    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    [self.webView loadRequest:request];

    return NO;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [self updateButtonsandTitle];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self updateButtonsandTitle];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self webView:webView didFailNavigation:navigation withError:error];

}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (error.code != NSURLErrorCancelled) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error")
                                                                       message:[error localizedDescription]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                           style:UIAlertActionStyleCancel handler:nil];
        
        [alert addAction:okAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    
    [self updateButtonsandTitle];
}

#pragma mark - Miscellaneous

- (void)updateButtonsandTitle {
    NSString *webpageTitle = [self.webView.title copy];
    if ([webpageTitle length]) {
        self.title = webpageTitle;
    } else {
        self.title = self.webView.URL.absoluteString;
    }
    
    if (self.webView.isLoading) {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
    
    [self.awesomeToolbar setEnabled:[self.webView canGoBack] forButtonWithTitle:kWebBroswerBackString];
    [self.awesomeToolbar setEnabled:[self.webView canGoForward] forButtonWithTitle:kWebBroswerForwardString];
    [self.awesomeToolbar setEnabled:[self.webView isLoading] forButtonWithTitle:kWebBroswerStopString];
    [self.awesomeToolbar setEnabled:![self.webView isLoading] && self.webView.URL forButtonWithTitle:kWebBroswerRefreshString];
    
}

- (void)resetWebView {
    [self.webView removeFromSuperview];
    
    WKWebView *newWebView = [[WKWebView alloc] init];
    newWebView.navigationDelegate = self;
    [self.view addSubview:newWebView];
    [self.view bringSubviewToFront:self.awesomeToolbar];
    
    self.webView = newWebView;
    
    self.textField.text = nil;
    [self updateButtonsandTitle];
}

#pragma mark - AwesomeFloatingToolbarDelegate

- (void) floatingToolbar:(AwesomeFloatingToolbar *)toolbar didSelectButtonWithTitle:(NSString *)title {
    if ([title isEqual:kWebBroswerBackString]) {
        [self.webView goBack];
    } else if ([title isEqual:kWebBroswerForwardString]) {
        [self.webView goForward];
    } else if ([title isEqual:kWebBroswerStopString]) {
        [self.webView stopLoading];
    } else if ([title isEqual:kWebBroswerRefreshString]) {
        [self.webView reload];
    }
}

- (void)floatingToolbar:(AwesomeFloatingToolbar *)toolbar didTryToPanWithOffset:(CGPoint)offset {
    CGPoint startingPoint = toolbar.frame.origin;
    CGPoint newPoint = CGPointMake(startingPoint.x + offset.x, startingPoint.y + offset.y);
    
    CGRect potentialNewFrame = CGRectMake(newPoint.x, newPoint.y, CGRectGetWidth(toolbar.frame), CGRectGetHeight(toolbar.frame));
    
    if (CGRectContainsRect(self.view.bounds, potentialNewFrame)) {
        toolbar.frame = potentialNewFrame;
    }
}

- (void)floatingToolbar:(AwesomeFloatingToolbar *)toolbar didTryToResizeWithScale:(CGFloat)scale {
    
//    CGAffineTransform transform = CGAffineTransformScale(toolbar.transform, scale, scale);
//    
//    for (UILabel *label in toolbar.subviews) {
//        label.transform = transform;
//    }
//    
//    toolbar.transform = transform;
    
    toolbar.transform = CGAffineTransformScale(toolbar.transform, scale, scale);
//
//       //Relayout
//    [toolbar setNeedsLayout];
//    
//    scale = 1.0;
    
    // I know this isn't optimal.. but handier for debugging purposes
    float currentWidth = CGRectGetWidth(toolbar.frame);
    float currentHeight = CGRectGetHeight(toolbar.frame);
    float newWidth = currentWidth * scale;
    float newHeight = currentHeight * scale;
    toolbar.frame = CGRectMake(toolbar.frame.origin.x, toolbar.frame.origin.y, newWidth, newHeight);
}

@end
