//
// QR Code Generator - generates UIImage from NSString
//
// Copyright (C) 2012 http://moqod.com Andrew Kopanev <andrew@moqod.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy 
// of this software and associated documentation files (the "Software"), to deal 
// in the Software without restriction, including without limitation the rights 
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
// of the Software, and to permit persons to whom the Software is furnished to do so, 
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all 
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
// DEALINGS IN THE SOFTWARE.
//

#import "TCQRCodeGenerator.h"
#import "qrencode.h"

@interface TCQRCodeGenerator ()

@property (nonatomic, assign) QRcode *qrcode;

@end

@implementation TCQRCodeGenerator

@synthesize text = _text;
@synthesize blackPointColor = _blackPointColor;
@synthesize whitePointColor = _whitePointColor;
@synthesize qrMargin = _qrMargin;
@synthesize qrErrCorrLv = _qrErrCorrLv;

@synthesize qrcode = _qrcode;

- (void)dealloc
{
    self.text = nil;
    self.qrcode = NULL;
    self.blackPointColor = nil;
    self.whitePointColor = nil;
    
    [super dealloc];
}

- (id)init
{
    if (self = [super init])
    {
        self.qrcode = NULL;
        self.blackPointColor = [UIColor blackColor];
        self.whitePointColor = [UIColor whiteColor];
        self.qrMargin = QRCodeMaskMargin;
        self.qrErrCorrLv = kTCQR_ECLEVEL_L;
    }
    
    return self;
}

- (id)initWithText:(NSString *)text
{
    if (self = [self init])
    {
        self.text = text;
    }
    
    return self;
}

- (void)setText:(NSString *)text
{
    [text retain];
    [_text release];
    _text = text;
    
    self.qrcode = NULL;
    if (_text.length > 0)
    {
        self.qrcode = QRcode_encodeString([_text UTF8String], 0, self.qrErrCorrLv, QR_MODE_8, 1);
    }
}

- (void)setQrcode:(QRcode *)qrcode
{
    if (_qrcode)
    {
        QRcode_free(_qrcode);
        _qrcode = NULL;
    }
    
    _qrcode = qrcode;
}

- (UIImage *)qrImageForSize:(CGFloat)size
{
    if (0 == self.text.length || size <= 0.0f)
    {
        return nil;
    }
	
	if (!self.qrcode)
    {
		return nil;
	}
	
    CGFloat scale = [[UIScreen mainScreen] scale];
    size_t scaleSize = size * scale;
    
	// create context
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef ctx = CGBitmapContextCreate(0, scaleSize, scaleSize, 8, scaleSize * 4, colorSpace, kCGImageAlphaPremultipliedLast);
	
	CGAffineTransform translateTransform = CGAffineTransformMakeTranslation(0, -size);
	CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scale, -scale);
	CGContextConcatCTM(ctx, CGAffineTransformConcat(translateTransform, scaleTransform));
    CGContextSetAllowsAntialiasing(ctx, true);
    CGContextSetShouldAntialias(ctx, true);
	
	// draw QR on this context
	[TCQRCodeGenerator drawQRCode:self.qrcode inContext:ctx withSize:size blackColor:self.blackPointColor whiteColor:self.whitePointColor qrMargin:self.qrMargin];
	
	// get image
	CGImageRef qrCGImage = CGBitmapContextCreateImage(ctx);
	UIImage * qrImage = [UIImage imageWithCGImage:qrCGImage scale:scale orientation:UIImageOrientationUp];
	
	// some releases
	CGContextRelease(ctx);
	CGImageRelease(qrCGImage);
	CGColorSpaceRelease(colorSpace);
	
	return qrImage;
}

+ (void)drawQRCode:(QRcode *)code inContext:(CGContextRef)ctx withSize:(CGFloat)size blackColor:(UIColor *)blackColor whiteColor:(UIColor *)whiteColor qrMargin:(CGFloat)qrMargin
{
    if (!code || !ctx || !blackColor || !whiteColor)
    {
        return;
    }
    
	unsigned char *data = 0;
	int width = 0;
	data = code->data;
	width = code->width;
	float zoom = (double)size / (code->width + 2.0 * qrMargin);
	CGRect rectDraw = CGRectMake(0, 0, zoom, zoom);
	
    CGContextSetBlendMode(ctx, kCGBlendModeCopy);
	// draw white background
    CGContextSetFillColorWithColor(ctx, whiteColor.CGColor);
    CGContextFillRect(ctx, CGRectMake(0, 0, size, size));
    
    // draw black points
	CGContextSetFillColorWithColor(ctx, blackColor.CGColor);
	for(int i = 0; i < width; ++i)
    {
		for(int j = 0; j < width; ++j) {
			if(*data & 1)
            {
				rectDraw.origin = CGPointMake((j + qrMargin) * zoom,(i + qrMargin) * zoom);
				CGContextAddRect(ctx, rectDraw);
			}
			++data;
		}
	}
	CGContextFillPath(ctx);
}

+ (UIImage *)qrImageForString:(NSString *)string imageSize:(CGFloat)size
{
    TCQRCodeGenerator *qrCodeGen = [[TCQRCodeGenerator alloc] initWithText:string];
    UIImage *qrImage = [qrCodeGen qrImageForSize:size];
    
    [qrCodeGen release];
    return qrImage;
}

@end
