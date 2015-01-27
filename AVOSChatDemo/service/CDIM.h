//
//  CDIMClient.h
//  LeanChat
//
//  Created by lzw on 15/1/21.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDCommon.h"

@interface CDIM : NSObject

@property AVIMClient* imClient;

+ (instancetype)sharedInstance;

-(void)open;

-(BOOL)isOpened;

- (void)close;

- (void)fetchOrCreateConversationWithUserId:(NSString *)userId callback:(AVIMConversationResultBlock)callback ;

- (void)findRoomsWithCallback:(AVArrayResultBlock)callback;

-(void)findGroupedConvsWithBlock:(AVArrayResultBlock)block;

-(void)setTypeOfConv:(AVIMConversation*)conv callback:(AVBooleanResultBlock)callback;

- (void)sendText:(NSString *)text conversation:(AVIMConversation *)conversation  callback:(AVIMBooleanResultBlock)callback;

-(void)sendMessage:(AVIMTypedMessage*)message conversation:(AVIMConversation *)conversation callback:(AVIMBooleanResultBlock)callback;

-(NSArray*)findMessagesByConversationId:(NSString*)convid;

@end
