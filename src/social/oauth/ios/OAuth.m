//
//  VKAuthController.m
//  vktest
//
//  Created by Yury Lasty on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OAuth.h"
#import "../../ios/LightViewController.h"
#import <caml/mlvalues.h>                                                                                                                               
#import <caml/callback.h>                                                                                                                               
#import <caml/alloc.h>
#import <caml/threads.h> 

#define CLOSE_BUTTON_HEIGHT 25
#define CLOSE_BUTTON_WIDTH  25

static OAuth * sharedOAuth = nil;

@implementation OAuth

@dynamic closeButtonInsets, closeButtonImageName, closeButtonVisible;

/* 
 * Initialize
 */
-(id)init {
	self = [super init];

	if (self != nil) {
		self.modalPresentationStyle = UIModalPresentationFormSheet;
		_authorizing = NO;
		_closeButton = nil;
		_closeButtonVisible = NO;
		_closeButtonImageName = @"close_auth_dialog_btn";
		_closeButtonInsets =  UIEdgeInsetsZero;
	}

	return self;
}


/*
 *
 */
-(void)updateCloseButtonImage {
  [_closeButton setImage: [UIImage imageNamed: _closeButtonImageName] forState: UIControlStateNormal];
}

/*
 *
 */
-(void)updateCloseButtonFrame {
  CGRect rect = [UIScreen mainScreen].applicationFrame;
  _closeButton.frame = CGRectMake(rect.size.width - CLOSE_BUTTON_WIDTH - _closeButtonInsets.right, 
                                  _closeButtonInsets.top, 
                                  CLOSE_BUTTON_WIDTH, 
                                  CLOSE_BUTTON_HEIGHT);
}

/*
 *
 */
-(void)createCloseButton {
  _closeButton = [[UIButton buttonWithType: UIButtonTypeCustom] retain];
  [self updateCloseButtonImage];
  [self updateCloseButtonFrame];
  [_closeButton addTarget: self action:@selector(onCloseButton) forControlEvents: UIControlEventTouchUpInside];
  _closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
}



/*
 *
 */
-(void)setCloseButtonInsets: (UIEdgeInsets)insets {
    _closeButtonInsets = insets;
    if (_closeButton != nil) {
      [self updateCloseButtonFrame];
    }
}

/*
 *
 */
-(UIEdgeInsets)closeButtonInsets {
  return _closeButtonInsets;
}


/*
 *
 */
-(void)setCloseButtonImageName: (NSString *)name {
  if (_closeButtonImageName != nil) {
    [_closeButtonImageName release];
  }

  _closeButtonImageName = [name retain];
  
  if (_closeButton != nil) {
    [self updateCloseButtonImage];
  }
}


/*
 *
 */
-(NSString *)closeButtonImageName {
  return _closeButtonImageName;
}



/*
 *
 */
-(void)setCloseButtonVisible: (BOOL)visible {
  _closeButtonVisible = visible;
  if (_closeButton == nil && [self isViewLoaded]) {
    [self createCloseButton];
    [self.view addSubview: _closeButton];
  }
}


/*
 *
 */
-(BOOL)closeButtonVisible {
  return _closeButtonVisible;
}



+(OAuth *)sharedInstance {
  if (sharedOAuth == nil) {
    sharedOAuth = [[OAuth alloc] init];
  }
  
  return sharedOAuth;
}


/*
 * Вконтакте выставляют в мета тэге viewport атрибут width в device-width, поэтому при модальном показе на iPad
 * длинна контента получается 768 (или 1024 в зависимости от ориентации). Из-за этого появляется скрол и вообще выглядит как говно.
 */
-(NSString *) setViewportWidth:(CGFloat)inWidth {
	UIWebView * w = (UIWebView *)self.view;
	NSString *result = [w stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"(function ( inWidth ) { "
		"var result = ''; "
		"var viewport = null; "
		"var content = 'width = ' + inWidth; "
		"var document_head = document.getElementsByTagName('head')[0]; "
		"var child = document_head.firstChild; "
		"while ( child ) { "
		"if ( null == viewport && child.nodeType == 1 && child.nodeName == 'META' && child.getAttribute( 'name' ) == 'viewport' ) { "
		"viewport = child; "
		"content = child.getAttribute( 'content' ); "
		"if ( content.search( /width\\s\?=\\s\?[^,]+/ ) < 0 ) { "
		"content = 'width = ' + inWidth + ', ' + content; "
		"} else { "
		"content = content.replace( /width\\s\?=\\s\?[^,]+/ , 'width = ' + inWidth ); "
		"} "
		"} "
		"child = child.nextSibling; "
		"} "
		"if ( null != content ) { "
		"child = document.createElement( 'meta' ); "
		"child.setAttribute( 'name' , 'viewport' ); "
		"child.setAttribute( 'content' , content ); "
		"if ( null == viewport ) { "
		"document_head.appendChild( child ); "
		"result = 'append viewport ' + content; "
		"} else { "
		"document_head.replaceChild( child , viewport ); "
		"result = 'replace viewport ' + content; "
		"} "
		"} "
		"return result; "
		"})( %d )" , (int)inWidth]];

	return result;
}


-(void)onCloseButton {
  [_webview stopLoading];
  
  [self dismissModalViewControllerAnimated: YES];
  value *mlf = (value*)caml_named_value("oauth_redirected");
  NSString * errorUrl = [NSString stringWithFormat: @"%@#error=access_denied", _redirectURIpath];
  caml_acquire_runtime_system();
  if (mlf != NULL) {                                                                                                        
    caml_callback(*mlf, caml_copy_string([errorUrl UTF8String]));
  }
  caml_release_runtime_system();
  
}


