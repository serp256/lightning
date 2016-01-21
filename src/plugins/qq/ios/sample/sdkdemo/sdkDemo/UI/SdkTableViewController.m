//
//  SdkTableViewController.m
//  sdkDemo
//
//  Created by xiaolongzhang on 13-7-8.
//  Copyright (c) 2013年 xiaolongzhang. All rights reserved.
//

#import "SdkTableViewController.h"
#import "cellInfo.h"

@interface SdkTableViewController ()

@end

@implementation SdkTableViewController

@synthesize sectionName = _sectionName;
@synthesize sectionRow  = _sectionRow;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
    {
        // Custom initialization
        self.sectionName = [NSMutableArray arrayWithCapacity:1];
        self.sectionRow = [NSMutableArray arrayWithCapacity:1];
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
    return [[self sectionRow] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[[self sectionRow] objectAtIndex:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[self sectionName] objectAtIndex:section];
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
    if ([array isKindOfClass:[NSArray class]])
    {
        title = [[array objectAtIndex:row] title];
    }
    
    if (nil == title)
    {
        title = @"未知cell";
    }
    
    [[cell textLabel] setText:title];
    [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    
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
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"QQSDK.123456:\\"]];
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    
    NSArray *array = [[self sectionRow] objectAtIndex:section];
    if ([array isKindOfClass:[NSArray class]])
    {
        cellInfo *cell = [array objectAtIndex:row];
        if ([cell isKindOfClass:[cellInfo class]])
        {
            id target = [cell target];
            SEL sel = [cell sel];
            id userInfo = [cell userInfo];
            if ([target respondsToSelector:sel])
            {
                [target performSelector:sel withObject:userInfo];
            }
        }
    }
}

@end
