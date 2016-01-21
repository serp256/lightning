//
//  TCApiObjectEditController.m
//  tencentOAuthDemo
//
//  Created by JeaminWong on 13-3-18.
//
//

#import <QuartzCore/QuartzCore.h>
#import "TCApiObjectEditController.h"

#define kTCTextViewBorderWidth 2.0f
#define kTCKeyboardCandidateAreaHeigth 40.0f

@interface TCApiObjectEditController ()
{
    CGSize _keyboardSize;
    CGRect _rootViewFrame;
}

@property (nonatomic, strong) TCApiObjectEditDoneHandler editDoneHandler;
@property (nonatomic, strong) TCApiObjectEditCancelHandler editCancelHandler;
@property (retain, nonatomic) UIViewController *parentCtrl;

- (IBAction)onBtnConfirmPressed:(UIButton *)sender;
- (IBAction)onBtnCancelPressed:(UIButton *)sender;
- (IBAction)onBkgPressed:(UIControl *)sender;

- (void)keyboardWillShow:(NSNotification*)note;

@end

@implementation TCApiObjectEditController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.view.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.editDoneHandler = nil;
    self.editCancelHandler = nil;
    
    [super viewDidDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.objDesc.layer.borderWidth = kTCTextViewBorderWidth;
    self.objDesc.layer.borderColor = [UIColor blackColor].CGColor;
    
    self.objText.layer.borderWidth = kTCTextViewBorderWidth;
    self.objText.layer.borderColor = [UIColor blackColor].CGColor;
    
    self.objUrl.layer.borderWidth = kTCTextViewBorderWidth;
    self.objUrl.layer.borderColor = [UIColor blackColor].CGColor;
    
    self.objTitle.delegate = self;
    self.objDesc.delegate = self;
    self.objText.delegate = self;
    self.objUrl.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.editDoneHandler = nil;
    self.editCancelHandler = nil;
    self.parentCtrl = nil;
    
    [_objTitle release];
    [_objDesc release];
    [_objText release];
    [_objUrl release];
    [super dealloc];
}
- (void)viewDidUnload {
    self.editDoneHandler = nil;
    self.editDoneHandler = nil;
    
    [self setObjTitle:nil];
    [self setObjDesc:nil];
    [self setObjText:nil];
    [self setObjUrl:nil];
    [super viewDidUnload];
}

- (void)keyboardWillShow:(NSNotification *)note
{
    NSDictionary *userInfo = [note userInfo];
    NSValue *value = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    _keyboardSize = [value CGRectValue].size;
    _rootViewFrame = self.view.frame;
}

- (IBAction)onBtnConfirmPressed:(UIButton *)sender {
    if (self.editDoneHandler)
    {
        self.editDoneHandler(self);
        self.editDoneHandler = nil;
    }
    
    if ([self.parentCtrl respondsToSelector:@selector(dismissViewControllerAnimated:completion:)])
    {
        [self.parentCtrl dismissViewControllerAnimated:YES completion:NULL];
    }
    else
    {
        [self.parentCtrl dismissModalViewControllerAnimated:YES];
    }
    
    self.parentCtrl = nil;
}

- (IBAction)onBtnCancelPressed:(UIButton *)sender {
    if (self.editCancelHandler)
    {
        self.editCancelHandler(self);
        self.editCancelHandler = nil;
    }
    
    if ([self.parentCtrl respondsToSelector:@selector(dismissViewControllerAnimated:completion:)])
    {
        [self.parentCtrl dismissViewControllerAnimated:YES completion:NULL];
    }
    else
    {
        [self.parentCtrl dismissModalViewControllerAnimated:YES];
    }
    
    self.parentCtrl = nil;
}

- (IBAction)onBkgPressed:(UIControl *)sender {
    [_objTitle resignFirstResponder];
    [_objDesc resignFirstResponder];
    [_objText resignFirstResponder];
    [_objUrl resignFirstResponder];
}

- (void)modalIn:(UIViewController *)parentCtrl withDoneHandler:(TCApiObjectEditDoneHandler)doneHandler cancelHandler:(TCApiObjectEditCancelHandler)cancelHandler animated:(BOOL)animated
{
    self.editDoneHandler = doneHandler;
    self.editCancelHandler = cancelHandler;
    self.parentCtrl = parentCtrl;
    [self.parentCtrl presentModalViewController:self animated:animated];
}

#pragma mark -
#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

#pragma mark -
#pragma mark UITextViewDelegate
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    CGRect frame = textView.frame;
    CGFloat textViewBottom = frame.origin.y + frame.size.height;
    frame = self.view.bounds;
    CGFloat rootViewBottom = frame.origin.y + frame.size.height;
    if (rootViewBottom - textViewBottom < _keyboardSize.height + kTCKeyboardCandidateAreaHeigth)
    {
        frame = self.view.frame;
        frame.origin.y -= (_keyboardSize.height + kTCKeyboardCandidateAreaHeigth - rootViewBottom + textViewBottom);
        self.view.frame = frame;
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (_rootViewFrame.size.height!=0 || _rootViewFrame.size.width!=0) {
        self.view.frame = _rootViewFrame;
    }
}

@end
