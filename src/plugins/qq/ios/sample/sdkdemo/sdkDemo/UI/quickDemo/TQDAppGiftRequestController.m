//
//  TQDAppGiftRequestController.m
//  tencentOAuthDemo
//
//  Created by 易壬俊 on 13-6-24.
//
//

#import "TQDAppGiftRequestController.h"

@interface TQDAppGiftRequestController () <QuickDialogEntryElementDelegate>

// params binding
@property (nonatomic, retain) NSString *binding_source;
@property (nonatomic, retain) NSString *binding_receiver;
@property (nonatomic, retain) NSString *binding_title;
@property (nonatomic, retain) NSString *binding_msg;
@property (nonatomic, retain) NSString *binding_img;
@property (nonatomic, retain) NSString *binding_exclude;
@property (nonatomic, retain) NSString *binding_specified;
@property (nonatomic, assign) BOOL      binding_only;

@end

@implementation TQDAppGiftRequestController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    QEntryElement *entryElement = (QEntryElement *)[self.root elementWithKey:@"QEntryElement_specified"];
    entryElement.delegate = nil;
    [_binding_source release];
    [_binding_receiver release];
    [_binding_title release];
    [_binding_img release];
    [_binding_msg release];
    [_binding_exclude release];
    [_binding_specified release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)onSendRequest:(id)sender
{
    [self.view endEditing:YES];
    QSegmentedElement *element = (QSegmentedElement *)[self.root elementWithKey:@"typeSegmentedElement"];
    NSString *type = (NSString *)element.selectedValue;
    [self.root fetchValueUsingBindingsIntoObject:self];
    [self.tencentOAuth sendGiftRequest:_binding_receiver
                               exclude:_binding_exclude
                             specified:_binding_specified
                                  only:_binding_only
                                  type:type
                                 title:_binding_title
                               message:_binding_msg
                              imageURL:_binding_img
                                source:_binding_source];
}

@end
