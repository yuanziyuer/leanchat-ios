//
//  CDIMClient.m
//  LeanChat
//
//  Created by lzw on 15/1/21.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDIMClient.h"

static CDIMClient*instance;
static BOOL initialized;
static NSMutableArray* _conversations;
static NSMutableArray* _messages;
static AVIM* _im;

@interface CDIMClient()<AVIMDelegate,AVIMSignatureDataSource>{
    
}
@end

@implementation CDIMClient

+ (instancetype)sharedInstance
{
    static dispatch_once_t once_token=0;
    dispatch_once(&once_token, ^{
        instance=[[CDIMClient alloc] init];
    });
    if(!initialized){
        _conversations=[NSMutableArray array];
        _messages=[NSMutableArray array];
        _im=[[AVIM alloc] init];
        _im.delegate=instance;
        //_im.signatureDataSource=instance;
        initialized=YES;
    }
    return instance;
}

-(BOOL)isOpened{
    return _im.status==AVIMStatusOpened;
}

-(void)open{
    [_im openWithClientId:[AVUser currentUser].objectId callback:^(BOOL succeeded, NSError *error) {
        [CDUtils logError:error callback:^{
            NSLog(@"im open succeed");
        }];
    }];
}

- (void)addConversation:(AVIMConversation *)conversation {
    if (conversation && ![_conversations containsObject:conversation]) {
        [_conversations addObject:conversation];
    }
}

- (void)close {
    [_conversations removeAllObjects];
    [_im closeWithCallback:nil];
    initialized = NO;
}

- (void)fetchOrCreateConversationWithUserId:(NSString *)userId callback:(AVIMConversationResultBlock)callback {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    [array addObject:_im.clientId];
    [array addObject:userId];
    [_im queryConversationsWithClientIds:array skip:0 limit:0 callback:^(NSArray *objects, NSError *error) {
        if(error){
            callback(nil,error);
        }else{
            if (objects.count > 0) {
                AVIMConversation *conversation = [objects objectAtIndex:0];
                [self addConversation:conversation];
                callback(conversation, nil);
            } else{
                [_im createConversationWithName:nil clientIds:@[userId] attributes:nil callback:^(AVIMConversation *conversation, NSError *error) {
                    [self addConversation:conversation];
                    callback(conversation,error);
                }];
            }
        }
    }];
}

- (void)queryConversationsWithCallback:(AVIMArrayResultBlock)callback {
    //todo: getConversationsFromDB
    callback(_conversations,nil);
}

- (void)updateConversation:(AVIMConversation *)conversation withName:(NSString *)name attributes:(NSDictionary *)attributes callback:(AVIMBooleanResultBlock)callback {
    AVIMConversationUpdateBuilder *builder = [conversation newUpdateBuilder];
    builder.name = name;
    builder.attributes = attributes;
    [conversation sendUpdate:[builder dictionary] callback:^(BOOL succeeded, NSError *error) {
        NSLog(@"name:%@", conversation.name);
        NSLog(@"attributes:%@", conversation.attributes);
    }];
}

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

-(void)receiveMessage:(AVIMTypedMessage*)message{
    [_messages addObject:message];
    [self postUpdatedMessage:message];
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

#pragma mark - AVIMDelegate

/*!
 当前聊天状态被暂停，常见于网络断开时触发。
 */
- (void)imPaused:(AVIM *)im{
    NSLog(@"%s",__PRETTY_FUNCTION__);
}

/*!
 当前聊天状态开始恢复，常见于网络断开后开始重新连接。
 */
- (void)imResuming:(AVIM *)im{
    NSLog(@"%s",__PRETTY_FUNCTION__);
}
/*!
 当前聊天状态已经恢复，常见于网络断开后重新连接上。
 */
- (void)imResumed:(AVIM *)im{
    NSLog(@"%s",__PRETTY_FUNCTION__);
}

/*!
 接收到新的普通消息。
 @param conversation － 所属对话
 @param message - 具体的消息
 @return None.
 */
- (void)conversation:(AVIMConversation *)conversation didReceiveCommonMessage:(AVIMMessage *)message{
    NSLog(@"%s",__PRETTY_FUNCTION__);
}

/*!
 接收到新的富媒体消息。
 @param conversation － 所属对话
 @param message - 具体的消息
 @return None.
 */
- (void)conversation:(AVIMConversation *)conversation didReceiveTypedMessage:(AVIMTypedMessage *)message{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    [self receiveMessage:message];
}

/*!
 消息已投递给对方。
 @param conversation － 所属对话
 @param message - 具体的消息
 @return None.
 */
- (void)conversation:(AVIMConversation *)conversation messageDelivered:(AVIMMessage *)message{
    NSLog(@"%s",__PRETTY_FUNCTION__);
}

/*!
 对话中有新成员加入的通知。
 @param conversation － 所属对话
 @param clientIds - 加入的新成员列表
 @param clientId - 邀请者的 id
 @return None.
 */
- (void)conversation:(AVIMConversation *)conversation membersAdded:(NSArray *)clientIds byClientId:(NSString *)clientId{
    NSLog(@"%s",__PRETTY_FUNCTION__);
}
/*!
 对话中有成员离开的通知。
 @param conversation － 所属对话
 @param clientIds - 离开的成员列表
 @param clientId - 操作者的 id
 @return None.
 */
- (void)conversation:(AVIMConversation *)conversation membersRemoved:(NSArray *)clientIds byClientId:(NSString *)clientId{
    NSLog(@"%s",__PRETTY_FUNCTION__);
}

/*!
 被邀请加入对话的通知。
 @param conversation － 所属对话
 @param clientId - 邀请者的 id
 @return None.
 */
- (void)conversation:(AVIMConversation *)conversation invitedByClientId:(NSString *)clientId{
    NSLog(@"%s",__PRETTY_FUNCTION__);
}

/*!
 从对话中被移除的通知。
 @param conversation － 所属对话
 @param clientId - 操作者的 id
 @return None.
 */
- (void)conversation:(AVIMConversation *)conversation kickedByClientId:(NSString *)clientId{
    NSLog(@"%s",__PRETTY_FUNCTION__);
}

@end
