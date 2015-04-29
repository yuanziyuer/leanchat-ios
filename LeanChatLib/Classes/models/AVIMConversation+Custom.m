//
//  AVIMConversation+CustomAttributes.m
//  LeanChatLib
//
//  Created by lzw on 15/4/8.
//  Copyright (c) 2015年 avoscloud. All rights reserved.
//

#import "AVIMConversation+Custom.h"
#import "CDIM.h"

@implementation AVIMConversation(Custom)

-(CDConvType)type{
    return [[self.attributes objectForKey:CONV_TYPE] intValue];
}

+(NSString*)nameOfUserIds:(NSArray*)userIds{
    NSMutableArray* names=[NSMutableArray array];
    for(int i=0;i<userIds.count;i++){
        id<CDUserModel> user=[[CDIMConfig config].userDelegate getUserById:[userIds objectAtIndex:i]];
        [names addObject:user.username];
    }
    return [names componentsJoinedByString:@","];
}

-(NSString*)displayName{
    if([self type]==CDConvTypeSingle){
        NSString* otherId=[self otherId];
        id<CDUserModel> other=[[CDIMConfig config].userDelegate getUserById:otherId];
        return other.username;
    }else{
        return self.name;
    }
}

-(NSString*)otherId{
    NSArray* members=self.members;
    if(members.count!=2){
        [NSException raise:@"invalid conv" format:nil];
    }
    CDIM* im=[CDIM sharedInstance];
    if([members containsObject:im.selfId]==NO){
        [NSException raise:@"invalid conv" format:nil];
    }
    NSString* otherId;
    if([members[0] isEqualToString:im.selfId]){
        otherId=members[1];
    }else{
        otherId=members[0];
    }
    return otherId;
}

-(NSString*)title{
    if(self.type==CDConvTypeSingle){
        return self.displayName;
    }else{
        return [NSString stringWithFormat:@"%@(%ld)",self.displayName,(long)self.members.count];
    }
}

-(UIImage*)icon{
    return [self imageWithColor:[self colorFromConversationId] size:CGSizeMake(50, 50) radius:4];
}

-(UIColor*)colorFromConversationId{
    NSInteger length=self.conversationId.length;
    NSInteger partLength=length/3;
    NSString *part1,*part2,*part3;
    part1=[self.conversationId substringWithRange:NSMakeRange(0, partLength)];
    part2=[self.conversationId substringWithRange:NSMakeRange(partLength, partLength)];
    part3=[self.conversationId substringWithRange:NSMakeRange(partLength*2, partLength)];
    CGFloat hue=[self hashNumberFromString:part3]%256/256.0;
    CGFloat saturation=[self hashNumberFromString:part2]%128/256.0+0.5;
    CGFloat brightness=[self hashNumberFromString:part1]%128/256.0+0.5;
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}

-(NSUInteger)hashNumberFromString:(NSString*)string{
    NSInteger hash=string.hash;
    if(hash<0){
        return -hash;
    }else{
        return hash;
    }
}

-(UIImage*)imageWithColor:(UIColor *)color size:(CGSize)size radius:(CGFloat)radius{
    CGRect rect=CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    [[UIBezierPath bezierPathWithRoundedRect:rect
                                cornerRadius:radius] addClip];
    CGContextRef context=UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    UIImage *image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
