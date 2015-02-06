//
//  UserService.m
//  AVOSChatDemo
//
//  Created by lzw on 14-10-22.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDUserService.h"
#import "CDUtils.h"

static UIImage* defaultAvatar;

@implementation CDUserService

+(void)findFriendsIsNetworkOnly:(BOOL)networkOnly callback:(AVArrayResultBlock)callback{
    AVUser* user=[AVUser currentUser];
    [user getFollowees:callback];
}

+(void)findFriendsWithCallback:(AVArrayResultBlock)callback{
    AVUser* user=[AVUser currentUser];
    AVQuery* q=[AVRelation reverseQuery:@"_User" relationKey:@"friends" childObject:user];
    [q findObjectsInBackgroundWithBlock:callback];
}

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
    UIImage* placeHolder=[UIImage imageNamed:@"default_user_avatar"];
    [avatarView setImage:placeHolder];
    AVFile* avatar=[user objectForKey:@"avatar"];
    if(avatar){
        [avatar getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if(error==nil){
                UIImage* image=[UIImage imageWithData:data];
                [avatarView setImage:image];
            }else{
                [CDUtils alertError:error];
            }
        }];
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
            [CDUtils alertError:error];
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

@end
