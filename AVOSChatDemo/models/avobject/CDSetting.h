//
//  CDSetting.h
//  LeanChat
//
//  Created by lzw on 15/1/15.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import <AVOSCloud/AVOSCloud.h>
#define MSG_PUSH @"msgPush"
#define SOUND @"sound"

@interface CDSetting : AVObject<AVSubclassing>

@property  BOOL msgPush;

@property  BOOL sound;

@end
