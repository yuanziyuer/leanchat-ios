//
//  CDEntryVC.h
//  LeanChat
//
//  Created by lzw on 15/4/15.
//  Copyright (c) 2015年 LeanCloud. All rights reserved.
//

#import "CDBaseVC.h"
#import "CDTextField.h"
#import "CDResizableButton.h"
#import <AVOSCloud/AVOSCloud.h>

#define KEY_USERNAME @"KEY_USERNAME"
#define USERNAME_MIN_LENGTH 3
#define PASSWORD_MIN_LENGTH 3
#define RGBCOLOR(r, g, b) [UIColor colorWithRed : (r) / 255.0 green : (g) / 255.0 blue : (b) / 255.0 alpha : 1]

static CGFloat kEntryVCIconImageViewMarginTop = 80;
static CGFloat kEntryVCIconImageViewSize = 80;
static CGFloat kEntryVCHorizontalSpacing = 30;
static CGFloat kEntryVCVerticalSpacing = 10;
static CGFloat kEntryVCUsernameFieldMarginTop = 30;
static CGFloat kEntryVCTextFieldPadding = 10;
static CGFloat kEntryVCTextFieldHeight = 40;

@protocol CDEntryVCDelegate <NSObject>

- (void)didPasswordTextFieldReturn:(CDTextField *)passwordField;

- (void)textFieldDidChange:(UITextField *)textField;

@end

@interface CDEntryVC : CDBaseVC

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) CDTextField *usernameField;
@property (nonatomic, strong) CDTextField *passwordField;

@end
