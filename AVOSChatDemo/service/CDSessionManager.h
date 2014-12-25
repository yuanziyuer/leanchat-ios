//
//  CDSessionManager.h
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/29/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDCommon.h"
#import "CDMsg.h"
#import "CDChatGroup.h"

@interface CDSessionManager : NSObject <AVSessionDelegate, AVSignatureDelegate, AVGroupDelegate>

+ (instancetype)sharedInstance;

#pragma mark - session
- (void)watchPeerId:(NSString *)peerId;

-(void)unwatchPeerId:(NSString*)peerId;

-(void)openSession;

-(void)closeSession;

#pragma mark - operation message

- (void)sendMessageWithObjectId:(NSString*)objectId content:(NSString *)content type:(CDMsgType)type toPeerId:(NSString *)toPeerId group:(AVGroup*)group;

+(NSString*)getConvidOfRoomType:(CDMsgRoomType)roomType otherId:(NSString*)otherId groupId:(NSString*)groupId;

- (void)clearData;

+(NSString*)convidOfSelfId:(NSString*)myId andOtherId:(NSString*)otherId;

+(NSString*)getPathByObjectId:(NSString*)objectId;

#pragma mark - histroy
- (void)getHistoryMessagesForPeerId:(NSString *)peerId callback:(AVArrayResultBlock)callback;

- (void)getHistoryMessagesForGroup:(NSString *)groupId callback:(AVArrayResultBlock)callback;


-(AVSession*)getSession;

@end

