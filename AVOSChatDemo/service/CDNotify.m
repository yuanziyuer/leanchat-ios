//
//  CDNotification.m
//  LeanChat
//
//  Created by lzw on 15/2/5.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDNotify.h"

@interface CDNotify (){
    
}

@property NSNotificationCenter* center;

@end

static CDNotify* _notify;

@implementation CDNotify

+(instancetype)sharedInstance{
    if(_notify==nil){
        _notify=[[CDNotify alloc] init];
    }
    return _notify;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _center=[NSNotificationCenter defaultCenter];
    }
    return self;
}

-(void)addConvObserver:(id)target selector:(SEL)selector{
    [_center addObserver:target selector:selector name:NOTIFICATION_CONV_UPDATED object:nil];
}

-(void)removeConvObserver:(id)target{
    [_center removeObserver:target name:NOTIFICATION_CONV_UPDATED object:nil];
}

-(void)postConvNotify{
    [_center postNotificationName:NOTIFICATION_CONV_UPDATED object:nil];
}

@end
