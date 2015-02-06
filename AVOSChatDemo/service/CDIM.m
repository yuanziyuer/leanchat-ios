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

@interface CDIM()<AVIMClientDelegate,AVIMSignatureDataSource>{
    
}

@property CDStorage* storage;

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
        _imClient=[[AVIMClient alloc] init];
        _imClient.delegate=self;
        _storage=[CDStorage sharedInstance];
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
    [_imClient closeWithCallback:nil];
    initialized = NO;
}

#pragma mark - conversation

-(void)fecthConvWithId:(NSString*)convid callback:(AVIMConversationResultBlock)callback{
    [_imClient queryConversationById:convid callback:callback];
}

- (void)fetchConvWithUserId:(NSString *)userId callback:(AVIMConversationResultBlock)callback {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    [array addObject:_imClient.clientId];
    [array addObject:userId];
    [_imClient queryConversationsWithClientIds:array skip:0 limit:0 callback:^(NSArray *objects, NSError *error) {
        if(error){
            callback(nil,error);
        }else{
            AVIMConversationResultBlock WithConv=^(AVIMConversation* conv,NSError* error){
                if(error){
                }else{
                    callback(conv, nil);
                }
            };
            if (objects.count > 0) {
                AVIMConversation *conv = [objects objectAtIndex:0];
                WithConv(conv,nil);
            } else{
                [self createConvWithUserId:userId callback:WithConv];
            }
        }
    }];
}

-(void)createConvWithUserId:(NSString*)userId callback:(AVIMConversationResultBlock)callback{
    [_imClient createConversationWithName:nil clientIds:@[userId] attributes:@{CONV_TYPE:@(CDConvTypeSingle)} callback:callback];
}

-(void)createConvWithUserIds:(NSArray*)userIds callback:(AVIMConversationResultBlock)callback{
    NSString* name=[CDConvService nameOfUserIds:userIds];
    [_imClient createConversationWithName:name clientIds:userIds attributes:@{CONV_TYPE:@(CDConvTypeGroup)} callback:callback];
}

-(void)findGroupedConvsWithBlock:(AVArrayResultBlock)block{
    NSDictionary* attrs=@{CONV_TYPE:@(CDConvTypeGroup)};
    [_imClient queryConversationsWithName:nil andAttributes:attrs skip:0 limit:0 callback:block];
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

-(void)fetchConvsWithIds:(NSSet*)convids callback:(AVIMArrayResultBlock)callback{
    if(convids.count>0){
        [_imClient queryConversationByIds:[convids allObjects] callback:callback];
    }else{
        callback([NSMutableArray array],nil);
    }
}

#pragma mark - send or receive message

-(void)postUpdatedMsg:(id)msg{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MESSAGE_UPDATED object:msg];
}

-(void)receiveMsg:(AVIMTypedMessage*)msg conv:(AVIMConversation*)conv{
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
            [_storage insertRoomWithConvid:conv.conversationId];
            [_storage insertMsg:msg];
            [_storage incrementUnreadWithConvid:conv.conversationId];
            [self postUpdatedMsg:msg];
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
    if(message.messageId){
        [self receiveMsg:message conv:conversation];
    }
}

/*!
 消息已投递给对方。
 @param conversation － 所属对话
 @param message - 具体的消息
 @return None.
 */
- (void)conversation:(AVIMConversation *)conversation messageDelivered:(AVIMMessage *)message{
    [_storage updateStatus:AVIMMessageStatusDelivered byMsgId:message.messageId];
    [self postUpdatedMsg:message];
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
