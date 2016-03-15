//
//  userInfoViewController.m
//  sdkDemo
//
//  Created by xiaolongzhang on 13-4-3.
//  Copyright (c) 2013年 xiaolongzhang. All rights reserved.
//

#import "userInfoViewController.h"

#define kNickPosX 10
#define kNickPosY 10
#define kNickHeight 20

#define kVipInfoX    kNickPosX
#define kVipInfoY   kNickPosY + kNickHeight + 10
#define kVipInfoHeight 60

@interface userInfoViewController ()

@end

@implementation userInfoViewController

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
    CGRect rect = [[UIScreen mainScreen] bounds];
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:rect];
    [self setView:scrollView];
    
    UILabel *nick = [[UILabel alloc] initWithFrame:CGRectMake(kNickPosX, kNickPosY, rect.size.width, kNickHeight)];
    [nick setText:[NSString stringWithFormat:@"nick:%@", [self nick]]];
    [nick setFont:[UIFont systemFontOfSize:16]];
    [nick setTextColor:[UIColor blackColor]];
    [[self view] addSubview:nick];
    
    UILabel *vip = [[UILabel alloc] initWithFrame:CGRectMake(kVipInfoX, kVipInfoY, rect.size.width, kVipInfoHeight)];
    [vip setNumberOfLines:0];
    [vip setText:[NSString stringWithFormat:@"yellow_vip:%u\nyellow_vip_level:%u\nyellow_year_vip:%u", [self isYellowVip],[self yellowVipLevel],[self isYellowYearVip]]];
    [vip setFont:[UIFont systemFontOfSize:16]];
    [vip setTextColor:[UIColor blackColor]];
    [[self view] addSubview:vip];
    
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[self qqLog1]]]];
    UIImageView *imageViewQQ = [[UIImageView alloc] initWithImage:image];
    CGRect imageRect = CGRectMake(kNickPosX, kVipInfoY + kVipInfoHeight + 10, [image size].width / 2, [image size].height / 2);
    [imageViewQQ setFrame:imageRect];
    [[self view] addSubview:imageViewQQ];
    
    imageRect.origin.y += ([image size].height + 10);
    image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[self qqLog2]]]];
    imageRect.size = CGSizeMake([image size].width / 2, [image size].height / 2);
    UIImageView *imageViewQQ1 = [[UIImageView alloc] initWithImage:image];
    [imageViewQQ1 setFrame:imageRect];
    [[self view] addSubview:imageViewQQ1];
    
    imageRect.origin.y += ([image size].height + 10);
    image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[self qzoneLog1]]]];
    UIImageView *imageViewQZone1 = [[UIImageView alloc] initWithImage:image];
    imageRect.size = CGSizeMake([image size].width / 2, [image size].height / 2);
    [imageViewQZone1 setFrame:imageRect];
    [[self view] addSubview:imageViewQZone1];
    
    imageRect.origin.y += ([image size].height + 10);
    image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[self qzoneLog2]]]];
    UIImageView *imageViewQZone2 = [[UIImageView alloc] initWithImage:image];
    imageRect.size = CGSizeMake([image size].width / 2, [image size].height / 2);
    [imageViewQZone2 setFrame:imageRect];
    [[self view] addSubview:imageViewQZone2];
    NSUInteger height = imageRect.origin.y + [image size].height + 40;
    [scrollView setContentSize:CGSizeMake(rect.size.width, height)];
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(close)];
    [[self navigationItem] setRightBarButtonItem:leftItem];
    
    [[self view] setBackgroundColor:[UIColor whiteColor]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)close
{
    //5.0+
    [self dismissModalViewControllerAnimated:YES];
}

- (void)dealloc
{
    [self setNick:nil];
    [self setYellowVipLevel:nil];
    [self setIsYellowVip:nil];
    [self setIsYellowYearVip:nil];
    [self setQqLog1:nil];
    [self setQqLog2:nil];
    [self setQzoneLog1:nil];
    [self setQzoneLog2:nil];
}
@end
