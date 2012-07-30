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

#define CLOSE_BUTTON_HEIGHT 25 // ???
#define CLOSE_BUTTON_WIDTH  25

//static OAuth * sharedOAuth = nil;

@implementation OAuth

//@dynamic closeButtonInsets, closeButtonImageName, closeButtonVisible;


/* 
 * Initialize
 */
-(id)initWithURL:(value)mlURL closeButton:(value)mlCloseButton {
	self = [super init];
	//NSLog(@"init OAUTH");

	if (self != nil) {
		self.modalPresentationStyle = UIModalPresentationFormSheet;
		_authorizing = NO;
		// close button
		_closeButton = nil;
		_closeButtonInsets =  UIEdgeInsetsZero;
		_closeButtonImageName = @"close_auth_dialog_btn";
		if (Is_block(mlCloseButton)) {
			value button = Field(mlCloseButton,0);
			_closeButtonVisible = YES;
			// insets
			value insets = Field(button,0);
			_closeButtonInsets = 
				UIEdgeInsetsMake(Int_val(Field(insets,0)), Int_val(Field(insets,1)), Int_val(Field(insets,2)), Int_val(Field(insets,3)));
			// image
			if (Is_block(Field(button,1))) {
				value image = Field(Field(button,1),0);
				_closeButtonImageName = [[NSString alloc] initWithCString:String_val(image) encoding:NSUTF8StringEncoding];
			}
		} else _closeButtonVisible = NO;

		// URL
		url = [[NSURL alloc] initWithString:[NSString stringWithCString:String_val(mlURL) encoding:NSASCIIStringEncoding]];
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
		 
		NSURL *u = [NSURL URLWithString:[[url.query substringWithRange:substr_range] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
		_redirectURIpath = [u.path retain];

		_webview = nil;
		_spinner = nil;
	}

	return self;
}

-(void)start {
	[[LightViewController sharedInstance] presentModalViewController:self animated: YES];
}

/*
-(void)updateCloseButtonImage {
  [_closeButton setImage: [UIImage imageNamed: _closeButtonImageName] forState: UIControlStateNormal];
}

-(void)updateCloseButtonFrame {
  CGRect rect = [UIScreen mainScreen].applicationFrame;
  _closeButton.frame = CGRectMake(rect.size.width - CLOSE_BUTTON_WIDTH - _closeButtonInsets.right, 
                                  _closeButtonInsets.top, 
                                  CLOSE_BUTTON_WIDTH, 
                                  CLOSE_BUTTON_HEIGHT);
}

-(void)createCloseButton {
  _closeButton = [[UIButton buttonWithType: UIButtonTypeCustom] retain];
  [_closeButton setImage: [UIImage imageNamed: _closeButtonImageName] forState: UIControlStateNormal];
  CGRect rect = [UIScreen mainScreen].applicationFrame;
  _closeButton.frame = CGRectMake(rect.size.width - CLOSE_BUTTON_WIDTH - _closeButtonInsets.right, 
                                  _closeButtonInsets.top, 
                                  CLOSE_BUTTON_WIDTH, 
                                  CLOSE_BUTTON_HEIGHT);
  [_closeButton addTarget: self action:@selector(onCloseButton) forControlEvents: UIControlEventTouchUpInside];
  _closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
}
 */


/*
-(void)setCloseButtonInsets: (UIEdgeInsets)insets {
    _closeButtonInsets = insets;
    if (_closeButton != nil) {
      [self updateCloseButtonFrame];
    }
}

-(UIEdgeInsets)closeButtonInsets {
  return _closeButtonInsets;
}

-(void)setCloseButtonImageName: (NSString *)name {
  if (_closeButtonImageName != nil) {
    [_closeButtonImageName release];
  }

  _closeButtonImageName = [name retain];
  
  if (_closeButton != nil) {
    [self updateCloseButtonImage];
  }
}

-(NSString *)closeButtonImageName {
  return _closeButtonImageName;
}


-(void)setCloseButtonVisible: (BOOL)visible {
  _closeButtonVisible = visible;
  if (_closeButton == nil && [self isViewLoaded]) {
    [self createCloseButton];
    [self.view addSubview: _closeButton];
  }
}

-(BOOL)closeButtonVisible {
  return _closeButtonVisible;
}



+(OAuth *)sharedInstance {
  if (sharedOAuth == nil) {
    sharedOAuth = [[OAuth alloc] init];
  }
  
  return sharedOAuth;
}

*/


/*
 * Вконтакте выставляют в мета тэге viewport атрибут width в device-width, поэтому при модальном показе на iPad
 * длинна контента получается 768 (или 1024 в зависимости от ориентации). Из-за этого появляется скрол и вообще выглядит как говно.
 */
-(NSString *) setViewportWidth:(CGFloat)inWidth {
	NSString *result = [_webview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"(function ( inWidth ) { "
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
	NSString * errorUrl = [NSString stringWithFormat: @"%@#error=access_denied", _redirectURIpath];
	[[LightViewController sharedInstance] dismissModalViewControllerAnimated: NO];
  caml_acquire_runtime_system();
  value *mlf = (value*)caml_named_value("oauth_redirected");
  if (mlf != NULL) {                                                                                                        
    caml_callback(*mlf, caml_copy_string([errorUrl UTF8String]));
  }
  caml_release_runtime_system();
  
}


/*                                                                                                                                                                                      
 *                                                                                                                                                                                      
 */                                                                                                                                                                                     
-(void)loadView {                                                                                                                                                                       
	//NSLog(@"OAUTH load view");
	CGRect rect = [UIScreen mainScreen].applicationFrame; 
	_webview = [[UIWebView alloc] initWithFrame: rect];                                                                                                                                 
	_webview.delegate = self;                                                                                                                                                           
	_webview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;                                                                                     
	_webview.scalesPageToFit = YES;                                                                                                                                                      
	self.view = _webview;   

	_spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	_spinner.center = CGPointMake(CGRectGetMidX(_webview.frame), CGRectGetMidY(_webview.frame));
	_spinner.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin ;
	[self.view addSubview:_spinner];

	if (_closeButtonVisible) {
		_closeButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		[_closeButton setImage: [UIImage imageNamed: _closeButtonImageName] forState: UIControlStateNormal];
		CGRect rect = [UIScreen mainScreen].applicationFrame;
		_closeButton.frame = CGRectMake(rect.size.width - CLOSE_BUTTON_WIDTH - _closeButtonInsets.right, 
																		_closeButtonInsets.top, 
																		CLOSE_BUTTON_WIDTH, 
																		CLOSE_BUTTON_HEIGHT);
		[_closeButton addTarget: self action:@selector(onCloseButton) forControlEvents: UIControlEventTouchUpInside];
		_closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
		[self.view addSubview: _closeButton];
	}
    
	_authorizing = YES;
	[_webview loadRequest:[NSURLRequest requestWithURL:url]];                                                                                                                          
}

-(void)viewDidUnload {
	//NSLog(@"VIEW did unload");
	if (_closeButton) [_closeButton release];
	_webview.delegate = nil;
	[_webview release];
	_webview = nil;
	[_spinner release];
	_spinner = nil;
}

/*                                                                                                                                                                                      
 *                                                                                                                                                                                      
 */                                                                                                                                                                                     
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {                                                                                                    
	return [[LightViewController sharedInstance] shouldAutorotateToInterfaceOrientation:orientation];
}                                                                                                                                                                                       


/*                                                                                                                                                                                      
 *  Show auth dialog                                                                                                                                                                    
-(void)authorize:(NSURL *)url { 
	if (_webview == nil) return; // raise exn

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
	
	
	[_webview loadRequest:[NSURLRequest requestWithURL: url]];                                                                                                                          
}                                                                                                                                                                                       
*/


/*                                                                                                                                                                                      
 * webview delegate                                                                                                                                                                     
 */                                                                                                                                                                                     
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {                                                                                                            
	if (!_authorizing) {
		return;
	}
	_authorizing = NO;
	//NSLog(@"didFailLoad %@", error.localizedDescription);
	[_spinner stopAnimating];
	NSString * errorUrl = [NSString stringWithFormat: @"%@#error=server_error&error_description=webViewdidFailLoadWithError", _redirectURIpath];
	[[LightViewController sharedInstance] dismissModalViewControllerAnimated: NO];
	NSCAssert([NSThread isMainThread],@"OAuth didFail not in main thread");
	caml_acquire_runtime_system();
	value * mlf = (value*)caml_named_value("oauth_redirected"); 
	caml_callback(*mlf, caml_copy_string([errorUrl UTF8String]));
	caml_release_runtime_system();        	
}       


/*                                                                                                                                                                                      
 *                                                                                                                                                                                      
 */                                                                                                                                                                                     
-(void)webViewDidFinishLoad:(UIWebView *)webView {                                                                                                                                      
  //NSLog(@"Finished loading '%@'", webView.request.URL.absoluteString);

  if (!_authorizing) {
    return;
  }
  
  [_spinner stopAnimating];
	NSString * content = [webView stringByEvaluatingJavaScriptFromString: @"document.body.innerHTML"];
	
	
	NSCAssert([NSThread isMainThread],@"OAuth didFinish not in main thread");
	// В VK если сперва вбили левый логин, а потом нажали cancel, то нас не редиректят на blank.html
	if ([@"security breach" isEqualToString: content]) {
		NSString * errorUrl = [NSString stringWithFormat: @"%@#error=access_denied", _redirectURIpath];
		[[LightViewController sharedInstance] dismissModalViewControllerAnimated: NO];
		caml_acquire_runtime_system();
		value *mlf = (value*)caml_named_value("oauth_redirected");
		if (mlf != NULL) {                                                                                                        
		    caml_callback(*mlf, caml_copy_string([errorUrl UTF8String]));
		}
		caml_release_runtime_system();
		return;
	} else if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		[self setViewportWidth: 540.0f];
	}
}


/*
 *
 */
-(void)webViewDidStartLoad:(UIWebView *)webView {
	//NSLog(@"didStartLoad '%@'", webView.request.URL.absoluteString);
	[_spinner startAnimating];
}

/*
 *
 */
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	//NSLog(@"Should start %@, paths: [%@ = %@]",request.URL.absoluteString,request.URL.path,_redirectURIpath);
	
	if ([request.URL.path isEqualToString: _redirectURIpath]) {
		if (_authorizing) {
			NSCAssert([NSThread isMainThread],@"OAuth shotStartLoad not in main thread");
			_authorizing = NO;
			[_spinner stopAnimating];
			[[LightViewController sharedInstance] dismissModalViewControllerAnimated:NO];
			caml_acquire_runtime_system();
			value * mlf = (value*)caml_named_value("oauth_redirected"); 
			caml_callback(*mlf, caml_copy_string([request.URL.absoluteString UTF8String]));
			caml_release_runtime_system();        
			//NSLog(@"ml callback successfully called");
			return NO;
		}
	}
	return YES;
}


-(void)dealloc {
	//NSLog(@"DEALLOC OAUTH!!!! %p",self);
	if (_closeButton) [_closeButton release];
	if (_spinner) [_spinner release];
	if (_webview) {
		_webview.delegate = nil;
		[_webview release];
	};
	_authorizing = NO;
	[url release];
	[_redirectURIpath release];
	[super dealloc];
}


@end

