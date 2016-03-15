//
//  SendStoryViewController.m
//  tencentOAuthDemo
//
//  Created by xiaolongzhang on 12-11-28.
//
//

#import "SendStoryViewController.h"
#import "sdkCall.h"

#define K_KEYBOARD_HEIGHT 180.0f
#define K_SHARE_DETAIL_TITLE    @"太懒了"
#define K_SHARE_DETAIL_SUMMARY  @"实在是太懒了"
#define K_SHARE_DETAIL_FEEDS    @"开发都太懒了"
#define K_SHARE_DETAIL_IMAGEURL @"http://cc.cocimg.com/bbs/attachment/upload/96/92396.png"
#define K_SHARE_DETAIL_FRIENDNUMBER @"0"
#define K_SHARE_DETAIL_SHAREURL @"www.qq.com"

@interface SendStoryViewController () <UITextFieldDelegate>

@property (retain, nonatomic) IBOutlet UITextField *sharetitle;
@property (retain, nonatomic) IBOutlet UITextField *summary;
@property (retain, nonatomic) IBOutlet UITextField *feeds;
@property (retain, nonatomic) IBOutlet UITextField *imageurl;
@property (retain, nonatomic) IBOutlet UIControl *shareView;
@property (retain, nonatomic) IBOutlet UITextField *shareurl;

@end

@implementation SendStoryViewController
@synthesize sharetitle = _sharetitle;
@synthesize summary = _summary;
@synthesize feeds = _feeds;
@synthesize imageurl = _imageurl;
@synthesize shareurl = _shareurl;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendStoryResponse:) name:kSendStoryResponse object:[sdkCall getinstance]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
   [(UIControl *)self.shareView addTarget:self action:@selector(backgroundTap:) forControlEvents:UIControlEventTouchDown];
    
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification
                                              object:nil];
    
    rect = self.shareView.frame;
    self.sharetitle.delegate = self;
    self.summary.delegate = self;
    self.feeds.delegate = self;
    self.imageurl.delegate = self;
    self.shareurl.delegate = self;
    
    self.sharetitle.text = K_SHARE_DETAIL_TITLE;
    self.summary.text = K_SHARE_DETAIL_SUMMARY;
    self.feeds.text = K_SHARE_DETAIL_FEEDS;
    self.imageurl.text = K_SHARE_DETAIL_IMAGEURL;
    self.shareurl.text = K_SHARE_DETAIL_SHAREURL;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)OnClickShare
{
    NSString *imageurl = self.imageurl.text;
    NSString *shareText = self.summary.text;
    NSString *feeds = self.feeds.text;
    NSString *shareTitle = self.sharetitle.text;
    NSString *source = @"4";
    NSString *act = @"进入应用";
    NSString *url = @"www.qq.com";
    NSString *shareurl = self.shareurl.text;
    
    if (nil == shareTitle
        || 0 == [shareTitle length])
    {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"分享失败" message:[NSString stringWithFormat:@"标题不能为空"]
													   delegate:self cancelButtonTitle:@"我知道啦" otherButtonTitles: nil];
        [alert show];
    }
    else
    {
        NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                              shareText, @"description",
                              feeds, @"summary",
                              imageurl, @"pics",
                              shareTitle, @"title",
                              source, @"source",
                              act, @"act",
                              url, @"url",
                              shareurl, @"shareurl",
                              nil];
        
        if (NO == [[[sdkCall getinstance] oauth] sendStory:data friendList:nil])
        {
            [self showInvalidTokenOrOpenIDMessage];
        }
    }
}

- (void)sendStoryResponse:(NSNotification *)notify
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

- (void)showInvalidTokenOrOpenIDMessage{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"api调用失败" message:@"参数有误或者token失效，请检查参数或者重新登录" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

- (IBAction)OnClickCancle
{
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)doClose
{
    [self dismissModalViewControllerAnimated:YES];
}
#pragma mark -
#pragma mark 解决虚拟键盘挡住UITextField的方法

- (void)keyboardWillShow:(NSNotification *)noti
{
    //键盘输入的界面调整
    //键盘的高度
}

#pragma mark
#pragma mark 相应键盘点击了return按键的回掉

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.imageurl
        || textField == self.shareurl)
    {
        NSTimeInterval animationDuration = 0.30f;
        [UIView beginAnimations:@"ResizeForKeyBoard" context:nil];
        [UIView setAnimationDuration:animationDuration];
        self.view.frame = rect;
        [UIView commitAnimations];

        return YES;
    }
    
    [textField resignFirstResponder];
    return YES;
}

#pragma mark -
#pragma mark 主要是只有URL输入那个框需要在点击后整体上移动
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField == self.imageurl
        || textField == self.shareurl)
    {
        
        CGRect currentFrame = [self.shareView frame];
        if (currentFrame.origin.x == rect.origin.x
            && currentFrame.origin.y == rect.origin.y
            && currentFrame.size.width == rect.size.width
            && currentFrame.size.height == rect.size.height)
        {
            rect = self.shareView.frame;
            CGRect frame = CGRectMake(rect.origin.x, rect.origin.y - K_KEYBOARD_HEIGHT, rect.size.width, rect.size.height + K_KEYBOARD_HEIGHT);
            
            NSTimeInterval animationDuration = 0.30f;
            [UIView beginAnimations:@"ResizeForKeyBoard" context:nil];
            [UIView setAnimationDuration:animationDuration];
            [self.shareView setFrame:frame];
            [UIView commitAnimations];
        }
    }
}


#pragma mark
#pragma mark 触摸背景来关闭虚拟键盘
- (IBAction)backgroundTap:(id)sender
{
    NSTimeInterval animationDuration = 0.30f;
    [UIView setAnimationDuration:animationDuration];
    self.shareView.frame = rect;
    [self.shareView setFrame:rect];
    [UIView commitAnimations];
    
    [self.sharetitle resignFirstResponder];
    [self.feeds resignFirstResponder];
    [self.imageurl resignFirstResponder];
    [self.summary resignFirstResponder];
    [self.shareurl resignFirstResponder];
}


- (void)dealloc
{
    [self setTitle:nil];
    [self setSummary:nil];
    [self setFeeds:nil];
    [self setImageurl:nil];
    [self setShareView:nil];
    [self setShareView:nil];
    [self setShareurl:nil];
}

- (void)viewDidUnload {
    [self setTitle:nil];
    [self setSummary:nil];
    [self setFeeds:nil];
    [self setImageurl:nil];
    [self setShareView:nil];
    [self setShareView:nil];
    [self setShareurl:nil];
    [super viewDidUnload];
}
@end
