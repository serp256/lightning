//
//  sdkDemoViewController.m
//  sdkDemo
//
//  Created by xiaolongzhang on 13-3-29.
//  Copyright (c) 2013年 xiaolongzhang. All rights reserved.
//

#import "sdkDemoViewController.h"
#import "sdkCall.h"
#import "cellInfo.h"
#import "QZoneTableViewController.h"
#import "QQVipTableViewController.h"
#import "QQApiDemoController.h"
#import <time.h>
#import <TencentOpenAPI/TencentOAuth.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <CommonCrypto/CommonDigest.h>
#import <TencentOpenAPI/TencentApiInterface.h>
#import <TencentOpenAPI/TencentMessageObject.h>

#import "QuickDemoViewController.h"


@interface sdkDemoViewController ()
{
    FGalleryViewController  *_localGallery;
    NSInteger               _currentTableViewTag;
}

@property (nonatomic, retain)NSMutableArray *sectionName;
@property (nonatomic, retain)NSMutableArray *sectionRow;

@end

@implementation sdkDemoViewController

@synthesize sectionName = _sectionName;
@synthesize sectionRow = _sectionRow;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
    {
        // Custom initialization
        self.sectionName = [NSMutableArray arrayWithCapacity:1];
        self.sectionRow = [NSMutableArray arrayWithCapacity:1];
        [self loadData];
        _isLogined = NO;
        _currentTableViewTag = 0;
    }

    return self;
}

- (void)loadData
{
    NSMutableArray *cellLogin = [NSMutableArray arrayWithCapacity:1];
    [cellLogin addObject:[cellInfo info:@"第三方登录" target:self Sel:@selector(login) viewController:nil]];
    [[self sectionName] addObject:@"登录"];
    [[self sectionRow] addObject:cellLogin];
    
    NSMutableArray *cellApiInfo = [NSMutableArray arrayWithCapacity:4];
    
    [cellApiInfo addObject:[cellInfo info:@"QQ定向分享" target:nil Sel:@selector(pushSelectViewController:) viewController:nil userInfo:[NSNumber numberWithInteger:kApiQQ]]];
    [cellApiInfo addObject:[cellInfo info:@"QQ空间" target:self Sel:@selector(pushSelectViewController:) viewController:nil userInfo:[NSNumber numberWithInteger:kApiQZone]]];
    [cellApiInfo addObject:[cellInfo info:@"QQ会员" target:nil Sel:@selector(pushSelectViewController:) viewController:nil userInfo:[NSNumber numberWithInteger:kApiQQVip]]];
    
    [[self sectionName] addObject:@"api"];
    [[self sectionRow] addObject:cellApiInfo];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSuccessed) name:kLoginSuccessed object:[sdkCall getinstance]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFailed) name:kLoginFailed object:[sdkCall getinstance]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginCancelled) name:kLoginCancelled object:[sdkCall getinstance]];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)login
{
    NSArray* permissions = [NSArray arrayWithObjects:
                     kOPEN_PERMISSION_GET_USER_INFO,
                     kOPEN_PERMISSION_GET_SIMPLE_USER_INFO,
                     kOPEN_PERMISSION_ADD_ALBUM,
                     kOPEN_PERMISSION_ADD_ONE_BLOG,
                     kOPEN_PERMISSION_ADD_SHARE,
                     kOPEN_PERMISSION_ADD_TOPIC,
                     kOPEN_PERMISSION_CHECK_PAGE_FANS,
                     kOPEN_PERMISSION_GET_INFO,
                     kOPEN_PERMISSION_GET_OTHER_INFO,
                     kOPEN_PERMISSION_LIST_ALBUM,
                     kOPEN_PERMISSION_UPLOAD_PIC,
                     kOPEN_PERMISSION_GET_VIP_INFO,
                     kOPEN_PERMISSION_GET_VIP_RICH_INFO,
                     nil];
    
    [[[sdkCall getinstance] oauth] authorize:permissions inSafari:NO];
}

- (void)pushSelectViewController:(NSNumber *)apiType
{
    UIViewController *rootViewController = nil;
    switch ([apiType unsignedIntegerValue]) {
        case kApiQZone:
            rootViewController = [[QZoneTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
            break;
        case kApiQQVip:
            rootViewController = [[QQVipTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
            break;
        case kApiQQ:
            rootViewController = [[QQApiDemoController alloc] init];
            break;
        default:
            break;
    }
    [[self navigationController] pushViewController:rootViewController animated:YES];
    __RELEASE(rootViewController);
}


- (void)logout
{
    
}

- (void)showInvalidTokenOrOpenIDMessage
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"api调用失败" message:@"可能未授权登录或者授权已过期，请先重新登陆再获取" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

#pragma mark message
- (void)loginSuccessed
{
    if (NO == _isLogined)
    {
        _isLogined = YES;
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"结果" message:@"登录成功" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil];
    [alertView show];
    
    NSArray *arrayCell = [[self tableView] visibleCells];
    for (id cell in arrayCell)
    {
        [[cell textLabel] setEnabled:_isLogined];
    }
}

- (void)loginFailed
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"结果" message:@"登录失败" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil];
    [alertView show];
}

- (void) loginCancelled
{
    //do nothing
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [[self sectionName] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.

    return [[[self sectionRow] objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = [indexPath row];
    NSUInteger section = [indexPath section];
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellSelectionStyleNone reuseIdentifier:CellIdentifier];
    }
    
    NSString *title = nil;
    NSMutableArray *array = [[self sectionRow] objectAtIndex:section];
    if ([array isKindOfClass:[NSMutableArray class]])
    {
        title = [[array objectAtIndex:row] title];
    }
    
    if (nil == title)
    {
        title = @"未知";
    }
    
    [[cell textLabel] setText:title];
    [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
//    if (0 == indexPath.row
//        || 1 == indexPath.row)
//    {
//        [[cell textLabel] setEnabled:YES];
//    }
    
    // Configure the cell...
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[self sectionName] objectAtIndex:section];
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    
    NSArray *array = [[self sectionRow] objectAtIndex:section];
    if ([array isKindOfClass:[NSMutableArray class]])
    {
        cellInfo *info = (cellInfo *)[array objectAtIndex:row];
        if ([self respondsToSelector:[info sel]])
        {
            if (nil == [info userInfo])
            {
                [self performSelector:[info sel]];
            }
            else
            {
                [self performSelector:[info sel] withObject:[info userInfo]];
            }
        }
    }
    
    [[tableView cellForRowAtIndexPath:indexPath] setHighlighted:NO animated:NO];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    __SUPER_DEALLOC;
}

@end
