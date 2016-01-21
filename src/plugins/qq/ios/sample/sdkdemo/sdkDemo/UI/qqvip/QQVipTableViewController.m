//
//  QQVipTableViewController.m
//  sdkDemo
//
//  Created by xiaolongzhang on 13-7-8.
//  Copyright (c) 2013年 xiaolongzhang. All rights reserved.
//

#import "QQVipTableViewController.h"
#import "cellInfo.h"
#import "sdkCall.h"

@interface QQVipTableViewController ()

@end

@implementation QQVipTableViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
    {
        NSMutableArray *cellvip = [NSMutableArray array];
        [cellvip addObject:[cellInfo info:@"基本会员信息" target:self Sel:@selector(getVipInfo) viewController:nil]];
        [cellvip addObject:[cellInfo info:@"详细会员信息" target:self Sel:@selector(getVipRichInfo) viewController:nil]];
        [[self sectionName] addObject:@"会员"];
        [[self sectionRow] addObject:cellvip];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(analysisResponse:) name:kGetVipInfoResponse object:[sdkCall getinstance]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(analysisResponse:) name:kGetVipRichInfoResponse object:[sdkCall getinstance]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)getVipInfo
{
    if(NO == [[[sdkCall getinstance] oauth] getVipInfo])
    {
        [sdkCall showInvalidTokenOrOpenIDMessage];
    }
}


- (void)getVipRichInfo
{
    if (NO == [[[sdkCall getinstance] oauth] getVipRichInfo])
    {
        [sdkCall showInvalidTokenOrOpenIDMessage];
    }
}

- (void)analysisResponse:(NSNotification *)notify
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

@end
