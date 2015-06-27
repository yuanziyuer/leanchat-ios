//
//  AddRequest.h
//  LeanChat
//
//  Created by lzw on 14-10-23.
//  Copyright (c) 2014年 LeanCloud. All rights reserved.
//

#import "CDCommon.h"

typedef enum : NSUInteger {
    CDAddRequestStatusWait = 0,
    CDAddRequestStatusDone
} CDAddRequestStatus;

#define kAddRequestFromUser @"fromUser"
#define kAddRequestToUser @"toUser"
#define kAddRequestStatus @"status"

@interface CDAddRequest : AVObject <AVSubclassing>

@property AVUser *fromUser;
@property AVUser *toUser;
@property int status;

@end
