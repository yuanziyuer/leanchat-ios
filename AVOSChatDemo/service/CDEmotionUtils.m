//
//  CDEmotionUtils.m
//  LeanChat
//
//  Created by lzw on 14/11/25.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDEmotionUtils.h"
#import "XHEmotionManager.h"

@implementation CDEmotionUtils

+(NSArray*)getEmotionManagers{
    NSString* emotionChars=@"😄😃😊☺️😍😘😚😗😜😝😛😳😁😌😒😞😣😢😂😭😪😥😰😅😓😩😫😨😱😠😡😤😖😆😋😷😎😴😵😲😏😬😐";
    NSMutableArray *emotionManagers = [NSMutableArray array];
    for (NSInteger i = 0; i < 1; i ++) {
        XHEmotionManager *emotionManager = [[XHEmotionManager alloc] init];
        emotionManager.emotionName = @"";
        NSMutableArray *emotions = [NSMutableArray array];
        for (NSInteger j = 0; j < [emotionChars length]/2; j ++) {
            XHTextEmotion* textEmotion=[[XHTextEmotion alloc] init];
            NSString* emotion=[emotionChars substringWithRange:NSMakeRange(j*2, 2)];
            textEmotion.emotion=[emotion copy];
            [emotions addObject:textEmotion];
        }
        emotionManager.emotions = emotions;
        [emotionManagers addObject:emotionManager];
    }
    return emotionManagers;
}

@end
