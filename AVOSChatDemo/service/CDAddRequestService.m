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

+(void)agreeAddRequest:(CDAddRequest*)addRequest callback:(AVBooleanResultBlock)callback{
    [CDUserService addFriend:addRequest.fromUser callback:^(BOOL succeeded, NSError *error) {
        if(error){
            if(error.code!=kAVErrorDuplicateValue){
                callback(NO,error);
            }else{
                addRequest.status=CDAddRequestStatusDone;
                [addRequest saveInBackgroundWithBlock:callback];
            }
        }else{
            addRequest.status=CDAddRequestStatusDone;
            [addRequest saveInBackgroundWithBlock:callback];
        }
    }];
}

+(void)haveWaitAddRequestWithToUser:(AVUser*)toUser callback:(AVBooleanResultBlock)callback{
    AVUser* user=[AVUser currentUser];
    AVQuery* q=[CDAddRequest query];
    [q whereKey:kAddRequestFromUser equalTo:user];
    [q whereKey:kAddRequestToUser equalTo:toUser];
    [q whereKey:kAddRequestStatus equalTo:@(CDAddRequestStatusWait)];
    [q countObjectsInBackgroundWithBlock:^(NSInteger number, NSError *error) {
        if(error){
            callback(0,error);
        }else{
            if(number>0){
                callback(YES,error);
            }else{
                callback(NO,error);
            }
        }
    }];
}

+(void)tryCreateAddRequestWithToUser:(AVUser*)user callback:(AVBooleanResultBlock)callback{
    [self haveWaitAddRequestWithToUser:user callback:^(BOOL succeeded, NSError *error) {
        if(error){
            callback(NO,error);
        }else{
            if(succeeded){
                callback(YES,[NSError errorWithDomain:@"Add Request" code:0 userInfo:@{NSLocalizedDescriptionKey:@"已经请求过了"}]);
            }else{
                AVUser* curUser=[AVUser currentUser];
                CDAddRequest* addRequest=[[CDAddRequest alloc] init];
                addRequest.fromUser=curUser;
                addRequest.toUser=user;
                addRequest.status=CDAddRequestStatusWait;
                [addRequest saveInBackgroundWithBlock:callback];
            }
        }
    }];
}

@end
