//
//  CDEmotionUtils.m
//  LeanChat
//
//  Created by lzw on 14/11/25.
//  Copyright (c) 2014年 LeanCloud. All rights reserved.
//

#import "CDEmotionUtils.h"
#import "XHEmotionManager.h"
#import "Emoji.h"
#import "NSString+Emojize.h"
#import "CDChatManager.h"

#define CDSupportEmojis \
@[@":smile:", \
@":laughing:", \
@":blush:", \
@":smiley:", \
@":relaxed:", \
@":smirk:", \
@":heart_eyes:", \
@":kissing_heart:", \
@":kissing_closed_eyes:", \
@":flushed:", \
@":relieved:", \
@":satisfied:", \
@":grin:", \
@":wink:", \
@":stuck_out_tongue_winking_eye:", \
@":stuck_out_tongue_closed_eyes:", \
@":grinning:", \
@":kissing:", \
@":kissing_smiling_eyes:", \
@":stuck_out_tongue:", \
@":sleeping:", \
@":worried:", \
@":frowning:", \
@":anguished:", \
@":open_mouth:", \
@":grimacing:", \
@":confused:", \
@":hushed:", \
@":expressionless:", \
@":unamused:", \
@":sweat_smile:", \
@":sweat:", \
@":disappointed_relieved:", \
@":weary:", \
@":pensive:", \
@":disappointed:", \
@":confounded:", \
@":fearful:", \
@":cold_sweat:", \
@":persevere:", \
@":cry:", \
@":sob:", \
@":joy:", \
@":astonished:", \
@":scream:", \
@":tired_face:", \
@":angry:", \
@":rage:", \
@":triumph:", \
@":sleepy:", \
@":yum:", \
@":mask:", \
@":sunglasses:", \
@":dizzy_face:", \
@":neutral_face:", \
@":no_mouth:", \
@":innocent:", \
@":thumbsup:", \
@":thumbsdown:", \
@":clap:", \
@":point_right:", \
@":point_left:" \
];

@implementation CDEmotionUtils

+ (UIImage *)imageFromString:(NSString *)string attributes:(NSDictionary *)attributes size:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [string drawInRect:CGRectMake(0, 0, size.width, size.height) withAttributes:attributes];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (NSArray *)emotionManagers {
    NSDictionary *codeToEmoji = [NSString emojiAliases];
    NSArray *emotionCodes = CDSupportEmojis;
    NSMutableArray *emotionManagers = [NSMutableArray array];
    for (NSInteger i = 0; i < 2; i++) {
        if (i == 0) {
            XHEmotionManager *emotionManager = [[XHEmotionManager alloc] init];
            CGFloat width = 30;
            emotionManager.estimatedPages = 2;
            emotionManager.emotionSize = CGSizeMake(width, width);
            emotionManager.emotionName = @"普通";
            NSMutableArray *emotions = [NSMutableArray array];
            for (NSInteger j = 0; j < emotionCodes.count; j++) {
                XHEmotion *xhEmotion = [[XHEmotion alloc] init];
                NSString *code = emotionCodes[j];
                CGFloat emojiSize = 30;
                xhEmotion.emotionConverPhoto = [self imageFromString:codeToEmoji[code] attributes:@{ NSFontAttributeName:[UIFont systemFontOfSize:25] } size:CGSizeMake(emojiSize, emojiSize)];
                xhEmotion.emotionPath = code;
                [emotions addObject:xhEmotion];
            }
            emotionManager.emotions = emotions;
            [emotionManagers addObject:emotionManager];
        } else {
            XHEmotionManager *emotionManager = [[XHEmotionManager alloc] init];
            CGFloat width = 55;
            emotionManager.emotionSize = CGSizeMake(width, width);
            emotionManager.estimatedPages = 1;
            emotionManager.emotionName = @"Gif";
            NSMutableArray *emotions = [NSMutableArray array];
            for (NSInteger j = 0; j < 16; j ++) {
                XHEmotion *emotion = [[XHEmotion alloc] init];
                NSString *imageName = [NSString stringWithFormat:@"section%ld_emotion%ld", (long)0 , (long)j];
                emotion.emotionPath = imageName;
                emotion.emotionConverPhoto = [UIImage imageNamed:imageName];
                [emotions addObject:emotion];
            }
            emotionManager.emotions = emotions;
            [emotionManagers addObject:emotionManager];
        }
    }
    return emotionManagers;
}

+ (NSString *)emojiStringFromString:(NSString *)text {
    return [self convertString:text toEmoji:YES];
}

+ (NSString *)plainStringFromEmojiString:(NSString *)emojiText {
    return [self convertString:emojiText toEmoji:NO];
}

+ (NSString *)convertString:(NSString *)text toEmoji:(BOOL)toEmoji {
    NSMutableString *emojiText = [[NSMutableString alloc] initWithString:text];
    for (NSString *code in[[NSString emojiAliases] allKeys]) {
        NSString *emoji = [NSString emojiAliases][code];
        if (toEmoji) {
            [emojiText replaceOccurrencesOfString:code withString:emoji options:NSLiteralSearch range:NSMakeRange(0, emojiText.length)];
        }
        else {
            [emojiText replaceOccurrencesOfString:emoji withString:code options:NSLiteralSearch range:NSMakeRange(0, emojiText.length)];
        }
    }
    return emojiText;
}

+ (void)saveEmotions {
    NSMutableArray *emotions = [NSMutableArray array];
    for (NSInteger j = 0; j < 16; j ++) {
        NSString *imageName = [NSString stringWithFormat:@"section%ld_emotion%ld", (long)0 , (long)j];
        NSString *path = [[NSBundle bundleForClass:[CDChatManager class]] pathForResource:[NSString stringWithFormat:@"emotion%ld",(long)j] ofType:@"gif"];
        if (path == nil) {
            [NSException raise:@"LeanChatLib" format:@"emotion path is nil"];
        }
        AVFile *file = [AVFile fileWithName:imageName contentsAtPath:path];
        AVObject *emotion = [AVObject objectWithClassName:@"Emotion"];
        [emotion setObject:imageName forKey:@"name"];
        [emotion setObject:file forKey:@"file"];
        [emotions addObject:emotion];
    }
    [AVObject saveAllInBackground:emotions block:^(BOOL succeeded, NSError *error) {
        NSLog(@"save emotions, error : %@", error);
    }];
}

+ (void)findEmotionWithName:(NSString *)name block:(AVFileResultBlock)block {
    AVQuery *query = [AVQuery queryWithClassName:@"Emotion"];
    query.cachePolicy = kAVCachePolicyCacheElseNetwork;
    [query findObjectsInBackgroundWithBlock:^(NSArray *emotions, NSError *error) {
        if (error) {
            block(nil, error);
        } else {
            for (AVObject *emotion in emotions) {
                if ([emotion[@"name"] isEqualToString:name]) {
                    block(emotion[@"file"], nil);
                    return;
                }
            }
            block(nil, [NSError errorWithDomain:@"LeanChatLib" code:0 userInfo:@{NSLocalizedDescriptionKey:@"emotion of that name not found"}]);
        }
    }];
}

@end
