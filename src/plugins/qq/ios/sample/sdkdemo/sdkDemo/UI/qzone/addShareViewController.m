//
//  addShareViewController.m
//  sdkDemo
//
//  Created by xiaolongzhang on 13-4-2.
//  Copyright (c) 2013年 xiaolongzhang. All rights reserved.
//

#import "addShareViewController.h"
#import "sdkCall.h"
#import <QuartzCore/QuartzCore.h>

#define K_KEYBOARD_HEIGHT 180.0f
@interface addShareViewController () <UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UITextField *shareTitle;
@property (strong, nonatomic) IBOutlet UITextView *shareUrl;
@property (strong, nonatomic) IBOutlet UITextView *shareSummary;
@property (strong, nonatomic) IBOutlet UITextView *shareComment;
@property (strong, nonatomic) IBOutlet UITextView *shareImageURL;
@property (assign, nonatomic) CGSize scrollViewContentSize;

@end

@implementation addShareViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addShareReponse:) name:kAddShareResponse object:[sdkCall getinstance]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if ([[self view] isKindOfClass:[UIScrollView class]])
    {
        CGRect rect = [[UIScreen mainScreen] bounds];
        [(UIScrollView *)[self view] setContentSize:CGSizeMake(rect.size.width, rect.size.height + 50)];
        [[self view] setFrame:rect];
        [self setScrollViewContentSize:[(UIScrollView *)[self view] contentSize]];
    }
    
    UIControl *backView = [[UIControl alloc] initWithFrame:[[self view] bounds]];
    [[self view] insertSubview:backView atIndex:0];
    [backView addTarget:self action:@selector(backgroundTap:) forControlEvents:UIControlEventTouchDown];
    
    CALayer *layer = [[self shareComment] layer];
    [layer setMasksToBounds:YES];
    [layer setCornerRadius:4.0f];
    [layer setBorderWidth:1.0f];
    [layer setBorderColor:[[UIColor blackColor] CGColor]];
    [[self shareComment] setDelegate:self];
    
    layer = [[self shareSummary] layer];
    [layer setMasksToBounds:YES];
    [layer setCornerRadius:4.0f];
    [layer setBorderWidth:1.0f];
    [layer setBorderColor:[[UIColor blackColor] CGColor]];
    [[self shareSummary] setDelegate:self];
    
    layer = [[self shareImageURL] layer];
    [layer setMasksToBounds:YES];
    [layer setCornerRadius:4.0f];
    [layer setBorderWidth:1.0f];
    [layer setBorderColor:[[UIColor blackColor] CGColor]];
    [[self shareImageURL] setDelegate:self];
    
    layer = [[self shareUrl] layer];
    [layer setMasksToBounds:YES];
    [layer setCornerRadius:4.0f];
    [layer setBorderWidth:1.0f];
    [layer setBorderColor:[[UIColor blackColor] CGColor]];
    [[self shareUrl] setDelegate:self];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(close)];
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(addshare)];
    [[self navigationItem] setRightBarButtonItem:leftItem];
    [[self navigationItem] setLeftBarButtonItem:rightItem];
    [self setTitle:@"add_share"];
}

- (IBAction)backgroundTap:(id)sender
{
    [[self shareComment] resignFirstResponder];
    [[self shareSummary] resignFirstResponder];
    [[self shareImageURL] resignFirstResponder];
    [[self shareUrl] resignFirstResponder];
    [[self shareTitle] resignFirstResponder];
    
    [(UIScrollView *)[self view] setContentSize:[self scrollViewContentSize]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)close
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)addshare
{
    TCAddShareDic *params = [TCAddShareDic dictionary];
    params.paramTitle = [[self shareTitle] text];
    params.paramComment = [[self shareComment] text];
    params.paramSummary =  [[self shareSummary] text];
    params.paramImages = [[self shareImageURL] text];
    params.paramUrl = [[self shareUrl] text];
	
	if(![[[sdkCall getinstance] oauth] addShareWithParams:params])
    {
        [self showInvalidTokenOrOpenIDMessage];
    }
}

- (void)addShareReponse:(NSNotification *)notify
{
    if (notify)
    {
        APIResponse *response = [[notify userInfo] objectForKey:kResponse];
        if (URLREQUEST_SUCCEED == response.retCode && kOpenSDKErrorSuccess == response.detailRetCode)
        {
            NSMutableString *str=[NSMutableString stringWithFormat:@""];
            for (id key in response.jsonResponse)
            {
                [str appendString: [NSString stringWithFormat:@"%@:%@\n",key,[response.jsonResponse objectForKey:key]]];
            }
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"操作成功" message:[NSString stringWithFormat:@"%@",str]
                                  
                                                           delegate:self cancelButtonTitle:@"我知道啦" otherButtonTitles: nil];
            [alert show];
        }
        else
        {
            NSString *errMsg = [NSString stringWithFormat:@"errorMsg:%@\n%@", response.errorMsg, [response.jsonResponse objectForKey:@"msg"]];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"操作失败" message:errMsg delegate:self cancelButtonTitle:@"我知道啦" otherButtonTitles: nil];
            [alert show];
        }
    }
}

- (void)viewDidUnload
{
    [self setShareTitle:nil];
    [self setShareUrl:nil];
    [self setShareSummary:nil];
    [self setShareComment:nil];
    [self setShareImageURL:nil];
    [self setShareTitle:nil];
    [self setShareSummary:nil];
    [self setShareUrl:nil];
    [self setShareSummary:nil];
    [self setShareComment:nil];
    [self setShareImageURL:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

#pragma mark -
#pragma mark 主要是只有URL输入那个框需要在点击后整体上移动
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    CGPoint point = CGPointMake(0, 0);
    CGFloat height = 0;
    if ([self shareSummary] == textView
        || [self shareComment] == textView
        || [self shareImageURL] == textView)
    {
        point = CGPointMake(0, 100);
        height += [[self shareImageURL] frame].origin.y + [[self shareImageURL] frame].size.height - [[self shareSummary] frame].origin.y - [[self shareSummary] frame].size.height;
        if([self shareComment] == textView)
        {
            point.y += [[self shareComment] frame].origin.y + [[self shareComment] frame].size.height - [[self shareSummary] frame].origin.y - [[self shareSummary] frame].size.height;
        }
        else if([self shareImageURL] == textView)
        {
            point.y += height;
        }
    }
    
    UIScrollView *scrollView = [self view];
    [scrollView setContentOffset:CGPointZero];
    [scrollView setContentOffset:point];
    CGSize size = [self scrollViewContentSize];
    size.height += height;
    [scrollView setContentSize:size];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{

}

- (void)showInvalidTokenOrOpenIDMessage
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"api调用失败" message:@"可能授权已过期，请重新获取" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}
@end
