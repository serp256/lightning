//
//  addAlbumViewController.m
//  sdkDemo
//
//  Created by xiaolongzhang on 13-5-3.
//  Copyright (c) 2013年 xiaolongzhang. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "addAlbumViewController.h"
#import "sdkDemoAppDelegate.h"
//#import "sdkDemoViewController.h"
#import "sdkCall.h"

#define kDropDownMiniHeight 200
#define kDropDownCellHeight 35.0f


@implementation DropDown
@synthesize tv = _tv;
@synthesize tableArray = _tableArray;
@synthesize textField = _textField;
@synthesize delegate = _delegate;
@synthesize selectIndex = _selectIndex;

- (void)dealloc
{
    [self setTv:nil];
    [self setTextField:nil];
    [self setTableArray:nil];
}

- (id)initWithFrame:(CGRect)frame
{
    if (kDropDownMiniHeight > frame.size.height)
    {
        _frameHeight = kDropDownMiniHeight;
    }
    else
    {
        _frameHeight = frame.size.height;
    }
    
    _tableHeight = _frameHeight - 30;
    frame.size.height = 30.0f;
    if(self = [super initWithFrame:frame])
    {
        _showList = NO;
        _tv = [[UITableView alloc] initWithFrame:CGRectMake(0.0f, 30.0f, frame.size.width, 0)];
        [_tv setDelegate:self];
        [_tv setDataSource:self];
        [_tv setBackgroundColor:[UIColor whiteColor]];
        [_tv setSeparatorColor:[UIColor clearColor]];
        [[_tv layer] setBorderWidth:1.0f];
        [[_tv layer] setBorderColor:[[UIColor colorWithRed:(CGFloat)0x33/(CGFloat)0xff green:(CGFloat)0x33/(CGFloat)0xff blue:(CGFloat)0x33/(CGFloat)0xff alpha:1] CGColor]];
        [_tv setHidden:YES];
        [self addSubview:_tv];
        
        _textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 30)];
        [_textField setBorderStyle:UITextBorderStyleLine];
        [_textField addTarget:self action:@selector(dropdown) forControlEvents:UIControlEventAllTouchEvents];
        [_textField setTextColor:[UIColor grayColor]];
        [_textField setDelegate:self];
        [self addSubview:_textField];
    }
    return self;
}

