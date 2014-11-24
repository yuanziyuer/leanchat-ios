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

@property NSMutableArray* friends;

#pragma conversation
- (NSArray *)chatRooms;
-(void)findConversationsWithCallback:(AVArrayResultBlock)callback;


#pragma session
- (void)watchPeerId:(NSString *)peerId;
-(void)unwatchPeerId:(NSString*)peerId;
-(void)openSession;
-(void)closeSession;

#pragma operation message
- (void)sendMessageWithType:(CDMsgType)type content:(NSString *)content  toPeerId:(NSString *)toPeerId group:(AVGroup*)group;
- (void)sendAttachmentWithObjectId:(NSString*)objectId type:(CDMsgType)type toPeerId:(NSString *)toPeerId group:(AVGroup*)group;

- (NSArray*)getMsgsForConvid:(NSString*)convid;
+(NSString*)getConvidOfRoomType:(CDMsgRoomType)roomType otherId:(NSString*)otherId groupId:(NSString*)groupId;
- (void)clearData;
+(NSString*)convidOfSelfId:(NSString*)myId andOtherId:(NSString*)otherId;
+(NSString*)getPathByObjectId:(NSString*)objectId;
+(NSString*)uuid;

#pragma histroy
- (void)getHistoryMessagesForPeerId:(NSString *)peerId callback:(AVArrayResultBlock)callback;
- (void)getHistoryMessagesForGroup:(NSString *)groupId callback:(AVArrayResultBlock)callback;

#pragma group
- (AVGroup *)joinGroupById:(NSString *)groupId;
- (void)saveNewGroupWithName:(NSString*)name withCallback:(AVGroupResultBlock)callback ;
-(void)inviteMembersToGroup:(CDChatGroup*) chatGroup userIds:(NSArray*)userIds;
-(void)kickMemberFromGroup:(CDChatGroup*)chatGroup userId:(NSString*)userId;
-(void)quitFromGroup:(CDChatGroup*)chatGroup;

#pragma user cache
- (void)registerUsers:(NSArray*)users;
- (void)registerUser:(AVUser*)user;
- (AVUser *)lookupUser:(NSString*)userId;
-(void)cacheUsersWithIds:(NSArray*)userIds callback:(AVArrayResultBlock)callback;


@end
