//
//  UserService.m
//  AVOSChatDemo
//
//  Created by lzw on 14-10-22.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDUserService.h"
#import "CDUtils.h"
#import "CDCache.h"
#import "CDAbuseReport.h"
#import <LeanChatLib/LeanChatLib.h>

static UIImage* defaultAvatar;

@implementation CDUserService

+(void)findFriendsWithBlock:(AVArrayResultBlock)block{
    AVUser* user=[AVUser currentUser];
    AVQuery* q=[user followeeQuery];
    q.cachePolicy=kAVCachePolicyNetworkElseCache;
    [q findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error==nil){
            [CDCache registerUsers:objects];
        }
        block(objects,error);
    }];
}

+(void)isMyFriend:(AVUser*)user block:(AVBooleanResultBlock)block{
    AVUser* currentUser=[AVUser currentUser];
    AVQuery*q=[currentUser followeeQuery];
    [q whereKey:@"followee" equalTo:user];
    [q findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error){
            block(NO,error);
        }else{
            if(objects.count>0){
                block(YES,nil);
            }else{
                block(NO,error);
            }
        }
    }];
};


+(NSString*)getPeerIdOfUser:(AVUser*)user{
    return user.objectId;
}

// should exclude friends
+(void)findUsersByPartname:(NSString *)partName withBlock:(AVArrayResultBlock)block{
    AVQuery *q=[AVUser query];
    [q setCachePolicy:kAVCachePolicyNetworkElseCache];
    [q whereKey:@"username" containsString:partName];
    AVUser *curUser=[AVUser currentUser];
    [q whereKey:@"objectId" notEqualTo:curUser.objectId];
    [q orderByDescending:@"updatedAt"];
    [q findObjectsInBackgroundWithBlock:block];
}

+(void)findUsersByIds:(NSArray*)userIds callback:(AVArrayResultBlock)callback{
    if([userIds count]>0){
        AVQuery *q=[AVUser query];
        [q setCachePolicy:kAVCachePolicyNetworkElseCache];
        [q whereKey:@"objectId" containedIn:userIds];
        [q findObjectsInBackgroundWithBlock:callback];
    }else{
        callback([[NSArray alloc] init],nil);
    }
}

+(void)displayAvatarOfUser:(AVUser*)user avatarView:(UIImageView*)avatarView{
    AVFile* avatar=[user objectForKey:@"avatar"];
    if(avatar){
        [avatar getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if(error==nil){
                UIImage* image=[UIImage imageWithData:data];
                [avatarView setImage:image];
            }else{
                UIImage* placeHolder=[UIImage imageNamed:@"default_user_avatar"];
                [avatarView setImage:placeHolder];
            }
        }];
    }else{
        [avatarView setImage:[UIImage imageWithHashString:user.objectId displayString:[[user.username substringWithRange:NSMakeRange(0, 1)] capitalizedString]]];
    }
}

+(UIImage*)getAvatarOfUser:(AVUser*)user{
    if(defaultAvatar==nil){
        defaultAvatar=[UIImage imageNamed:@"default_user_avatar"];
    }
    UIImage* image=defaultAvatar;
    AVFile* avatarFile=[user objectForKey:@"avatar"];
    if(avatarFile==nil){
        [CDUtils alert:@"avatar of user is nil"];
    }else{
        NSError* error;
        NSData* data=[avatarFile getData:&error];
        if(error==nil){
            image=[UIImage imageWithData:data];
        }else{
            DLog(@"%@",error);
        }
    }
    return image;
}

+(void)saveAvatar:(UIImage*)image callback:(AVBooleanResultBlock)callback{
    NSData* data=UIImagePNGRepresentation(image);
    AVFile* file=[AVFile fileWithData:data];
    [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(error){
            callback(succeeded,error);
        }else{
            AVUser* user=[AVUser currentUser];
            [user setObject:file forKey:@"avatar"];
            [user setFetchWhenSave:YES];
            [user saveInBackgroundWithBlock:callback];
        }
    }];
}

+(void)addFriend:(AVUser*)user callback:(AVBooleanResultBlock)callback{
    AVUser* curUser=[AVUser currentUser];
    [curUser follow:user.objectId andCallback:callback];
}

+(void)removeFriend:(AVUser*)user callback:(AVBooleanResultBlock)callback{
    AVUser* curUser=[AVUser currentUser];
    [curUser unfollow:user.objectId andCallback:callback];
}

#pragma mark - AddRequest

+(void)findAddRequestsWithBlock:(AVArrayResultBlock)block{
    AVUser* curUser=[AVUser currentUser];
    AVQuery *q=[CDAddRequest query];
    [q includeKey:kAddRequestFromUser];
    [q whereKey:kAddRequestToUser equalTo:curUser];
    [q orderByDescending:@"createdAt"];
    [q findObjectsInBackgroundWithBlock:block];
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
            if(error.code==kAVErrorObjectNotFound){
                callback(NO,nil);
            }else{
                callback(NO,error);
            }
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

#pragma mark - report abuse
+(void)reportAbuseWithReason:(NSString*)reason convid:(NSString*)convid block:(AVBooleanResultBlock)block{
    CDAbuseReport *report=[[CDAbuseReport alloc] init];
    report.reason=reason;
    report.convid=convid;
    report.author=[AVUser currentUser];
    [report saveInBackgroundWithBlock:block];
}

@end
