//
//  CDIMClient.m
//  LeanChat
//
//  Created by lzw on 15/1/21.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDIM.h"
#import "CDModels.h"
#import "CDService.h"

static CDIM*instance;
static BOOL initialized;
static NSMutableArray* _conversations;
static NSMutableArray* _messages;

@interface CDIM()<AVIMClientDelegate,AVIMSignatureDataSource>{
    
}
@end

@implementation CDIM

#pragma mark - lifecycle

+ (instancetype)sharedInstance
{
    static dispatch_once_t once_token=0;
    dispatch_once(&once_token, ^{
        instance=[[CDIM alloc] init];
    });
    if(!initialized){
        initialized=YES;
    }
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _conversations=[NSMutableArray array];
        _messages=[NSMutableArray array];
        _imClient=[[AVIMClient alloc] init];
        _imClient.delegate=self;
        //_imClient.signatureDataSource=self;
    }
    return self;
}

-(BOOL)isOpened{
    return _imClient.status==AVIMClientStatusOpened;
}

-(void)open{
    [_imClient openWithClientId:[AVUser currentUser].objectId callback:^(BOOL succeeded, NSError *error) {
        [CDUtils logError:error callback:^{
            NSLog(@"im open succeed");
        }];
    }];
}

- (void)close {
    [_conversations removeAllObjects];
    [_imClient closeWithCallback:nil];
    initialized = NO;
}

#pragma mark - conversation

- (void)addConversation:(AVIMConversation *)conversation {
    if (conversation && ![_conversations containsObject:conversation]) {
        [_conversations addObject:conversation];
    }
}

- (void)fetchOrCreateConversationWithUserId:(NSString *)userId callback:(AVIMConversationResultBlock)callback {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    [array addObject:_imClient.clientId];
    [array addObject:userId];
    [_imClient queryConversationsWithClientIds:array skip:0 limit:0 callback:^(NSArray *objects, NSError *error) {
        if(error){
            callback(nil,error);
        }else{
            AVIMConversationResultBlock withConversation=^(AVIMConversation* conversation,NSError* error){
                if(error){
                }else{
                    [self addConversation:conversation];
                    callback(conversation, nil);
                }
            };
            if (objects.count > 0) {
                AVIMConversation *conversation = [objects objectAtIndex:0];
                withConversation(conversation,nil);
            } else{
                [_imClient createConversationWithName:nil clientIds:@[userId] attributes:nil callback:withConversation];
            }
        }
    }];
}

-(AVIMTypedMessage*)getLastMsgWithConvid:(NSString*)convid{
    for(int i=_messages.count-1;i>=0;i--){
        AVIMTypedMessage* msg=[_messages objectAtIndex:i];
        if([msg.conversationId isEqualToString:convid]){
            return msg;
        }
    }
    return nil;
}

+(void)cacheRooms:(NSArray*)rooms callback:(AVArrayResultBlock)callback{
    NSMutableSet* userIds=[NSMutableSet set];
    for(CDRoom* room in rooms){
        if(room.type==CDConvTypeSingle){
            if([CDCacheService lookupUser:room.otherId]==nil){
                [userIds addObject:room.otherId];
            }
        }
    }
    [CDCacheService cacheUsersWithIds:userIds callback:callback];
}

- (void)findRoomsWithCallback:(AVArrayResultBlock)callback {
    //todo: getConversationsFromDB
    NSMutableArray* rooms=[NSMutableArray array];
    for(AVIMConversation* conv in _conversations){
        CDRoom* room=[[CDRoom alloc] init];
        room.conv=conv;
        room.unreadCount=0;
        if([conv.members count]==2){
            room.type=CDConvTypeSingle;
            room.otherId=[CDIMUtils getOtherIdOfConv:conv];
        }else{
            room.type=CDConvTypeGroup;
        }
        room.lastMsg=[self getLastMsgWithConvid:conv.conversationId];
        [rooms addObject:room];
    }
    callback(rooms,nil);
}

-(void)findGroupedConvsWithBlock:(AVArrayResultBlock)block{
    AVUser* user=[AVUser currentUser];
    NSMutableDictionary *whereDict=[NSMutableDictionary dictionary];
    NSDictionary* cond=@{@"$size":@{@"$gt":@(2)},@"$all":@[user.objectId]};
    [whereDict setObject:cond forKey:@"m"];
    [_imClient queryConversationsWithConditions:whereDict skip:0 limit:0 callback:block];
}

- (void)updateConv:(AVIMConversation *)conv name:(NSString *)name attrs:(NSDictionary *)attrs callback:(AVIMBooleanResultBlock)callback {
    AVIMConversationUpdateBuilder *builder = [conv newUpdateBuilder];
    if(name){
        builder.name = name;
    }
    if(attrs){
        builder.attributes = attrs;
    }
    [conv sendUpdate:[builder dictionary] callback:callback];
}

-(NSArray*)findMessagesByConversationId:(NSString*)convid{
    NSMutableArray* array=[[NSMutableArray alloc] init];
    for(AVIMTypedMessage* msg in _messages){
        if([msg.conversationId isEqualToString:convid]){
            [array addObject:msg];
        }
    }
    return array;
}

