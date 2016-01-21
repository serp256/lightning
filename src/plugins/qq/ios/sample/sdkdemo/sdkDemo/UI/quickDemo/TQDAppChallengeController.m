//
//  TQDAppChallengeController.m
//  tencentOAuthDemo
//
//  Created by 易壬俊 on 13-6-19.
//
//

#import "TQDAppChallengeController.h"

@interface TQDAppChallengeController ()

// params binding
@property (nonatomic, retain) NSString *binding_source;
@property (nonatomic, retain) NSString *binding_receiver;
@property (nonatomic, retain) NSString *binding_img;
@property (nonatomic, retain) NSString *binding_msg;

@end

@implementation TQDAppChallengeController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    [_binding_source release];
    [_binding_receiver release];
    [_binding_img release];
    [_binding_msg release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)onSendChallenge:(id)sender
{
    [self.view endEditing:YES];
    QSegmentedElement *element = (QSegmentedElement *)[self.root elementWithKey:@"typeSegmentedElement"];
    NSString *type = (NSString *)element.selectedValue;
    [self.root fetchValueUsingBindingsIntoObject:self];
    [self.tencentOAuth sendChallenge:self.binding_receiver type:type imageURL:self.binding_img message:self.binding_msg source:self.binding_source];
}

@end
