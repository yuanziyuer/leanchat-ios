//
//  AddRequestService.h
//  AVOSChatDemo
//
//  Created by lzw on 14-10-23.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDAddRequest.h"

@interface CDAddRequestService : NSObject

+(void)findAddRequestsOnlyByNetwork:(BOOL)onlyNetwork withCallback:(AVArrayResultBlock)callback;

@end
