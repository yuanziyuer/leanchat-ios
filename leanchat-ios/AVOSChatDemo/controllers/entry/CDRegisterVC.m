//
//  CDRegisterController.m
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/24/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDRegisterVC.h"
#import "CDUtils.h"
#import "CDAppDelegate.h"

@interface CDRegisterVC () <CDEntryVCDelegate>

@property (nonatomic, strong) UIBarButtonItem *cancelBarButtonItem;
@property (nonatomic, strong) UIButton *registerButton;

@end

@implementation CDRegisterVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title=@"注册";
    self.navigationItem.leftBarButtonItem = self.cancelBarButtonItem;
    [self.view addSubview:self.registerButton];
}

-(UIBarButtonItem*)cancelBarButtonItem{
    if(_cancelBarButtonItem==nil){
        UIImage *image = [UIImage imageNamed:@"cancel"];
        UIImage *selectedImage = [UIImage imageNamed:@"cancel_selected"];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, image.size.width, image.size.height);
        [button setImage:image forState:UIControlStateNormal];
        [button setImage:selectedImage forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
        _cancelBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    return _cancelBarButtonItem;
}

-(UIButton*)registerButton{
    if(_registerButton==nil){
        UIImage* normalImage= [[UIImage imageNamed:@"blue_expand_normal"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
        UIImage* highlightImage = [[UIImage imageNamed:@"blue_expand_highlight"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
        _registerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _registerButton.frame=CGRectMake(CGRectGetMinX(self.usernameField.frame), CGRectGetMaxY(self.passwordField.frame)+kEntryVCVerticalSpacing, CGRectGetWidth(self.usernameField.frame), CGRectGetHeight(self.usernameField.frame));
        [_registerButton setBackgroundImage:normalImage forState:UIControlStateNormal];
        [_registerButton setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
        [_registerButton setBackgroundImage:highlightImage forState:UIControlStateDisabled];
        _registerButton.enabled = NO;
        [_registerButton setTitle:@"注册" forState:UIControlStateNormal];
        [_registerButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_registerButton addTarget:self action:@selector(registerAVUser:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _registerButton;
}


#pragma mark - Actions

- (void)cancel:(id)sender{
    [self dismissViewControllerAnimated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }];
}

-(void)registerAVUser:(id)sender
{
    AVUser *user = [AVUser user];
    user.username = self.usernameField.text;
    user.password = self.passwordField.text;
    [user setFetchWhenSave:YES];
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [CDUtils filterError:error callback:^{
            [[NSUserDefaults standardUserDefaults] setObject:self.usernameField.text forKey:KEY_USERNAME];
            [self dismissViewControllerAnimated:NO completion:^{
                CDAppDelegate *delegate = (CDAppDelegate *)[UIApplication sharedApplication].delegate;
                [delegate toMain];
            }];
        }];
    }];
    
    
}

- (void)changeButtonState{
    if(self.usernameField.text.length >= USERNAME_MIN_LENGTH && self.passwordField.text.length >= PASSWORD_MIN_LENGTH){
        self.registerButton.enabled = YES;
    }else {
        self.registerButton.enabled = NO;
    }
}

-(void)didPasswordTextFieldReturn:(CDTextField *)passwordField{
    if(self.registerButton.enabled){
        [self registerAVUser:nil];
    }
}

-(void)textFieldDidChange:(UITextField *)textField{
    [self changeButtonState];
}

@end