- (void)dropdown
{
    [_textField resignFirstResponder];
    if (_showList)
    {
        //如果下拉框已显示，则进行显示
        return;
    }
    else
    {
        //如果下拉框尚未显示，则进行显示
        CGRect sf = self.frame;
        sf.size.height = _frameHeight;
        
        //把dropdownList放到前面,防止下拉框被别的控件遮住
        [[self superview] bringSubviewToFront:self];
        [_tv setHidden:NO];
        _showList = YES; //显示下拉框
        
        CGRect frame = [_tv frame];
        frame.size.height = 0;
        [_tv setFrame:frame];
        frame.size.height = _tableHeight;
        [UIView beginAnimations:@"dropDownAnimation" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        [self setFrame:sf];
        [_tv setFrame:frame];
        [UIView commitAnimations];
    }
}

- (void)packup
{
    if (_showList)
    {
        _showList = NO;
        CGRect sf = [self frame];
        sf.size.height = 30;
        [UIView beginAnimations:@"packUpAnimation" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        [UIView setAnimationDidStopSelector:@selector(packUpStop)];
        [self setFrame:sf];
        CGRect frame = [_tv frame];
        frame.size.height = 0;
        [_tv setFrame:frame];
        [UIView commitAnimations];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_tableArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (nil == cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if ([indexPath row] < [_tableArray count])
    {
        [[cell textLabel] setText:[_tableArray objectAtIndex:[indexPath row]]];
        [[cell textLabel] setFont:[UIFont systemFontOfSize:16.0f]];
        [cell setAccessoryType:UITableViewCellAccessoryNone];
        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kDropDownCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath row] < [_tableArray count])
    {
        [_textField setText:[_tableArray objectAtIndex:[indexPath row]]];
        _showList = NO;
        [_tv setHidden:YES];
        
        CGRect sf = [self frame];
        sf.size.height = 30;
        [self setFrame:sf];
        CGRect frame = [_tv frame];
        frame.size.height = 0;
        [_tv setFrame:frame];
        
        [self setSelectIndex:[indexPath row]];
        if ([_delegate respondsToSelector:@selector(DropDown:selectIndex:)])
        {
            [_delegate DropDown:self selectIndex:[indexPath row]];
        }
    }
}

#pragma mark UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self dropdown];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    
}

#pragma mark animationDelegate
- (void)packUpStop
{
    [_tv setHidden:YES];
}

@end


#define kKeyBoardHeight 180.0f
#define kIntervalY 9.0f

#define kAlbumTitleLabelWidth 86
#define kAlbumTitleLabelHeight 21

#define kAlbumTitleTextFieldWidth 280
#define kAlbumTitleTextFieldHeight 30

#define kAlbumDescLabelWidth 86
#define kAlbumDescLabelHeight 21

#define kAlbumDescTextViewWidth 280
#define kAlbumDescTextViewHeight 141

#define kAlbumPrivLabelWidth 86
#define kAlbumPrivLabelHeight 21

#define kAlbumPrivWidth 280
#define kAlbumPrivHeight 30


#define kAlbumQuestionLabelWidth 86
#define kAlbumQuestionLabelHeight 21

#define kAlbumQuestionWidth 280
#define kAlbumQuestionHeight 30


#define kAlbumAnswerLabelWidth 86
#define kAlbumAnswerLabelHeight 21

#define kAlbumAnswerWidth 280
#define kAlbumAnswerHeight 30

@interface addAlbumViewController ()

@end

@implementation addAlbumViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:[[self view] bounds]];
    CGSize size = [scrollView frame].size;
    size.height += 100;
    [scrollView setContentSize:size];
    [scrollView setBackgroundColor:[UIColor whiteColor]];
    [[self view] addSubview:scrollView];
    
    UIControl *backView = [[UIControl alloc] initWithFrame:[[self view] bounds]];
    [scrollView addSubview:backView];
    [backView addTarget:self action:@selector(backgroundTap:) forControlEvents:UIControlEventTouchDown];
    
    CGRect frame = CGRectMake(20, 20, kAlbumTitleLabelWidth, kAlbumTitleLabelHeight);
    UILabel *title = [[UILabel alloc] initWithFrame:frame];
    [title setFont:[UIFont systemFontOfSize:16.0f]];
    [title setText:@"相册名称:"];
    [scrollView addSubview:title];
    
    frame.origin.y = frame.size.height + frame.origin.y + 9;
    frame.size.width = kAlbumTitleTextFieldWidth;
    frame.size.height = kAlbumTitleTextFieldHeight;
    _albumTitle = [[UITextView alloc] initWithFrame:frame];
    [_albumTitle setText:@"QQConnectSDK"];
    [_albumTitle setFont:[UIFont systemFontOfSize:16.0f]];
    [[_albumTitle layer] setBorderColor:[[UIColor colorWithRed:(CGFloat)0x33/(CGFloat)0xff green:(CGFloat)0x33/(CGFloat)0xff blue:(CGFloat)0x33/(CGFloat)0xff alpha:1.0f] CGColor]];
    [[_albumTitle layer] setBorderWidth:1.0f];
    [_albumTitle setDelegate:self];
    [scrollView addSubview:_albumTitle];
    
    
    frame.origin.y = frame.size.height + frame.origin.y + 9;
    frame.size.width = kAlbumDescLabelWidth;
    frame.size.height = kAlbumDescLabelHeight;
    UILabel *desc = [[UILabel alloc] initWithFrame:frame];
    [desc setFont:[UIFont systemFontOfSize:16.0f]];
    [desc setText:@"相册描述:"];
    [scrollView addSubview:desc];
    
    
    frame.origin.y = frame.size.height + frame.origin.y + 9;
    frame.size.width = kAlbumDescTextViewWidth;
    frame.size.height = kAlbumDescTextViewHeight;
    _albumDesc = [[UITextView alloc] initWithFrame:frame];
    [_albumDesc setFont:[UIFont systemFontOfSize:16.0f]];
    [_albumDesc setText:@"仅仅是用来测试QQConnectSDK"];
    [[_albumDesc layer] setBorderColor:[[UIColor colorWithRed:(CGFloat)0x33/(CGFloat)0xff green:(CGFloat)0x33/(CGFloat)0xff blue:(CGFloat)0x33/(CGFloat)0xff alpha:1.0f] CGColor]];
    //[[_albumDesc layer] setBorderColor:[[UIColor blackColor] CGColor]];
    [[_albumDesc layer] setBorderWidth:1.0f];
    [_albumDesc setDelegate:self];
    [scrollView addSubview:_albumDesc];
    
    
    frame.origin.y = frame.size.height + frame.origin.y + 9;
    frame.size.width = kAlbumPrivLabelWidth;
    frame.size.height = kAlbumPrivLabelHeight;
    UILabel *priv = [[UILabel alloc] initWithFrame:frame];
    [priv setFont:[UIFont systemFontOfSize:16.0f]];
    [priv setText:@"相册权限:"];
    [scrollView addSubview:priv];
    
    frame.origin.y = frame.size.height + frame.origin.y + 9;
    frame.size.width = kAlbumPrivWidth;
    frame.size.height = kAlbumPrivHeight;
    _albumPriv = [[DropDown alloc] initWithFrame:frame];
    [[_albumPriv textField] setPlaceholder:@"所有人可见"];
    NSArray *privArray = [[NSArray alloc] initWithObjects:@"所有人可见", @"全部QQ好友可见", @"仅主人可见", @"回答问题的人可见", nil];
    [_albumPriv setTableArray:privArray];
    [_albumPriv setDelegate:self];
    [[self view] setBackgroundColor:[UIColor whiteColor]];
    [scrollView addSubview:_albumPriv];
    
    frame.origin.y = frame.size.height + frame.origin.y + 9;
    frame.size.width = kAlbumQuestionLabelWidth;
    frame.size.height = kAlbumQuestionLabelHeight;
    UILabel *question = [[UILabel alloc] initWithFrame:frame];
    [question setFont:[UIFont systemFontOfSize:16.0f]];
    [question setText:@"question:"];
    [scrollView addSubview:question];
    
    frame.origin.y = frame.size.height + frame.origin.y + 9;
    frame.size.width = kAlbumQuestionWidth;
    frame.size.height = kAlbumQuestionHeight;
    _albumQuestion= [[UITextView alloc] initWithFrame:frame];
    [_albumQuestion setFont:[UIFont systemFontOfSize:16.0f]];
    [_albumQuestion setText:@"这是干嘛用的相册?空空，岛岛？"];
    [[_albumQuestion layer] setBorderColor:[[UIColor colorWithRed:(CGFloat)0x33/(CGFloat)0xff green:(CGFloat)0x33/(CGFloat)0xff blue:(CGFloat)0x33/(CGFloat)0xff alpha:1.0f] CGColor]];
    [[_albumQuestion layer] setBorderWidth:1.0f];
    [_albumQuestion setDelegate:self];
    [_albumQuestion setEditable:NO];
    [_albumQuestion setTextColor:[UIColor grayColor]];
    [scrollView addSubview:_albumQuestion];
    
    frame.origin.y = frame.size.height + frame.origin.y + 9;
    frame.size.width = kAlbumAnswerLabelWidth;
    frame.size.height = kAlbumAnswerLabelHeight;
    UILabel *answer = [[UILabel alloc] initWithFrame:frame];
    [answer setFont:[UIFont systemFontOfSize:16.0f]];
    [answer setText:@"answer:"];
    [scrollView addSubview:answer];
    
    frame.origin.y = frame.size.height + frame.origin.y + 9;
    frame.size.width = kAlbumAnswerWidth;
    frame.size.height = kAlbumAnswerHeight;
    _albumAnswer = [[UITextView alloc] initWithFrame:frame];
    [_albumAnswer setFont:[UIFont systemFontOfSize:16.0f]];
    [_albumAnswer setText:@"想多了，只是QQ互联SDK的测试相册。"];
    [[_albumAnswer layer] setBorderColor:[[UIColor colorWithRed:(CGFloat)0x33/(CGFloat)0xff green:(CGFloat)0x33/(CGFloat)0xff blue:(CGFloat)0x33/(CGFloat)0xff alpha:1.0f] CGColor]];
    [[_albumAnswer layer] setBorderWidth:1.0f];
    [_albumAnswer setDelegate:self];
    [_albumAnswer setEditable:NO];
    [_albumAnswer setTextColor:[UIColor grayColor]];
    [scrollView addSubview:_albumAnswer];
    
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(close)];
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(addAlbum)];
    [[self navigationItem] setRightBarButtonItem:leftItem];
    [[self navigationItem] setLeftBarButtonItem:rightItem];
    [self setTitle:@"add_ablum"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addAlbumResponse:) name:kAddAlbumResponse object:[sdkCall getinstance]];
}

