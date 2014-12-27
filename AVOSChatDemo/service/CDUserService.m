//
//  UserService.m
//  AVOSChatDemo
//
//  Created by lzw on 14-10-22.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDUserService.h"
#import "CDUtils.h"

@implementation CDUserService

+(void)findFriendsIsNetworkOnly:(BOOL)networkOnly callback:(AVArrayResultBlock)block{
    AVUser *user=[AVUser currentUser];
    AVRelation *relation=[user relationforKey:@"friends"];
    //    //设置缓存有效期
    //    query.maxCacheAge = 4 * 3600;
    AVQuery *q=[relation query];
    [CDUtils setPolicyOfAVQuery:q isNetwokOnly:networkOnly];
    if([q hasCachedResult]){
        NSLog(@"has cached results");
    }else{
        NSLog(@"don't have cache");
    }
    [q findObjectsInBackgroundWithBlock:block];
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

-(NSString*)getAvatarUrlOfAVUser:(AVUser*)user{
    AVFile* file=[user valueForKey:@"avatar"];
    return file.url;
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

@end
