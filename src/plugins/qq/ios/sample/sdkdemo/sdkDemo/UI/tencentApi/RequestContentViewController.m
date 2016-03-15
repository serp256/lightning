//
//  RequestContentViewController.m
//  tencentOAuthDemo
//
//  Created by xiaolongzhang on 13-6-14.
//
//

#import "RequestContentViewController.h"
#import <TencentOpenAPI/TencentMessageObject.h>
#import <TencentOpenAPI/TencentOAuth.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MediaPlayer.h>
#import <TencentOpenAPI/TencentApiInterface.h>

@interface RequestContentViewController ()

@end

@implementation RequestContentViewController
@synthesize req = _req;
@synthesize dataSource = _dataSource;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestthumbnailImageFinished:) name:MPMoviePlayerThumbnailImageRequestDidFinishNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *cancle = [[UIBarButtonItem alloc] initWithTitle:@"返回腾讯APP" style:UIBarButtonItemStylePlain target:self action:@selector(cancle)];
    [[self navigationItem] setRightBarButtonItem:cancle];
    [cancle release];
}


- (void)cancle
{
    TencentApiResp *resp = [TencentApiResp respFromReq:_req];
    NSUInteger ret = [TencentOAuth sendRespMessageToTencentApp:resp];
    if (0 == ret)
    {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] > 5.0)
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else
        {
            [self dismissModalViewControllerAnimated:YES];
        }
        
    }
    else
    {
        NSString *errMsg = nil;
        //pangzhang todo error
        switch (ret)
        {
            case kTencentApiPlatformUninstall:
                    errMsg = @"腾讯APP未安装";
                break;
            case kTencentApiPlatformNotSupport:
                    errMsg = @"腾讯APP不支持SDK";
                break;
            case kTencentApiParamsError:
                    errMsg = @"参数有误";
            default:
                    errMsg = @"未知错误";
                break;
        }
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"error" message:errMsg delegate:nil cancelButtonTitle:@"退出" otherButtonTitles:nil, nil ];
        [alertView show];
        [alertView release];
    }

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
    return [_dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    static NSString *CellIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellSelectionStyleNone reuseIdentifier:CellIdentifier] autorelease];
    }
    
    if (row < [_dataSource count])
    {
        NSString *title = nil;
        TencentBaseMessageObj *Obj = (TencentBaseMessageObj *)[_dataSource objectAtIndex:row];
        switch ([Obj nVersion])
        {
            case TencentTextObj:
                title = @"获取一段文字";
                break;
            case TencentImageObj:
                title = @"获取一张图片";
                break;
            case TencentAudioObj:
                title = @"获取一段音频";
                break;
            case TencentVideoObj:
                title = @"获取一段视频";
                break;
            case TencentImageAndVideoObj:
                title = @"获取照片或视频";
                break;
            default:
                break;
        }
        [[cell textLabel] setText:title];
        [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
        [[cell textLabel] setFont:[UIFont systemFontOfSize:20.0f]];
    }
    
    // Configure the cell...
    
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSUInteger row = [indexPath row];
    if (row <= [_dataSource count])
    {
        TencentBaseMessageObj *obj = (TencentBaseMessageObj *)[_dataSource objectAtIndex:row];
        switch ([obj nVersion])
        {
            case TencentTextObj:
            {
                YIPopupTextView* popTextView = [[YIPopupTextView alloc] initWithPlaceHolder:@"输入文本消息" maxCount:4096];
                [popTextView setTag:row];
                [popTextView setDelegate:self];
                [popTextView setText:@"芒果在这里写内容"];
                [popTextView showInView:[self view]];
            }
            break;
            case TencentImageObj:
            {
                [self popImagePickerController:row mediaType:(NSString *)kUTTypeImage];
            }
            break;
            case TencentAudioObj:
            {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"音频还未开放，尽情期待" delegate:nil cancelButtonTitle:@"cancel" otherButtonTitles:nil, nil];
                [alertView show];
                [alertView release];
            }
            break;
            case TencentVideoObj:
            {
                [self popImagePickerController:row mediaType:@"public.movie"];
            }
            break;
            case TencentImageAndVideoObj:
            {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"选择类型" message:@"请选择要上传的类型" delegate:self cancelButtonTitle:@"图片" otherButtonTitles:@"视频", nil];
                [alertView setTag:0xAA];
                [alertView show];
                CFRunLoopRun();
                
                NSUInteger index = [alertView tag];
                if (0 == index)
                {
                    [self popImagePickerController:row mediaType:(NSString *)kUTTypeImage];
                }
                else
                {
                    [self popImagePickerController:row mediaType:@"public.movie"];
                }
            }
            break;
            default:
                return;
            break;
        }
    }
}

