// Copyright (C) 2011-2012 by Tapjoy Inc.
//
// This file is part of the Tapjoy SDK.
//
// By using the Tapjoy SDK in your software, you agree to the terms of the Tapjoy SDK License Agreement.
//
// The Tapjoy SDK is bound by the Tapjoy SDK License Agreement and can be found here: https://www.tapjoy.com/sdk/license


#import "TJCFeaturedAppModel.h"
#import "TJCFeaturedAppManager.h"
#import "TJCConstants.h"
#import "TJCLog.h"

@implementation TJCFeaturedAppModel

@synthesize cost = cost_;
@synthesize storeID = storeID_;
@synthesize name = name_;
@synthesize description = description_;
@synthesize iconURL = iconURL_;
@synthesize largeIconURL = largeIconURL_;
@synthesize redirectURL = redirectURL_;
@synthesize amount = amount_;
@synthesize maxTimesToDisplayThisApp = maxTimesToDisplayThisApp_;
@synthesize fullScreenAdURL = fullScreenAdURL_;

- (id) initWithTBXML:(TJCTBXMLElement*) aXMLElement
{
	if ((self = [super init]))
	{
		if (!aXMLElement) 
		{
			return self;
		}
		cost_ = [[TJCTBXML textForElement:[TJCTBXML childElementNamed:@"Cost" parentElement:aXMLElement]] copy];
		storeID_ = [[TJCTBXML textForElement:[TJCTBXML childElementNamed:@"StoreID" parentElement:aXMLElement]] copy];
		name_ = [[TJCTBXML textForElement:[TJCTBXML childElementNamed:@"Name" parentElement:aXMLElement]] copy];
		description_ = [[TJCTBXML textForElement:[TJCTBXML childElementNamed:@"Description" parentElement:aXMLElement]] copy];
		iconURL_ = [[TJCTBXML textForElement:[TJCTBXML childElementNamed:@"IconURL" parentElement:aXMLElement]] copy];
		largeIconURL_ = [[TJCTBXML textForElement:[TJCTBXML childElementNamed:@"MediumIconURL" parentElement:aXMLElement]] copy];
		redirectURL_ = [[TJCTBXML textForElement:[TJCTBXML childElementNamed:@"RedirectURL" parentElement:aXMLElement]] copy];
		amount_ = [TJCTBXML numberForElement:[TJCTBXML childElementNamed:@"Amount" parentElement:aXMLElement]];
		
		if (maxTimesToDisplayThisApp_ < 0)
		{
			maxTimesToDisplayThisApp_ = TJC_FEATURED_APP_DEFAULT_MAX_DISPLAY_COUNT;
		}
		
		// Sometimes the URL returned from the server has unescaped characters, make sure that it's all escaped.
		fullScreenAdURL_ = [[[TJCTBXML textForElement:[TJCTBXML childElementNamed:@"FullScreenAdURL" parentElement:aXMLElement]] 
								  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] copy];
	}
	return self;
}


- (void) dealloc
{
	[cost_ release];
	[storeID_ release];
	[name_ release];
	[redirectURL_ release];
	[iconURL_ release];
	[largeIconURL_ release];
	[description_ release];
	[fullScreenAdURL_ release];	
	[super dealloc];
}

@end
