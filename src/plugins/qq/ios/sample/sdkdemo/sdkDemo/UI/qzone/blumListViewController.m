//
//  photoListViewController.m
//  sdkDemo
//
//  Created by xiaolongzhang on 13-4-11.
//  Copyright (c) 2013年 xiaolongzhang. All rights reserved.
//

#import "blumListViewController.h"
#import "photoListViewController.h"
#import "sdkCall.h"

@interface blumListViewController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate>
@property (nonatomic, retain) NSMutableArray *photoArray;
@end

@implementation blumListViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [[self navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(doClose)]];
    
    NSThread *getPhotoThread = [[NSThread alloc] initWithTarget:self selector:@selector(getPhoto) object:nil];
    [getPhotoThread start];
}

- (void)getPhoto
{
    [self setPhotoArray:[NSMutableArray array]];
    for (id dicInfo in [self blumList])
    {
        NSString *albumUrl = [dicInfo objectForKey:@"coverurl"];
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:albumUrl]]];
        [[self photoArray] addObject:image];
    }
}

- (void)doClose
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[self blumList] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    // Configure the cell...
    if (nil == cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    NSDictionary *photoInfo = [[self blumList] objectAtIndex:indexPath.row];
    NSString *albumid = [photoInfo objectForKey:@"name"];
    if ([[self photoArray] count] > indexPath.row)
    {
        UIImage *image = [[self photoArray] objectAtIndex:indexPath.row];
        [[cell imageView] setImage:image];
    }

    [[cell textLabel] setText:albumid];
    return cell;
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
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    
    if (indexPath.row >= [[self blumList] count])
    {
        return;
    }
    
    photoListViewController *viewController = [[photoListViewController alloc] initWithNibName:nil bundle:nil];
    [viewController setAlbumId:[[[self blumList] objectAtIndex:indexPath.row] objectForKey:@"albumid"]];
    [[self navigationController] pushViewController:viewController animated:YES];
}

- (void)getListPhotoResponse:(NSNotification *)notify
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (notify)
    {
        APIResponse *response = [[notify userInfo] objectForKey:kResponse];
        NSLog(@"%@", [response jsonResponse]);
        if (URLREQUEST_SUCCEED == response.retCode && kOpenSDKErrorSuccess == response.detailRetCode)
        {
            id photoArray = [[response jsonResponse] objectForKey:@"photos"];
            if ([photoArray isKindOfClass:[NSArray class]])
            {
                photoListViewController *viewController = [[photoListViewController alloc] initWithNibName:nil bundle:nil];
                [viewController setPhotoInfoArray:photoArray];
                [[self navigationController] pushViewController:viewController animated:YES];
            }
            else
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"操作失败" message:@"这个相册好像没有照片哦!赶紧去上传几张吧。" delegate:self cancelButtonTitle:@"好的，这就去" otherButtonTitles: @"算啦，闲的蛋疼", nil];
                [alert show];
            }
        }
        else
        {
            NSString *errMsg = [NSString stringWithFormat:@"errorMsg:%@\n%@", response.errorMsg, [response.jsonResponse objectForKey:@"msg"]];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"操作失败" message:errMsg delegate:self cancelButtonTitle:@"我知道啦" otherButtonTitles: nil];
            [alert show];
        }
    }
}

- (void)showInvalidTokenOrOpenIDMessage
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"api调用失败" message:@"可能授权已过期，请重新获取" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (0 == buttonIndex)
    {
        UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]){
            ipc.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
            ipc.mediaTypes =[UIImagePickerController availableMediaTypesForSourceType:ipc.sourceType];
        }
        
        ipc.delegate = self;
        [self presentModalViewController:ipc animated:YES];
    }
}

@end
