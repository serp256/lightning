//
//  TQDSendStoryController.m
//  tencentOAuthDemo
//
//  Created by 易壬俊 on 13-7-2.
//
//

#import "TQDSendStoryController.h"

@interface TQDSendStoryController ()

// params binding
@property (nonatomic, retain) NSString *binding_receiver;
@property (nonatomic, retain) NSString *binding_title;
@property (nonatomic, retain) NSString *binding_summary;
@property (nonatomic, retain) NSString *binding_description;
@property (nonatomic, retain) NSString *binding_pics;
@property (nonatomic, retain) NSString *binding_shareurl;
@property (nonatomic, retain) NSString *binding_act;

@end

@implementation TQDSendStoryController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)onSendStory:(id)sender
{
    [self.view endEditing:YES];
    [self.root fetchValueUsingBindingsIntoObject:self];
    NSMutableDictionary *params = [@{
                                   @"title"      : self.binding_title ?: @"",
                                   @"act"        : self.binding_act ?: @"进入应用" ,
                                   @"summary"    : self.binding_summary ?: @"",
                                   @"description": self.binding_description ?: @"",
                                   @"pics"       : self.binding_pics ?: @"",
                                   @"shareurl"   : self.binding_shareurl ?: @""
                                   }.mutableCopy autorelease];
    NSArray *friendList = nil;
    if (self.binding_receiver.length > 0) {
        friendList = [[self.binding_receiver stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@","];
    }
    [self.tencentOAuth sendStory:params friendList:friendList];
}

@end