/*                                                                                                                                                                                      
 *                                                                                                                                                                                      
 */                                                                                                                                                                                     
-(void)loadView {                                                                                                                                                                       
	CGRect rect = [UIScreen mainScreen].applicationFrame; 
	_webview = [[UIWebView alloc] initWithFrame: rect];                                                                                                                                 
	_webview.delegate = self;                                                                                                                                                           
	_webview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;                                                                                     
	_webview.scalesPageToFit = NO;                                                                                                                                                      
	self.view = _webview;   

	_spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	_spinner.center = CGPointMake(CGRectGetMidX(_webview.frame), CGRectGetMidY(_webview.frame));
	_spinner.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin ;
	[self.view addSubview:_spinner];

	if (_closeButtonVisible) {
		[self createCloseButton];
		[self.view addSubview: _closeButton];
	}
    
}                                                                                                                                                                                       

-(void)viewDidUnload {

}

/*                                                                                                                                                                                      
 *                                                                                                                                                                                      
 */                                                                                                                                                                                     
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {                                                                                                    
    return YES;                                                                                                                                                                         
}                                                                                                                                                                                       


/*                                                                                                                                                                                      
 *  Show auth dialog                                                                                                                                                                    
 */                                                                                                                                                                                     
-(void)authorize:(NSURL *)url { 

    _authorizing = YES;

    NSRange redirect_range = [url.query rangeOfString:@"redirect_uri="];
    NSRange amp_search_range;
    amp_search_range.location = redirect_range.location + redirect_range.length;
    amp_search_range.length = [url.query length] - amp_search_range.location;
        
    NSRange amp_range = [url.query rangeOfString:@"&" options:0 range:amp_search_range];
    NSRange substr_range;
    substr_range.location = amp_search_range.location;
    
    if (amp_range.location == NSNotFound) {
        substr_range.length   = [url.query length] - redirect_range.length - redirect_range.location;
    } else {
        substr_range.length   = amp_range.location - substr_range.location;    
    }
     
    NSURL * u = [NSURL URLWithString:[[url.query substringWithRange:substr_range] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    _redirectURIpath = [u.path retain];
    
    NSLog(@"Saved path %@", _redirectURIpath);
    
    /*                                                                                                                                                                                      
     NSString * urlstr = [NSString stringWithFormat:@"http://oauth.vkontakte.ru/authorize?client_id=%@&scope=%@&redirect=%@&display=touch&response_type=token",                          
     _appid, permissions, [@"http://oauth.vkontakte.ru/blank.html" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];                                                
     */                                                                                                                                                                                      
    
    [_webview loadRequest:[NSURLRequest requestWithURL: url]];                                                                                                                          
}                                                                                                                                                                                       


/*                                                                                                                                                                                      
 * webview delegate                                                                                                                                                                     
 */                                                                                                                                                                                     
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {                                                                                                            

    if (!_authorizing) {
      return;
    }

    _authorizing = NO;
  
    NSLog(@"HERE: didFaileLoad %@", error.localizedDescription);
    [_spinner stopAnimating];
	[self dismissModalViewControllerAnimated: YES];
	NSString * errorUrl = [NSString stringWithFormat: @"%@#error=server_error&error_description=webViewdidFailLoadWithError", _redirectURIpath];
    value * mlf = (value*)caml_named_value("oauth_redirected"); 
    caml_acquire_runtime_system();
    caml_callback(*mlf, caml_copy_string([errorUrl UTF8String]));
    caml_release_runtime_system();        	
}       


/*                                                                                                                                                                                      
 *                                                                                                                                                                                      
 */                                                                                                                                                                                     
-(void)webViewDidFinishLoad:(UIWebView *)webView {                                                                                                                                      

    if (!_authorizing) {
      return;
    }
    
    NSLog(@"HERE: Finished loading %@", webView.request.URL.absoluteString);
    [_spinner stopAnimating];
	NSString * content = [webView stringByEvaluatingJavaScriptFromString: @"document.body.innerHTML"];
	
	
	// В VK если сперва вбили левый логин, а потом нажали cancel, то нас не редиректят на blank.html
	if ([@"security breach" isEqualToString: content]) {
		[self dismissModalViewControllerAnimated: YES];
		value *mlf = (value*)caml_named_value("oauth_redirected");
		NSString * errorUrl = [NSString stringWithFormat: @"%@#error=access_denied", _redirectURIpath];
		caml_acquire_runtime_system();
		if (mlf != NULL) {                                                                                                        
		    caml_callback(*mlf, caml_copy_string([errorUrl UTF8String]));
		}
		caml_release_runtime_system();
		return;
	}  

    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self setViewportWidth: 540.0f];
    }
}


/*
 *
 */
-(void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"HERE: Started loading %@", webView.request.URL.absoluteString);
    [_spinner startAnimating];
}


/*
 *
 */
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"Saved path: %@ My path %@", _redirectURIpath, request.URL.path);
    
    if ([request.URL.path isEqualToString: _redirectURIpath]) {
        if (_authorizing) {
          _authorizing = NO;
          [self dismissModalViewControllerAnimated:YES];
          [_spinner stopAnimating];
          value * mlf = (value*)caml_named_value("oauth_redirected"); 
          caml_acquire_runtime_system();
          caml_callback(*mlf, caml_copy_string([request.URL.absoluteString UTF8String]));
          caml_release_runtime_system();        
          return NO;
        }
    }
    return YES;
}


-(void)dealloc {
	[super dealloc];
}


@end