- (void)popImagePickerController:(NSUInteger) row mediaType:(NSString *)mediaType
{
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        //ipc setMediaTypes:
        ipc.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
        ipc.mediaTypes = [NSArray arrayWithObjects:mediaType,nil];
    }
    ipc.delegate = self;
    ipc.view.tag = row;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] > 5.0)
    {
        [self presentViewController:ipc animated:YES completion:nil];
    }
    else
    {
        [self presentModalViewController:ipc animated:YES];
    }

}


- (void)setDataSource:(NSArray *)dataSource
{
    [_dataSource release];
    _dataSource = [dataSource retain];
    [[self tableView] reloadData];
}

#pragma mark imagePickerControllerDelegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    [picker dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSUInteger tag = picker.view.tag;
    
    if (tag < [_dataSource count])
    {
        NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
        
        if ([mediaType isEqualToString:(NSString *)kUTTypeImage])
        {
            UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
            
            TencentBaseMessageObj *obj = (TencentBaseMessageObj *)[_dataSource objectAtIndex:tag];
            NSData *data = UIImageJPEGRepresentation(image, 1.0f);
            if ([obj isMemberOfClass:[TencentImageMessageObjV1 class]])
            {
                [(TencentImageMessageObjV1 *)obj setDataImage:data];
            }
            else if([obj isMemberOfClass:[TencentImageAndVideoMessageObjV1 class]])
            {
                [(TencentImageAndVideoMessageObjV1 *)obj setDataImage:data];
            }
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"图片" message:@"图片获取成功" delegate:nil cancelButtonTitle:@"了解" otherButtonTitles:nil, nil];
            [alertView show];
            [alertView release];
        }
        
        else if([mediaType isEqualToString:@"public.movie"])
        {
            NSURL *videoURL = [info objectForKey:UIImagePickerControllerReferenceURL];
            //获取视频的预览图 这个方法太烂了 暂时先用这个方法
            MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:videoURL];
            CGFloat version = [[[UIDevice currentDevice] systemVersion] floatValue];
            UIImage *thumImage = nil;
            if (7.0f > version)
            {
                thumImage = [player thumbnailImageAtTime:1 timeOption:MPMovieTimeOptionNearestKeyFrame];
            }
            else
            {
                NSNumber *time1 = [NSNumber numberWithInt:2];
                [player requestThumbnailImagesAtTimes:@[time1] timeOption:MPMovieTimeOptionNearestKeyFrame];
            }

            NSData *dataThumbImage = nil;
            if (nil != thumImage)
            {
                dataThumbImage = UIImageJPEGRepresentation(thumImage, 0.5f);
            }

            if (tag < [_dataSource count])
            {
                TencentBaseMessageObj *obj = (TencentBaseMessageObj *)[_dataSource objectAtIndex:tag];
                if (TencentVideoObj == [obj nVersion])
                {
                    [(TencentVideoMessageV1 *)obj setSUrl:[videoURL absoluteString]];
                    [(TencentVideoMessageV1 *)obj setDataImagePreview:dataThumbImage];
                }
                else if(TencentImageAndVideoObj == [obj nVersion])
                {
                    [(TencentImageAndVideoMessageObjV1 *)obj setVideoUrl:[videoURL absoluteString]];
                }
            }
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"视频URL" message:[videoURL absoluteString] delegate:nil cancelButtonTitle:@"了解" otherButtonTitles:nil, nil];
            [alertView show];
            [alertView release];
        }
    }
    
    //pangzhang 先这样处理 选择之后我在4S的机器上发现点击不了退出
    if ([[[UIDevice currentDevice] systemVersion] floatValue] > 5.0)
    {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        [picker dismissModalViewControllerAnimated:YES];
    }
    
}

- (void)requestthumbnailImageFinished:(NSNotification *)notify
{
    NSLog(@"%@",notify);
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] > 5.0)
    {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        [picker dismissModalViewControllerAnimated:YES];
    }
}

#pragma mark YIPopupTextViewDelegate
- (void)popupTextView:(YIPopupTextView*)textView willDismissWithText:(NSString*)text
{
    //这里就不用了
    return;
}

- (void)popupTextView:(YIPopupTextView*)textView didDismissWithText:(NSString*)text
{
    NSUInteger row = [textView tag];
    if (row < [_dataSource count])
    {
        TencentTextMessageObjV1 *obj = (TencentTextMessageObjV1 *)[_dataSource objectAtIndex:row];
        [obj setSText:text];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"文字" message:text delegate:nil cancelButtonTitle:@"了解" otherButtonTitles:nil, nil];
        [alertView show];
        [alertView release];
    }
}

#pragma mark

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (0xAA == [alertView tag])
    {
        [alertView setTag:buttonIndex];
        CFRunLoopStop(CFRunLoopGetCurrent());
    }
}

- (void)dealloc
{
    [super dealloc];
    [_dataSource release];
    [_req release];
}

@end