- (void)addAlbumResponse:(NSNotification *)notify
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
            
            sdkDemoAppDelegate *delegate = (sdkDemoAppDelegate *)[[UIApplication sharedApplication] delegate];
            [[delegate viewController] setAlbumId:[[response jsonResponse] objectForKey:@"albumid"]];
        }
        else
        {
            NSString *errMsg = [NSString stringWithFormat:@"errorMsg:%@\n%@", response.errorMsg, [response.jsonResponse objectForKey:@"msg"]];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"操作失败" message:errMsg delegate:self cancelButtonTitle:@"我知道啦" otherButtonTitles: nil];
            [alert show];
        }
    }
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

- (void)addAlbum
{
    TCAddAlbumDic *dic = [TCAddAlbumDic dictionary];
    dic.paramAlbumname = [_albumTitle text];
    dic.paramAlbumdesc = [_albumDesc text];
    NSInteger index = [_albumPriv selectIndex] + 1;
    if (index > 1)
    {
        //主要是参数是1，3，4，5有点蛋疼，缺少个2
        index += 1;
    }
    dic.paramPriv = [NSString stringWithFormat:@"%d", index];
    if (5 == index)
    {
        dic.paramQuestion = [_albumQuestion text];
        dic.paramAnswer = [_albumAnswer text];
    }
    
    if (NO == [[[sdkCall getinstance] oauth] addAlbumWithParams:dic])
    {
        [sdkCall showInvalidTokenOrOpenIDMessage];
    }

    [_albumTitle text];
}

