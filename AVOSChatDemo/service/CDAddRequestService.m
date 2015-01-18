//
//  AddRequestService.m
//  AVOSChatDemo
//
//  Created by lzw on 14-10-23.
//  Copyright (c) 2014年 AVOS. All rights reserved.
// 

#import "CDAddRequestService.h"
#import "CDUtils.h"

@implementation CDAddRequestService

+(void)findAddRequestsOnlyByNetwork:(BOOL)onlyNetwork withCallback:(AVArrayResultBlock)callback{
    AVUser* curUser=[AVUser currentUser];
    AVQuery *q=[CDAddRequest query];
    [q includeKey:@"fromUser"];
    [q whereKey:@"toUser" equalTo:curUser];
    [q orderByDescending:@"createdAt"];
    [CDUtils setPolicyOfAVQuery:q isNetwokOnly:onlyNetwork];
    [q findObjectsInBackgroundWithBlock:callback];
}

+(void)countAddRequestsWithBlock:(AVIntegerResultBlock)block{
    AVQuery  *q=[CDAddRequest query];
    AVUser* user=[AVUser currentUser];
    [q whereKey:TO_USER equalTo:user];
    [q setCachePolicy:kAVCachePolicyNetworkElseCache];
    [q countObjectsInBackgroundWithBlock:block];
}

@end
