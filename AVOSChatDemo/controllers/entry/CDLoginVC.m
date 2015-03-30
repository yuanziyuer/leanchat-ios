//
//  CDLoginController.m
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/24/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDLoginVC.h"
#import "CDCommon.h"
#import "CDTextField.h"
#import "CDRegisterVC.h"
#import "CDBaseNavC.h"
#import "CDAppDelegate.h"
#import "CDService.h"

@interface CDLoginVC () <UITextFieldDelegate> {
    CGPoint _originOffset;
}
@property (nonatomic, strong)CDTextField *usernameField;
@property (nonatomic, strong)CDTextField *passwordField;
@property (nonatomic, strong)CDResizableButton *loginButton;

@end

@implementation CDLoginVC

- (void)viewDidLoad {
    [super viewDidLoad];
    //此处有坑，在iOS6.0时候 没有考虑到statusbar的高度问题，view所占高度为460 并不是SCREEN_HEIGHT
    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeKeyboard:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tap];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(closeKeyboard:)];
    [self.view addGestureRecognizer:pan];
    
    //[self.view setBackgroundColor:RGBCOLOR(222, 223, 225)];
    
    UIImage *image = [UIImage imageNamed:@"rounded_icon"];
    CGFloat width = image.size.width/2;
    CGFloat height = image.size.height/2;
    CGFloat originX = CGRectGetWidth(self.view.frame)/2-width/2;
    CGFloat originY=60;
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = CGRectMake(originX, originY, width, height);
    [self.view addSubview:imageView];
    
    originX = 30;
    originY = (SCREEN_HEIGHT<=480)?150:180;
    width = self.view.frame.size.width - originX*2;
    image = [UIImage imageNamed:@"input_bg_top"];
    height = image.size.height;
    CDTextField *textField = [[CDTextField alloc] initWithFrame:CGRectMake(originX, originY, width, height)];
    textField.background = image;
    textField.horizontalPadding = 10;
    textField.verticalPadding = 10;
    textField.placeholder = @"用户名";
    textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    textField.delegate = self;
    textField.returnKeyType = UIReturnKeyNext;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.view addSubview:textField];
    self.usernameField = textField;
    
    originY += height;
    image = [UIImage imageNamed:@"input_bg_bottom"];
    height = image.size.height;
    textField = [[CDTextField alloc] initWithFrame:CGRectMake(originX, originY, width, height)];
    textField.background = image;
    textField.horizontalPadding = 10;
    textField.verticalPadding = 10;
    textField.placeholder = @"密码";
    textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    textField.delegate = self;
    textField.secureTextEntry = YES;
    textField.returnKeyType = UIReturnKeyGo;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.view addSubview:textField];
    self.passwordField = textField;
    
    originY += height + 7;
    CDResizableButton* resizeButton=[[CDResizableButton alloc] initWithFrame:CGRectMake(originX,originY,width,height)];
    [resizeButton setTitle:@"登录" forState:UIControlStateNormal];
    [resizeButton setBackgroundImage:[UIImage imageNamed:@"blue_expand_normal"] forState:UIControlStateNormal];
    [resizeButton setBackgroundImage:[UIImage imageNamed:@"blue_expand_highlight"] forState:UIControlStateHighlighted];
    [resizeButton setBackgroundImage:[UIImage imageNamed:@"blue_expand_normal"] forState:UIControlStateDisabled];
    resizeButton.enabled=NO;
    [resizeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    //[resizeButton setBackgroundColor:[UIColor redColor]];
    [resizeButton addTarget:self action:@selector(login:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:resizeButton];
    self.loginButton = resizeButton;
    
    image = [[UIImage imageNamed:@"bottom_bar_normal"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    UIImage *selectedImage = [[UIImage imageNamed:@"bottom_bar_selected"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    originX = 0;
    originY = self.view.frame.size.height - image.size.height;
    width = self.view.frame.size.width/2;
    height = image.size.height;
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(originX, originY, width, height);
    [button setBackgroundImage:image forState:UIControlStateNormal];
    [button setBackgroundImage:selectedImage forState:UIControlStateHighlighted];
    [button setTitleColor:RGBCOLOR( 93,92,92) forState:UIControlStateNormal];
    [button setTitle:@"注册账号" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    [button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
    //    button.userInteractionEnabled = YES;
    [button addTarget:self action:@selector(toRegister:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    image = [UIImage imageNamed:@"bottom_bar_separator"];
    originX = (self.view.frame.size.width - image.size.width)/2;
    width = image.size.width;
    height = image.size.height;
    imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = CGRectMake(originX, originY, width, height);
    [self.view addSubview:imageView];
    
    image = [[UIImage imageNamed:@"bottom_bar_normal"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    originX = self.view.frame.size.width/2;
    width = self.view.frame.size.width/2;
    height = image.size.height;
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(originX, originY, width, height);
    [button setBackgroundImage:image forState:UIControlStateNormal];
    [button setBackgroundImage:selectedImage forState:UIControlStateHighlighted];
    [button setTitleColor:RGBCOLOR( 93,92,92) forState:UIControlStateNormal];
    [button setTitle:@"找回密码" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    [button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
    //    button.userInteractionEnabled = YES;
    [button addTarget:self action:@selector(toFindPassword:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
//    [self.navigationController.navigationBar setHidden:YES];
    
    //监听键盘高度的变换
    if (SCREEN_HEIGHT <= 480) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    
    
    self.usernameField.text = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USERNAME];
    [self changeButtonState:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeButtonState:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    UIScrollView *scrollView = (UIScrollView *)self.view;
    _originOffset = scrollView.contentOffset;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Actions
//Login button pressed
-(void)login:(id)sender {
//    [AVUser logInWithMobilePhoneNumberInBackground:self.usernameField.text smsCode:self.passwordField.text block:^(AVUser *user, NSError *error) {
//        if (user) {
//            //Login success
//            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:KEY_ISLOGINED];
//            [[NSUserDefaults standardUserDefaults] setObject:self.usernameField.text forKey:KEY_USERNAME];
//            NSLog(@"Login success");
//            CDAppDelegate *delegate = (CDAppDelegate *)[UIApplication sharedApplication].delegate;
//            [delegate toMain];
//        } else {
//            //Something bad has ocurred
//            NSString *errorString = [[error userInfo] objectForKey:@"error"];
//            UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Error" message:errorString delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
//            [errorAlertView show];
//        }
//    }];
//    [AVUser logInWithMobilePhoneNumberInBackground:self.usernameField.text password:self.passwordField.text block:^(AVUser *user, NSError *error) {
//        if (user) {
//            //Login success
//            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:KEY_ISLOGINED];
//            [[NSUserDefaults standardUserDefaults] setObject:self.usernameField.text forKey:KEY_USERNAME];
//            NSLog(@"Login success");
//            CDAppDelegate *delegate = (CDAppDelegate *)[UIApplication sharedApplication].delegate;
//            [delegate toMain];
//        } else {
//            //Something bad has ocurred
//            NSString *errorString = [[error userInfo] objectForKey:@"error"];
//            UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Error" message:errorString delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
//            [errorAlertView show];
//        }
//    }];
    
    [AVUser logInWithUsernameInBackground:self.usernameField.text password:self.passwordField.text block:^(AVUser *user, NSError *error) {
        if([CDUtils filterError:error]){
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:KEY_ISLOGINED];
            [[NSUserDefaults standardUserDefaults] setObject:self.usernameField.text forKey:KEY_USERNAME];
            CDAppDelegate *delegate = (CDAppDelegate *)[UIApplication sharedApplication].delegate;
            [delegate toMain];
        }
    }];
}

-(void)toRegister:(id)sender {
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    CDRegisterVC *vc = [[CDRegisterVC alloc] init];
    CDBaseNavC *nav = [[CDBaseNavC alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)toFindPassword:(id)sender {
    
}

- (void)closeKeyboard:(id)sender {
    [self.usernameField resignFirstResponder];
    [self.passwordField resignFirstResponder];
}

- (void)changeButtonState:(NSNotification *)notification{
    UIButton *button = self.loginButton;
    if(self.usernameField.text.length >= USERNAME_MIN_LENGTH && self.passwordField.text.length >= PASSWORD_MIN_LENGTH){
        button.enabled = YES;
    }else {
        button.enabled = NO;
    }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldClear:(UITextField *)textField{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if(textField == self.usernameField){
        [self.passwordField becomeFirstResponder];
    }else if(textField == self.passwordField){
        [self login:nil];
    }
    return YES;
}

#pragma mark - Responding to keyboard events
- (void)keyboardWillShow:(NSNotification *)notification {
    [self performSelector:@selector(moveUpMainView) withObject:nil afterDelay:0.1];
}

- (void)keyboardWillHide:(NSNotification *)notification{
    UIScrollView *scrollView = (UIScrollView *)self.view;
    [scrollView setContentOffset:_originOffset animated:YES];
}

- (void)moveUpMainView{
    UIScrollView *scrollView = (UIScrollView *)self.view;
    [scrollView setContentOffset:CGPointMake(0, 65) animated:YES];
}

@end
