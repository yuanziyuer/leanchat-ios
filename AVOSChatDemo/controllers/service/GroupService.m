//
//  GroupService.m
//  AVOSChatDemo
//
//  Created by lzw on 14/11/6.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "GroupService.h"
#import "ChatGroup.h"

@implementation GroupService

+(void)findGroupsWithCallback:(AVArrayResultBlock)callback{
    AVUser* user=[AVUser currentUser];
    AVQuery* q=[ChatGroup query];
    [q includeKey:@"owner"];
    [q setCachePolicy:kAVCachePolicyNetworkElseCache];
    [q whereKey:@"m" equalTo:user.objectId];
    [q orderByDescending:@"createdAt"];
    [q findObjectsInBackgroundWithBlock:callback];
}

+(void)findGroupsByIds:(NSMutableSet*)groupIds withCallback:(AVArrayResultBlock)callback{
    if(groupIds.count>0){
        AVQuery* q=[ChatGroup query];
        [q whereKey:@"objectId" containedIn:[groupIds allObjects]];
        [q includeKey:@"owner"];
        [q findObjectsInBackgroundWithBlock:callback];
    }else{
        callback([[NSMutableArray alloc] init],nil);
    }
}

@end
