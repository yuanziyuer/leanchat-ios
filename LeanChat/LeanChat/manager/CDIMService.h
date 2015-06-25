//
//  CDIMService.h
//  LeanChat
//
//  Created by lzw on 15/4/3.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDCommon.h"
#import <LeanChatLib/CDChatManager.h>

@interface CDIMService : NSObject <CDUserDelegate>

+ (instancetype)service;

- (void)goWithUserId:(NSString *)userId fromVC:(UIViewController *)vc;
- (void)goWithConv:(AVIMConversation *)conv fromNav:(UINavigationController *)nav;

@end
