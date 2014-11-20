//
//  GroupService.h
//  AVOSChatDemo
//
//  Created by lzw on 14/11/6.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVOSCloud/AVOSCloud.h>

@interface GroupService : NSObject

+(void)findGroupsWithCallback:(AVArrayResultBlock)callback;

+(void)findGroupsByIds:(NSMutableSet*)groupIds withCallback:(AVArrayResultBlock)callback;

@end
