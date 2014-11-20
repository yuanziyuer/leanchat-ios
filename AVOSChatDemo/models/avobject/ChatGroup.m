//
//  ChatGroup.m
//  AVOSChatDemo
//
//  Created by lzw on 14/11/6.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "ChatGroup.h"

@implementation ChatGroup

@dynamic owner;
@dynamic name;
@dynamic m;

+(NSString*)parseClassName{
    return @"AVOSRealtimeGroups";
}

-(NSString*)getTitle{
    int cnt=self.m.count;
    return [NSString stringWithFormat:@"%@(%d)",self.name,cnt];
}
@end