- (IBAction)backgroundTap:(id)sender
{
    [_albumDesc resignFirstResponder];
    [_albumTitle resignFirstResponder];
    [_albumQuestion resignFirstResponder];
    [_albumAnswer resignFirstResponder];
    [_albumPriv packup];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_albumDesc setDelegate:nil];
    _albumDesc = nil;
    [_albumTitle setDelegate:nil];
    _albumTitle = nil;
    [_albumQuestion setDelegate:nil];
    _albumQuestion = nil;
    [_albumAnswer setDelegate:nil];
    _albumAnswer = nil;
    [_albumPriv setDelegate:nil];
    _albumPriv = nil;
}

#pragma mark UITextViewDelegate
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if(textView == _albumDesc)
    {
        
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if(textView == _albumDesc)
    {
        
    }
}

#pragma mark DropDownDelegate
- (void)DropDown:(DropDown *)dropDown selectIndex:(NSInteger)index
{
    if(3 == index)
    {
        [_albumAnswer setTextColor:[UIColor blackColor]];
        [_albumAnswer setEditable:YES];
        
        [_albumQuestion setTextColor:[UIColor blackColor]];
        [_albumQuestion setEditable:YES];
    }
    else
    {
        [_albumAnswer setTextColor:[UIColor grayColor]];
        [_albumAnswer setEditable:NO];
        
        [_albumQuestion setTextColor:[UIColor grayColor]];
        [_albumQuestion setEditable:NO];
    }
}

@end
