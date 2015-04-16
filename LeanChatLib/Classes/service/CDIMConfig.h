//
//  CDIMConfig.h
//  LeanChatLib
//
//  Created by lzw on 15/4/8.
//  Copyright (c) 2015年 avoscloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVOSCloudIM/AVOSCloudIM.h>
#import "CDUserModel.h"

@protocol CDUserDelegate <NSObject>

@required

//同步方法
-(id<CDUserModel>) getUserById:(NSString*)userId;

//对于每条消息，都会调用这个方法来缓存发送者的用户信息，以便 getUserById 直接返回用户信息
-(void)cacheUserByIds:(NSSet*)userIds block:(AVBooleanResultBlock)block;

@end

@interface CDIMConfig : NSObject

@property (nonatomic,strong) id<CDUserDelegate> userDelegate;

+(CDIMConfig*)config;

@end
