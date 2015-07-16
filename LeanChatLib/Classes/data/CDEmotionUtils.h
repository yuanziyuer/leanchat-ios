//
//  CDEmotionUtils.h
//  LeanChat
//
//  Created by lzw on 14/11/25.
//  Copyright (c) 2014年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  表情工具类，提供表情、转换表情与文本
 */
@interface CDEmotionUtils : NSObject

/**
 *  获取 XHEmotionManager Array
 */
+ (NSArray *)emotionManagers;


/**
 *  :smile: 文本转换成原生表情
 */
+ (NSString *)emojiStringFromString:(NSString *)text;

/**
 *  原生表情转换成 :smile: 文本
 */
+ (NSString *)plainStringFromEmojiString:(NSString *)emojiText;

@end
