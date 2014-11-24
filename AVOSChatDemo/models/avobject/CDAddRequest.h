//
//  AddRequest.h
//  AVOSChatDemo
//
//  Created by lzw on 14-10-23.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import <AVOSCloud/AVOSCloud.h>
#define kAddRequestStatusWait 0
#define kAddRequestStatusDone 1

@interface CDAddRequest : AVObject<AVSubclassing>

@property AVUser *fromUser;
@property AVUser *toUser;
@property int status;

@end
