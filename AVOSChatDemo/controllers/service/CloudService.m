//
//  CloudService.m
//  AVOSChatDemo
//
//  Created by lzw on 14-10-24.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CloudService.h"
#import "UserService.h"

@implementation CloudService

+(void)callCloudRelationFnWithFromUser:(AVUser*)fromUser toUser:(AVUser*)toUser action:(NSString*)action callback:(AVIdResultBlock)callback{
    NSDictionary *dict=@{@"fromUserId":fromUser.objectId,@"toUserId":toUser.objectId};
    [AVCloud callFunctionInBackground:action withParameters:dict block:callback];
}

+(void)tryCreateAddRequestWithToUser:(AVUser*)toUser callback:(AVIdResultBlock)callback{
    AVUser* user=[AVUser currentUser];
    assert(user!=nil);
    NSDictionary* dict=@{@"fromUserId":user.objectId,@"toUserId":toUser.objectId};
    [AVCloud callFunctionInBackground:@"tryCreateAddRequest" withParameters:dict block:callback];
}

+(void)agreeAddRequestWithId:(NSString*)objectId callback:(AVIdResultBlock)callback{
    NSDictionary* dict=@{@"objectId":objectId};
    [AVCloud callFunctionInBackground:@"agreeAddRequest" withParameters:dict block:callback];
}

+(void)saveChatGroupWithId:(NSString*)groupId name:(NSString*)name callback:(AVIdResultBlock)callback{
    NSString* userId=[AVUser currentUser].objectId;
    assert(userId!=nil);
    NSDictionary* dict=@{@"groupId":groupId,@"ownerId":userId,@"name":name};
    [AVCloud callFunctionInBackground:@"saveChatGroup" withParameters:dict block:callback];
}

@end
