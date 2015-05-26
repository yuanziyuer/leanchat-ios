//
//  AlertViewHelper.h
//  AVOSDemo
//
//  Created by lzw on 15/5/21.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^LZAlertViewHelperFinishBlock)(BOOL confirm, NSString *text);

@interface LZAlertViewHelper : NSObject

- (void)showInputAlertViewWithMessage:(NSString *)message block:(LZAlertViewHelperFinishBlock)block;

- (void)showAlertViewWithMessage:(NSString *)message block:(LZAlertViewHelperFinishBlock)block;

@end