-(BOOL)setAttrs:(NSMutableDictionary*)attrs convType:(CDConvType)type{
    if([[attrs objectForKey:CONV_TYPE] isEqualToNumber:@(type)]==NO){
        [attrs setObject:@(type) forKey:CONV_TYPE];
        return YES;
    }
    return NO;
}

-(void)setTypeOfConv:(AVIMConversation*)conv callback:(AVBooleanResultBlock)callback{
    BOOL changed;
    NSMutableDictionary* dict=[conv.attributes mutableCopy];
    if(dict==nil){
        dict=[NSMutableDictionary dictionary];
    }
    if(conv.members.count>2){
        changed=[self setAttrs:dict convType:CDConvTypeGroup];
    }else{
        changed=[self setAttrs:dict convType:CDConvTypeSingle];
    }
    if(changed){
        [self updateConv:conv name:conv.name attrs:dict callback:callback];
    }else{
        callback(YES,nil);
    }
}

#pragma mark - send or receive message

-(void)postUpdatedMessage:(id)message{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MESSAGE_UPDATED object:message];
}

- (void)sendText:(NSString *)text conversation:(AVIMConversation *)conversation  callback:(AVIMBooleanResultBlock)callback{
    AVIMTextMessage* message=[AVIMTextMessage messageWithText:text attributes:nil];
    [self sendMessage:message conversation:conversation callback:callback];
}

-(void)sendImageWithPath:(NSString*)path conversation:(AVIMConversation*)conversation callback:(AVIMBooleanResultBlock)callback{
    AVIMImageMessage* message=[AVIMImageMessage messageWithText:nil attachedFilePath:path attributes:nil];
    [self sendMessage:message conversation:conversation callback:callback];
}

-(void)sendMessage:(AVIMTypedMessage*)message conversation:(AVIMConversation *)conversation callback:(AVIMBooleanResultBlock)callback{
    [conversation sendMessage:message callback:^(BOOL succeeded, NSError *error) {
        if(error==nil){
            [_messages addObject:message];
            [self postUpdatedMessage:message];
        }
        callback(succeeded,error);
    }];
}

-(void)receiveMessage:(AVIMTypedMessage*)msg{
    [CDUtils runInGlobalQueue:^{
        if(msg.mediaType==kAVIMMessageMediaTypeImage || msg.mediaType==kAVIMMessageMediaTypeAudio){
            NSString* path=[CDFileService getPathByObjectId:msg.messageId];
            NSFileManager* fileMan=[NSFileManager defaultManager];
            if([fileMan fileExistsAtPath:path]==NO){
                NSData* data=[msg.file getData];
                [data writeToFile:path atomically:YES];
            }
        }
        [CDUtils runInMainQueue:^{
            [_messages addObject:msg];
            [self postUpdatedMessage:msg];
        }];
    }];
}

#pragma mark - AVIMClientDelegate

/*!
 当前聊天状态被暂停，常见于网络断开时触发。
 */
- (void)imClientPaused:(AVIMClient *)imClient{
    DLog();
}

/*!
 当前聊天状态开始恢复，常见于网络断开后开始重新连接。
 */
- (void)imClientResuming:(AVIMClient *)imClient{
    DLog();
}
/*!
 当前聊天状态已经恢复，常见于网络断开后重新连接上。
 */
- (void)imClientResumed:(AVIMClient *)imClient{
    DLog();
}

#pragma mark - AVIMMessageDelegate

/*!
 接收到新的普通消息。
 @param conversation － 所属对话
 @param message - 具体的消息
 @return None.
 */
- (void)conversation:(AVIMConversation *)conversation didReceiveCommonMessage:(AVIMMessage *)message{
    DLog();
}

/*!
 接收到新的富媒体消息。
 @param conversation － 所属对话
 @param message - 具体的消息
 @return None.
 */
- (void)conversation:(AVIMConversation *)conversation didReceiveTypedMessage:(AVIMTypedMessage *)message{
    DLog();
    [self receiveMessage:message];
}

/*!
 消息已投递给对方。
 @param conversation － 所属对话
 @param message - 具体的消息
 @return None.
 */
- (void)conversation:(AVIMConversation *)conversation messageDelivered:(AVIMMessage *)message{
    DLog();
}

/*!
 对话中有新成员加入的通知。
 @param conversation － 所属对话
 @param clientIds - 加入的新成员列表
 @param clientId - 邀请者的 id
 @return None.
 */
- (void)conversation:(AVIMConversation *)conversation membersAdded:(NSArray *)clientIds byClientId:(NSString *)clientId{
    DLog();
}
/*!
 对话中有成员离开的通知。
 @param conversation － 所属对话
 @param clientIds - 离开的成员列表
 @param clientId - 操作者的 id
 @return None.
 */
- (void)conversation:(AVIMConversation *)conversation membersRemoved:(NSArray *)clientIds byClientId:(NSString *)clientId{
    DLog();
}

/*!
 被邀请加入对话的通知。
 @param conversation － 所属对话
 @param clientId - 邀请者的 id
 @return None.
 */
- (void)conversation:(AVIMConversation *)conversation invitedByClientId:(NSString *)clientId{
    DLog();
}

/*!
 从对话中被移除的通知。
 @param conversation － 所属对话
 @param clientId - 操作者的 id
 @return None.
 */
- (void)conversation:(AVIMConversation *)conversation kickedByClientId:(NSString *)clientId{
    DLog();
}

@end
