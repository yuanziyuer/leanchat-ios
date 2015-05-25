//
//  AlertViewHelper.m
//  AVOSDemo
//
//  Created by lzw on 15/5/21.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "AlertViewHelper.h"

@interface AlertViewHelper()<UIAlertViewDelegate>

@property (nonatomic, copy) AlertViewFinishBlock finishBlock;

@property (nonatomic, assign) UIAlertViewStyle alertViewStyle;

@property (nonatomic, strong) NSString *inputText;

@property (nonatomic, assign) BOOL result;

@end

@implementation AlertViewHelper

- (void)showAlertViewWithMessage:(NSString *)message type:(UIAlertViewStyle)style block:(AlertViewFinishBlock)block {
    self.finishBlock = block;
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    self.alertViewStyle = style;
    alertView.alertViewStyle = style;
    [alertView show];
}

- (void)showInputAlertViewWithMessage:(NSString *)message block:(AlertViewFinishBlock)block {
    [self showAlertViewWithMessage:message type:UIAlertViewStylePlainTextInput block:block];
}

- (void)showAlertViewWithMessage:(NSString *)message block:(AlertViewFinishBlock)block {
    [self showAlertViewWithMessage:message type:UIAlertViewStyleDefault block:block];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        self.result = YES;
        if (self.alertViewStyle == UIAlertViewStylePlainTextInput) {
            self.inputText = [alertView textFieldAtIndex:0].text;
        }
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (self.finishBlock) {
        self.finishBlock(self.result, self.inputText);
    }
    self.inputText = nil;
    self.finishBlock = nil;
    self.result = NO;
}

@end
