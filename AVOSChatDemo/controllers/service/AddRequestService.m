//
//  AddRequestService.m
//  AVOSChatDemo
//
//  Created by lzw on 14-10-23.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "AddRequestService.h"

@implementation AddRequestService

+(void)findAddRequestsWtihCallback:(AVArrayResultBlock)callback{
    AVUser* curUser=[AVUser currentUser];
    AVQuery *q=[AddRequest query];
    [q includeKey:@"fromUser"];
    [q whereKey:@"toUser" equalTo:curUser];
    [q orderByDescending:@"createdAt"];
    [q findObjectsInBackgroundWithBlock:callback];
}
@end
