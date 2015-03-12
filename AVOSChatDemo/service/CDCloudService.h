//
//  CloudService.h
//  AVOSChatDemo
//
//  Created by lzw on 14-10-24.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVOSCloud/AVOSCloud.h>

@interface CDCloudService : NSObject

+(id)convSignWithSelfId:(NSString*)selfId convid:(NSString*)convid targetIds:(NSArray*)targetIds action:(NSString*)action;


@end
