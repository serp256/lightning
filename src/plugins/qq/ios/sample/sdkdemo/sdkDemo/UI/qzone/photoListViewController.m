//
//  RootViewController.m
//  TimerScroller
//
//  Created by Andrew Carter on 12/4/11.

#import "photoListViewController.h"
#import "sdkCall.h"
#define isRetina ([UIScreen instancesRespondToSelector:@selector(scale)] ? (2 == [[UIScreen mainScreen] scale]) : NO)
#define currentDeviceSystemVersion [[[UIDevice currentDevice] systemVersion] floatValue]
@interface photoListViewController ()
@property (nonatomic, retain) NSMutableArray *photoArray;
@end
@implementation photoListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
        if (currentDeviceSystemVersion > 5.0f)
        {
            _timeScroller = [[TimeScroller alloc] initWithDelegate:self];
        }
        else
        {
            _timeScroller = nil;
        }

        
        //This is just junk data to be displayed.
        
        _isLoading = NO;
        _isScrolling = YES;
    }

    return self;
}

- (void)dealloc
{
}

- (void)viewDidLoad
{
    CGRect rect = [[UIScreen mainScreen] bounds];
    UIView *view = [[UIView alloc] initWithFrame:rect];
    [view setBackgroundColor:[UIColor whiteColor]];
    self.view = view;
    
    rect = [view bounds];
    rect.origin.x += rect.size.width / 2 - 50;
    rect.origin.y += rect.size.height / 2 - 50;
    rect.size.width = 100;
    rect.size.height = 100;
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:rect];
    [[self view] addSubview:_activityIndicatorView];
    [_activityIndicatorView startAnimating];
    TCListPhotoDic *params = [TCListPhotoDic dictionary];
    params.paramAlbumid = [self albumId];
	if(![[[sdkCall getinstance] oauth] getListPhotoWithParams:params])
    {
        [sdkCall showInvalidTokenOrOpenIDMessage];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getListPhotoResponse:) name:kGetListPhotoResponse object:[sdkCall getinstance]];
    [_activityIndicatorView startAnimating];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"上传图片" style:UIBarButtonItemStylePlain target:self action:@selector(uploadPic)];
    [[self navigationItem] setRightBarButtonItem:rightItem];
    [self setTitle:@"photolist"];
}

- (void)getListPhotoResponse:(NSNotification *)notify
{
    [_activityIndicatorView stopAnimating];
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
                [self setPhotoInfoArray:photoArray];
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

- (void)reloadData
{
    if (nil == _tableView)
    {
        CGRect rect = [[self view] bounds];
        _tableView = [[UITableView alloc] initWithFrame:rect style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [[self view] addSubview:_tableView];
        
        NSThread *getPhotoThread = [[NSThread alloc] initWithTarget:self selector:@selector(getPhotoWithUrl:) object:nil];
        [getPhotoThread start];
    }

}

- (void)setPhotoInfoArray:(NSMutableArray *)photoInfoArray
{
    _photoInfoArray = photoInfoArray;
    [self reloadData];
}

- (void)uploadPic
{
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]){
        ipc.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
        ipc.mediaTypes =[UIImagePickerController availableMediaTypesForSourceType:ipc.sourceType];
    }
    ipc.delegate = self;
    [self presentModalViewController:ipc animated:YES];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    TCUploadPicDic *params = [TCUploadPicDic dictionary];
    params.paramPicture = image;
    params.paramTitle = @"testDemo";
    params.paramPicnum = @"1";
    params.paramPhotodesc = @"仅仅是用来进行QQ互联的demo测试的";
    params.paramMobile = @"1";
    params.paramNeedfeed = @"1";
    params.paramX = @"39.909407";
    params.paramY = @"116.397521";
    params.paramAlbumid = [self albumId];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadPicResponse:) name:kUploadPicResponse object:[sdkCall getinstance]];
    if(NO == [[[sdkCall getinstance] oauth] uploadPicWithParams:params])
    {
        [sdkCall showInvalidTokenOrOpenIDMessage];
    }
    
    [self dismissModalViewControllerAnimated:YES];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)uploadPicResponse:(NSNotification *)notify
{
    [_activityIndicatorView stopAnimating];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (notify)
    {
        APIResponse *response = [[notify userInfo] objectForKey:kResponse];
        NSLog(@"%@", [response jsonResponse]);
        if (URLREQUEST_SUCCEED == response.retCode && kOpenSDKErrorSuccess == response.detailRetCode)
        {
            NSThread *getPhotoThread = [[NSThread alloc] initWithTarget:self selector:@selector(getPhotoWithUrl:) object:[[response jsonResponse] objectForKey:@"large_url"]];
            [getPhotoThread start];
        }
        else
        {
            NSString *errMsg = [NSString stringWithFormat:@"errorMsg:%@\n%@", response.errorMsg, [response.jsonResponse objectForKey:@"msg"]];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"操作失败" message:errMsg delegate:self cancelButtonTitle:@"我知道啦" otherButtonTitles: nil];
            [alert show];
        }
    }
}

