//
//  VKAuthController.m
//  vktest
//
//  Created by Yury Lasty on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKAuth.h"
#import "../ios/LightViewController.h"
#import <caml/mlvalues.h>                                                                                                                               
#import <caml/callback.h>                                                                                                                               
#import <caml/alloc.h>
#import <caml/threads.h> 

@implementation VKAuth

/* 
 * Initialize
 */
-(id)initWithAppid: (NSString *)appid {
	self = [super init];

	if (self != nil) {
		_appid = [appid copy];
		self.modalPresentationStyle = UIModalPresentationFormSheet;
	}

	return self;
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
-(void)authorize:(NSString *)permissions {
	NSString * urlstr = [NSString stringWithFormat:@"http://oauth.vkontakte.ru/authorize?client_id=%@&scope=%@&redirect=%@&display=touch&response_type=token", 
		 _appid, permissions, [@"http://oauth.vkontakte.ru/blank.html" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

	[_webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlstr]]];
}



/*
 * webview delegate
 */
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	[self dismissModalViewControllerAnimated: YES];
	[[LightViewController sharedInstance] becomeActive];
	caml_acquire_runtime_system();
	value *mlf = (value*)caml_named_value("vk_login_failed");
	if (mlf != NULL) {                                                                                                                   
		caml_callback(*mlf, Val_int(1));
	}
	caml_release_runtime_system();
}


/*
 *
 */
-(void)webViewDidFinishLoad:(UIWebView *)webView {
	NSString * content = [webView stringByEvaluatingJavaScriptFromString: @"document.body.innerHTML"];
	//    NSLog(@"URL is: %@\n\nContent is:\n%@\n\n ", [webView.request.URL absoluteString], content);


	value *mlf;

	// если сперва вбили левый логин, а потом нажали cancel, то нас не редиректят на blank.html
	if ([@"security breach" isEqualToString: content]) {
		[self dismissModalViewControllerAnimated: YES];
		[[LightViewController sharedInstance] becomeActive];
		caml_acquire_runtime_system();
		if (mlf != NULL) {                                                                                                        
			caml_callback(*mlf, Val_int(0));                                                                                                                                            
		}
		caml_release_runtime_system();
		return;
	}  


	// промежуточный вызов
	if (![webView.request.URL.path isEqualToString:@"/blank.html"]) {
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            [self setViewportWidth: 540.0f];
        }
		return;
	}


	NSArray * pairs = [webView.request.URL.fragment componentsSeparatedByString:@"&"];   
	NSString *token, *expires, *user_id;
	token = expires = user_id = nil;

	for (NSString * pair in pairs) {
		NSArray * kv = [pair componentsSeparatedByString:@"="];
		if ([[kv objectAtIndex:0] isEqualToString:@"error"]) {
			[self dismissModalViewControllerAnimated: YES];
			[[LightViewController sharedInstance] becomeActive];
			caml_acquire_runtime_system();
			mlf = (value*)caml_named_value("vk_login_failed");
			if (mlf != NULL) {
				caml_callback(*mlf, Val_int(0));
			}
			caml_release_runtime_system();
			return; 
		} else if ([[kv objectAtIndex:0] isEqualToString:@"access_token"]) {
			token = [kv objectAtIndex:1];
		} else if ([[kv objectAtIndex:0] isEqualToString:@"expires_in"]) {
			expires = [kv objectAtIndex:1]; 
		} else if ([[kv objectAtIndex:0] isEqualToString:@"user_id"]) {
			user_id = [kv objectAtIndex:1];
		}
	}

	[self dismissModalViewControllerAnimated: YES];
	[[LightViewController sharedInstance] becomeActive];

	caml_acquire_runtime_system();
	mlf = (value*)caml_named_value("vk_logged_in");
	if (mlf != NULL) {
		caml_callback3(*mlf, 
				caml_copy_string([user_id UTF8String]),
				caml_copy_string([token   UTF8String]),
				caml_copy_string([expires UTF8String])
			      );
	}
	caml_release_runtime_system();
}

#if 0

/*
 * Show captcha
 */
-(void)displayCaptchaWithSid: (NSString *)captcha_sid andUrl: (NSURL *)captcha_url {
	_captchaSid = [captcha_sid copy];  
	NSData * imgdata = [NSData dataWithContentsOfURL: captcha_url];
	UIImage * img = [UIImage imageWithData: imgdata];
	_captchaView = [[UIImageView alloc] initWithImage: img];
	[self.view addSubview: _captchaView];

	if (self.view.superview == nil) {
		[[[[UIApplication sharedApplication] windows] objectAtIndex:0] addSubview:self.view];
	}

	UIAlertView * alert = [[[UIAlertView alloc] initWithTitle: @"Captcha" message: @"Enter text in the picture" delegate:self cancelButtonTitle:nil  otherButtonTitles: @"OK", nil] autorelease];
	[alert show];
}


/* 
 *
 */
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	value * mlf = (value*)caml_named_value("vk_captcha_entered");
	caml_acquire_runtime_system();
	if (mlf != NULL) {
		caml_callback2(*mlf, 
				caml_copy_string([_captchaSid UTF8String]),
				caml_copy_string([@"Hello"  UTF8String])
			      );
	}  
	caml_release_runtime_system();
}

#endif

@end
