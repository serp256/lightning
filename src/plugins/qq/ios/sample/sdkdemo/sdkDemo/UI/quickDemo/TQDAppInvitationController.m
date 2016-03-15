//
//  TQDAppInvitationController.m
//  tencentOAuthDemo
//
//  Created by 易壬俊 on 13-6-3.
//
//

#import "TQDAppInvitationController.h"
#import "QuickDemoViewController.h"

@interface TQDAppInvitationController ()

// params binding
@property (nonatomic, retain) NSString *binding_source;
@property (nonatomic, retain) NSString *binding_picurl;
@property (nonatomic, retain) NSString *binding_desc;

@end

@implementation TQDAppInvitationController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)dealloc
{
    [_binding_source release];
    _binding_source = nil;
    [_binding_picurl release];
    _binding_picurl = nil;
    [_binding_desc release];
    _binding_desc = nil;
    [super dealloc];
}

- (void)onSendAppInvitation:(id)sender
{
    [self.view endEditing:YES];
    [self.root fetchValueUsingBindingsIntoObject:self];
    [self.tencentOAuth sendAppInvitationWithDescription:self.binding_desc imageURL:self.binding_picurl source:self.binding_source];
}

@end