- (void)getPhotoWithUrl:(NSString *)url
{
    if (nil == url)
    {
        [self setPhotoArray:[NSMutableArray array]];
        for (id dicInfo in [self photoInfoArray])
        {
            NSString *llocUrl = [[dicInfo objectForKey:@"large_image"] objectForKey:@"url"];
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:llocUrl]]];
            [[self photoArray] addObject:image];
        }
    }
    else
    {
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];
        [[self photoArray] insertObject:image atIndex:0];
        
        [self performSelectorOnMainThread:@selector(reloadData) withObject:self waitUntilDone:YES];
    }
}

#pragma mark TimeScrollerDelegate Methods

//You should return your UITableView here
- (UITableView *)tableViewForTimeScroller:(TimeScroller *)timeScroller
{
    return _tableView;
}

//You should return an NSDate related to the UITableViewCell given. This will be
//the date displayed when the TimeScroller is above that cell.
- (NSDate *)dateForCell:(UITableViewCell *)cell
{
    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
    NSDictionary *dictionary = [[self photoInfoArray] objectAtIndex:indexPath.row];
    NSNumber *time = [dictionary objectForKey:@"uploaded_time"];
    NSTimeInterval interVal = (NSTimeInterval)[time unsignedIntValue];
    return [NSDate dateWithTimeIntervalSince1970:interVal];
}

#pragma mark UIScrollViewDelegateMethods


//The TimeScroller needs to know what's happening with the UITableView (UIScrollView)
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    [_timeScroller scrollViewDidScroll];
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [_timeScroller scrollViewDidEndDecelerating];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{

    [_timeScroller scrollViewWillBeginDragging];
    _isScrolling = YES;

}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    _isScrolling = NO;
    if (!decelerate)
    {
        [_timeScroller scrollViewDidEndDecelerating];
    }
}

#pragma mark UITableViewDelegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self photoInfoArray] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static  NSString *identifier = @"TableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    NSDictionary *dictionary = [[self photoInfoArray] objectAtIndex:indexPath.row];
    NSString *title = [dictionary objectForKey:@"name"];
    cell.textLabel.text = title;
    
    if ([[self photoArray] count] > indexPath.row)
    {
        UIImage *image = [[self photoArray] objectAtIndex:indexPath.row];
        [[cell imageView] setImage:image];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSNumber *width = [[[[self photoInfoArray] objectAtIndex:indexPath.row] objectForKey:@"large_image"] objectForKey:@"width"];
    if ([[self photoInfoArray] count] > indexPath.row)
    {
        NSNumber *height = [[[[self photoInfoArray] objectAtIndex:indexPath.row] objectForKey:@"large_image"] objectForKey:@"height"];
        if (isRetina)
        {
            return [height unsignedIntegerValue] / 4;
        }
        else
        {
            return [height unsignedIntegerValue] / 2;
        }

    }
    
    return 0;
}

- (UIImage *)scaleImage:(UIImage *)image size:(CGSize)size
{
    CGFloat width = CGImageGetWidth(image.CGImage);
    CGFloat height = CGImageGetHeight(image.CGImage);
    
    float verticalRadio = size.height / height;
    float horizontalRadio = size.width / width;
    float radio = 1;
    
    if (verticalRadio > 1 && horizontalRadio > 1)
    {
        radio = verticalRadio > horizontalRadio ? horizontalRadio : verticalRadio;
    }
    else
    {
        radio = verticalRadio < horizontalRadio ? verticalRadio : horizontalRadio;
    }
    
    width = width * radio;
    height = height *radio;
    
    int xPos = (size.width - width) / 2;
    int yPos = (size.height - height) / 2;
    
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return  scaledImage;
}
@end
