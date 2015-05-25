//
//  AlertViewHelper.h
//  AVOSDemo
//
//  Created by lzw on 15/5/21.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^AlertViewFinishBlock)(BOOL confirm, NSString *text);

@interface AlertViewHelper : NSObject

- (void)showInputAlertViewWithMessage:(NSString *)message block:(AlertViewFinishBlock)block;

- (void)showAlertViewWithMessage:(NSString *)message block:(AlertViewFinishBlock)block;

@end
