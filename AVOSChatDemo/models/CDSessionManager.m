//  CDSessionManager.m
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/29/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDSessionManager.h"
#import "FMDB.h"
#import "CDCommon.h"
#import "CDMsg.h"
#import "CDChatRoom.h"
#import "CDUtils.h"
#import "CDCloudService.h"
#import "CDChatGroup.h"
#import "CDGroupService.h"
#import "AFNetworking.h"
#import "QiniuSDK.h"

@interface CDSessionManager () {
    FMDatabase *_database;
    AVSession *_session;
    NSMutableDictionary *_cachedUsers;
    NSMutableDictionary *cachedChatGroups;
    QNUploadManager *upManager;
}

@end

#define MESSAGES @"messages"

static id instance = nil;
static BOOL initialized = NO;

static NSString *messagesTableSQL=@"create table if not exists messages (id integer primary key, objectId varchar(63) unique not null,ownerId varchar(255) not null,fromPeerId varchar(255) not null, convid varchar(255) not null,toPeerId varchar(255),content varchar(1023) ,status integer,type integer,roomType integer,readStatus integer default 1,timestamp varchar(63) not null)";

@implementation CDSessionManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    if (!initialized) {
        [instance commonInit];
    }
    return instance;
}

- (NSString *)databasePath {
    static NSString *databasePath = nil;
    if (!databasePath) {
        NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        databasePath = [cacheDirectory stringByAppendingPathComponent:@"chat.db"];
    }
    return databasePath;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)init {
    if ((self = [super init])) {
        _cachedUsers=[[NSMutableDictionary alloc] init];
        cachedChatGroups=[[NSMutableDictionary alloc] init];
        
        AVSession *session = [[AVSession alloc] init];
        session.sessionDelegate = self;
        session.signatureDelegate = self;
        _session = session;

        NSLog(@"database path:%@", [self databasePath]);
        _database = [FMDatabase databaseWithPath:[self databasePath]];
        [_database open];
        [self commonInit];
    }
    return self;
}

//if type is image ,message is attment.objectId

-(void)createTable{
    if (![_database tableExists:@"messages"]) {
        [_database executeUpdate:messagesTableSQL];
    }
}

-(void)upgradeToAddField{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    [_database executeStatements:@"drop table if exists messages"];
    [self createTable];
}

- (void)commonInit {
    [self createTable];
    upManager=[[QNUploadManager alloc] init];
    initialized = YES;
}

#pragma mark - session

-(void)openSession{
    [_session openWithPeerId:[AVUser currentUser].objectId];
}

-(void)closeSession{
    [_session close];
}

- (void)clearData {
    //[_database executeUpdate:@"DROP TABLE IF EXISTS messages"];
    [_session close];
    initialized = NO;
}

#pragma mark - single chat

- (void)watchPeerId:(NSString *)peerId {
    NSLog(@"unwatch");
    [_session watchPeerIds:@[peerId] callback:^(BOOL succeeded, NSError *error) {
        [CDUtils logError:error callback:^{
            NSLog(@"watch succeed peerId=%@",peerId);
        }];
    }];
}

-(void)unwatchPeerId:(NSString*)peerId{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    [_session unwatchPeerIds:@[peerId] callback:^(BOOL succeeded, NSError *error) {
        NSLog(@"unwatch callback");
        [CDUtils logError:error callback:^{
            NSLog(@"unwatch succeed");
        }];
    }];
}

#pragma mark - conversation

-(void)findConversationsWithCallback:(AVArrayResultBlock)callback{
    [CDUtils runInGlobalQueue:^{
        AVUser* user=[AVUser currentUser];
        FMResultSet *rs = [_database executeQuery:@"select * from messages where ownerId=? group by convid order by timestamp desc" withArgumentsInArray:@[user.objectId]];
        NSArray *msgs=[self getMsgsByResultSet:rs];
        [self cacheMsgs:msgs withCallback:^(NSArray *objects, NSError *error) {
            if(error){
                [CDUtils runInMainQueue:^{
                    callback(nil,error);
                }];
            }else{
                NSMutableArray *chatRooms=[[NSMutableArray alloc] init];
                for(CDMsg* msg in msgs){
                    CDChatRoom* chatRoom=[[CDChatRoom alloc] init];
                    chatRoom.roomType=msg.roomType;
                    FMResultSet * countResult=[_database executeQuery:@"select count(*) from messages where convid=? and readStatus=?" withArgumentsInArray:@[msg.convid,@(CDMsgReadStatusUnread)]];
                    NSInteger count=0;
                    if([countResult next]){
                        count=[countResult intForColumnIndex:0];
                    }
                    [countResult close];
                    chatRoom.unreadCount=count;
                    
                    NSString* otherId=[msg getOtherId];
                    if(msg.roomType==CDMsgRoomTypeSingle){
                        chatRoom.chatUser=[self lookupUser:otherId];;
                    }else{
                        chatRoom.chatGroup=[self lookupChatGroupById:otherId];
                    }
                    chatRoom.latestMsg=msg;
                    [chatRooms addObject:chatRoom];
                }
                [CDUtils runInMainQueue:^{
                    callback(chatRooms,error);
                }];
            }
        }];
    }];
}

+(NSString*)convidOfSelfId:(NSString*)myId andOtherId:(NSString*)otherId{
    NSArray *arr=@[myId,otherId];
    NSArray *sortedArr=[arr sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSMutableString* result= [[NSMutableString alloc] init];
    for(int i=0;i<sortedArr.count;i++){
        if(i!=0){
            [result appendString:@":"];
        }
        [result appendString:[sortedArr objectAtIndex:i]];
    }
    return [CDUtils md5OfString:result];
}


+(NSString*)uuid{
    NSString *chars=@"abcdefghijklmnopgrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    assert(chars.length==62);
    int len=chars.length;
    NSMutableString* result=[[NSMutableString alloc] init];
    for(int i=0;i<24;i++){
        int p=arc4random_uniform(len);
        NSRange range=NSMakeRange(p, 1);
        [result appendString:[chars substringWithRange:range]];
    }
    return result;
}

+(NSString*)getConvidOfRoomType:(CDMsgRoomType)roomType otherId:(NSString*)otherId groupId:(NSString*)groupId{
    if(roomType==CDMsgRoomTypeSingle){
        NSString* curUserId=[AVUser currentUser].objectId;
        return [CDSessionManager convidOfSelfId:curUserId andOtherId:otherId];
    }else{
        return groupId;
    }
}

#pragma mark - send message

-(CDMsg*)createAndSendMsgWithObjectId:(NSString*)objectId type:(CDMsgType)type content:(NSString*)content toPeerId:(NSString*)toPeerId group:(AVGroup*)group{
    CDMsg* msg=[[CDMsg alloc] init];
    msg.toPeerId=toPeerId;
    int64_t currentTime=[[NSDate date] timeIntervalSince1970]*1000;
    msg.timestamp=currentTime;
    //NSLog(@"%@",[[NSDate dateWithTimeIntervalSince1970:msg.timestamp/1000] description]);
    msg.content=content;
    NSString* curUserId=[AVUser currentUser].objectId;
    msg.fromPeerId=curUserId;
    msg.status=CDMsgStatusSendStart;
    if(!group){
        msg.toPeerId=toPeerId;
        msg.roomType=CDMsgRoomTypeSingle;
    }else{
        msg.roomType=CDMsgRoomTypeGroup;
        msg.toPeerId=@"";
    }
    msg.readStatus=CDMsgReadStatusHaveRead;
    msg.convid=[CDSessionManager getConvidOfRoomType:msg.roomType otherId:msg.toPeerId groupId:group.groupId];
    msg.objectId=objectId;
    msg.type=type;
    return [self sendMsg:msg group:group];
}

-(CDMsg*)createAndSendMsgWithType:(CDMsgType)type content:(NSString*)content toPeerId:(NSString*)toPeerId group:(AVGroup*)group{
    return [self createAndSendMsgWithObjectId:[CDSessionManager uuid] type:type content:content toPeerId:toPeerId group:group];
}

-(AVSession*)getSession{
    return _session;
}

-(CDMsg*)sendMsg:(CDMsg*)msg group:(AVGroup*)group{
    if(!group){
        AVMessage *avMsg=[AVMessage messageForPeerWithSession:_session toPeerId:msg.toPeerId payload:[msg toMessagePayload]];
        [_session sendMessage:avMsg];
    }else{
        AVMessage *avMsg=[AVMessage messageForGroup:group payload:[msg toMessagePayload]];
        [group sendMessage:avMsg];
    }
    return msg;
}

- (void)sendMessageWithType:(CDMsgType)type content:(NSString *)content  toPeerId:(NSString *)toPeerId group:(AVGroup*)group{
    CDMsg* msg=[self createAndSendMsgWithType:type content:content toPeerId:toPeerId group:group];
    [self insertMessageToDBAndNotify:msg];
}

- (void)sendMessageWithObjectId:(NSString*)objectId content:(NSString *)content type:(CDMsgType)type toPeerId:(NSString *)toPeerId group:(AVGroup*)group{
    CDMsg* msg=[self createAndSendMsgWithObjectId:objectId type:type content:content toPeerId:toPeerId group:group];
    [self insertMessageToDBAndNotify:msg];
}

-(void)runTwiceTimeWithTimes:(int)times persistentId:(NSString*)persistentId callback:(AVIdResultBlock)callback{
    NSLog(@"times=%d",times);
    NSError* commonError=[NSError errorWithDomain:@"error" code:0 userInfo:@{NSLocalizedDescriptionKey:@"上传错误"}];
    if(times>=2){
        callback(nil,commonError);
    }else{
        [CDUtils runInGlobalQueue:^{
            sleep(1);
            [CDUtils runInMainQueue:^{
                NSString *url=@"http://api.qiniu.com/status/get/prefop";
                AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
                [manager GET:url parameters:@{@"id":persistentId} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    NSDictionary* dict=(NSDictionary*)responseObject;
                    NSLog(@"%@",dict);
                    NSArray* arr=[dict objectForKey:@"items"];
                    NSDictionary* result=[arr firstObject];
                    NSString* key=[result objectForKey:@"key"];
                    NSNumber* code=[result objectForKey:@"code"];
                    int codeInt=[code intValue];
                    if(codeInt==0){
                        NSString* finalUrl=[@"http://lzw-love.qiniudn.com/" stringByAppendingString:key];
                        callback(finalUrl,nil);
                    }else{
                        [self runTwiceTimeWithTimes:times+1 persistentId:persistentId callback:callback];
                    }
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    callback(nil,error);
                }];
            }];
        }];
    }
}

-(void)sendAudioWithId:(NSString*)objectId toPeerId:(NSString*)toPeerId group:(AVGroup*)group callback:(AVBooleanResultBlock)callback{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString* path=[CDSessionManager getPathByObjectId:objectId];
    [manager GET:@"https://leanchat.avosapps.com/qiniuToken" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary* dict=(NSDictionary*)responseObject;
        NSString* token=[dict objectForKey:@"token"];
        NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
        [upManager putData:data key:objectId token:token
                  complete: ^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
                      if(info.error){
                          callback(NO,info.error);
                      }else{
                          [self runTwiceTimeWithTimes:0 persistentId:[resp objectForKey:@"persistentId"] callback:^(id object, NSError *error) {
                              if(error){
                                  callback(NO,error);
                              }else{
                                  [self sendMessageWithObjectId:objectId content:(NSString*)object type:CDMsgTypeAudio toPeerId:toPeerId group:group];
                                  callback(YES,nil);
                              }
                          }];
                      }
                  } option:nil];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        callback(NO,error);
    }];
}

+(NSString*)getFilesPath{
    NSString* appPath=[NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* filesPath=[appPath stringByAppendingString:@"/files/"];
    NSFileManager *fileMan=[NSFileManager defaultManager];
    NSError *error;
    BOOL isDir=YES;
    if([fileMan fileExistsAtPath:filesPath isDirectory:&isDir]==NO){
        [fileMan createDirectoryAtPath:filesPath withIntermediateDirectories:YES attributes:nil error:&error];
        if(error){
            [NSException raise:@"error when create dir" format:@"error"];
        }
    }
    return filesPath;
}

+(NSString*)getPathByObjectId:(NSString*)objectId{
    return [[self getFilesPath] stringByAppendingString:objectId];
}

- (void)sendAttachmentWithObjectId:(NSString*)objectId type:(CDMsgType)type toPeerId:(NSString *)toPeerId group:(AVGroup*)group{
    NSString* path=[CDSessionManager getPathByObjectId:objectId];
    AVUser* curUser=[AVUser currentUser];
    double time=[[NSDate date] timeIntervalSince1970];
    NSMutableString *name=[[curUser username] mutableCopy];
    [name appendFormat:@"%f",time];
    AVFile *f=[AVFile fileWithName:name contentsAtPath:path];
    [f saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(error){
            [CDUtils alert:[error localizedDescription]];
        }else{
            [self sendMessageWithObjectId:objectId content:f.url type:type toPeerId:toPeerId group:group];
        }
    }];
}

- (void )insertMessageToDBAndNotify:(CDMsg*)msg{
    [self insertMsgToDB:msg];
    [self notifyMessageUpdate];
}

-(void)notifyGroupUpdate{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_GROUP_UPDATED object:nil];
}

-(void)notifyMessageUpdate{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MESSAGE_UPDATED object:nil userInfo:nil];
}

#pragma mark - messages database

-(CDMsg*)insertMsgToDB:(CDMsg*)msg{
    NSDictionary *dict=[msg toDatabaseDict];
    [_database executeUpdate:@"insert into messages (objectId,ownerId , fromPeerId, toPeerId, content,convid,status,type,roomType,readStatus,timestamp) values (:objectId,:ownerId,:fromPeerId,:toPeerId,:content,:convid,:status,:type,:roomType,:readStatus,:timestamp)" withParameterDictionary:dict];
    return msg;
}

- (NSMutableArray*)getMsgsForConvid:(NSString*)convid{
    FMResultSet * rs=[_database executeQuery:@"select * from messages where convid=? order by timestamp" withArgumentsInArray:@[convid]];
    return [self getMsgsByResultSet:rs];
}

-(NSArray*)getMsgsWithConvid:(NSString*)convid maxTimestamp:(int64_t)timestamp limit:(int)limit{
    NSString* timestampStr=[[NSNumber numberWithLongLong:timestamp] stringValue];
    FMResultSet* rs=[_database executeQuery:@"select * from messages where convid=? and timestamp<? order by timestamp desc limit ?" withArgumentsInArray:@[convid,timestampStr,@(limit)]];
    NSMutableArray* msgs=[self getMsgsByResultSet:rs];
    return [CDUtils reverseArray:msgs];
}

-(int64_t)getMaxTimestampFromDB{
    FMResultSet* rs=[_database executeQuery:@"select * from messages order by timestamp desc limit 1"];
    NSArray* array=[self getMsgsByResultSet:rs];
    if([array count]>0){
        CDMsg* msg=[array firstObject];
        return msg.timestamp;
    }else{
        return -1;
    }
}

-(int64_t)getMaxTimetstamp{
    int64_t timestamp=[self getMaxTimestampFromDB];
    if(timestamp!=-1){
        return timestamp+1;
    }else{
        NSDate* now=[NSDate date];
        int sec=[now timeIntervalSince1970]+10;
        return  (int64_t)sec*1000;
    }
}

-(CDMsg* )getMsgByResultSet:(FMResultSet*)rs{
    NSString *fromid = [rs stringForColumn:FROM_PEER_ID];
    NSString *toid = [rs stringForColumn:TO_PEER_ID];
    NSString *convid=[rs stringForColumn:CONV_ID];
    NSString *objectId=[rs stringForColumn:OBJECT_ID];
    NSString* timestampText = [rs stringForColumn:TIMESTAMP];
    int64_t timestamp=[timestampText longLongValue];
    NSString* content=[rs stringForColumn:CONTENT];
    CDMsgRoomType roomType=[rs intForColumn:ROOM_TYPE];
    CDMsgType type=[rs intForColumn:TYPE];
    CDMsgStatus status=[rs intForColumn:STATUS];
    CDMsgReadStaus readStatus=[rs intForColumn:READ_STATUS];
    
    CDMsg* msg=[[CDMsg alloc] init];
    msg.fromPeerId=fromid;
    msg.objectId=objectId;
    msg.toPeerId=toid;
    msg.timestamp=timestamp;
    msg.content=content;
    msg.type=type;
    msg.status=status;
    msg.roomType=roomType;
    msg.convid=convid;
    msg.readStatus=readStatus;
    return msg;
}

-(NSMutableArray*)getMsgsByResultSet:(FMResultSet*)rs{
    NSMutableArray *result = [NSMutableArray array];
    while ([rs next]) {
        CDMsg *msg=[self getMsgByResultSet :rs];
        [result addObject:msg];
    }
    [rs close];
    return result;
}

-(void)markHaveReadOfMsgs:(NSArray*)msgs{
    BOOL hasUnread=NO;
    for(CDMsg* msg in msgs){
        if(msg.readStatus==CDMsgReadStatusUnread){
            hasUnread=YES;
            break;
        }
    }
    if(!hasUnread){
        return;
    }
    [_database beginTransaction];
    for(CDMsg* msg in msgs){
        if(msg.readStatus==CDMsgReadStatusUnread){
            msg.readStatus=CDMsgReadStatusHaveRead;
            [_database executeUpdate:@"update messages set readStatus=? where objectId=?" withArgumentsInArray:@[@(CDMsgReadStatusHaveRead),msg.objectId]];
        }
    }
    [_database commit];
}

#pragma mark - history message

- (void)getHistoryMessagesForPeerId:(NSString *)peerId callback:(AVArrayResultBlock)callback {
    AVHistoryMessageQuery *query = [AVHistoryMessageQuery queryWithFirstPeerId:_session.peerId secondPeerId:peerId];
    [query findInBackgroundWithCallback:callback];
}

- (void)getHistoryMessagesForGroup:(NSString *)groupId callback:(AVArrayResultBlock)callback {
    AVHistoryMessageQuery *query = [AVHistoryMessageQuery queryWithGroupId:groupId];
    [query findInBackgroundWithCallback:callback];
}

#pragma mark - comman message handle

-(void)messageSendFinish:(AVMessage*)avMsg group:(AVGroup*)group{
    CDMsg* msg=[CDMsg fromAVMessage:avMsg];
    [self updateMsgWithId:msg.objectId status:CDMsgStatusSendSucceed];
    [self notifyMessageUpdate];
}

-(void)messageSendFailure:(AVMessage*)avMsg group:(AVGroup*)group{
    NSString* objectId=[CDMsg getObjectIdByAVMessage:avMsg];
    [self updateMsgWithId:objectId status:CDMsgStatusSendFailed];
    [self notifyMessageUpdate];
}

-(void)didReceiveAVMessage:(AVMessage*)avMsg group:(AVGroup*)group{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    NSLog(@"payload=%@",avMsg.payload);
    CDMsg* msg=[CDMsg fromAVMessage:avMsg];
    if(group){
        msg.roomType=CDMsgRoomTypeGroup;
        msg.convid=group.groupId;
    }else{
        msg.roomType=CDMsgRoomTypeSingle;
        msg.convid=[CDSessionManager convidOfSelfId:[AVUser currentUser].objectId andOtherId:avMsg.fromPeerId];
    }
    msg.status=CDMsgStatusSendReceived;
    msg.readStatus=CDMsgReadStatusUnread;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if(msg.type==CDMsgTypeImage || msg.type==CDMsgTypeAudio){
            NSString* path=[CDSessionManager getPathByObjectId:msg.objectId];
            NSFileManager* fileMan=[NSFileManager defaultManager];
            if([fileMan fileExistsAtPath:path]==NO){
                NSData* data=[[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:msg.content]];
                NSError* error;
                [data writeToFile:path options:NSDataWritingAtomic error:&error];
                if(error==nil){
                }else{
                    NSLog(@"error when download file");
                    return ;
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self insertMessageToDBAndNotify:msg];
        });
    });
}

-(void)updateMsgWithId:(NSString*)objectId status:(CDMsgStatus)status timestamp:(int64_t)timestamp{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    [self updateMsgWithId:objectId status:status];
    NSString* timestampText=[NSString stringWithFormat:@"%lld",timestamp];
    [_database executeUpdate:@"update messages set timestamp=? where objectId=?" withArgumentsInArray:@[timestampText,objectId]];
}

-(void)updateMsgWithId:(NSString*)objectId status:(CDMsgStatus)status{
    [_database executeUpdate:@"update messages set status=? where objectId=?" withArgumentsInArray:@[@(status),objectId]];
}

#pragma mark - AVSessionDelegate
- (void)sessionOpened:(AVSession *)session {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"session:%@", session.peerId);
}

- (void)sessionPaused:(AVSession *)session {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"session:%@", session.peerId);
}

- (void)sessionResumed:(AVSession *)session {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"session:%@", session.peerId);
}

- (void)session:(AVSession *)session didReceiveMessage:(AVMessage *)message {
    [self didReceiveAVMessage:message group:nil];
}

- (void)session:(AVSession *)session messageSendFailed:(AVMessage *)message error:(NSError *)error {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"session:%@ message:%@ toPeerId:%@ error:%@", session.peerId, message.payload, message.toPeerId, error);
    [self messageSendFailure:message group:nil];
}

- (void)session:(AVSession *)session messageSendFinished:(AVMessage *)message {
    [self messageSendFinish:message group:nil];
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"session:%@ message:%@ toPeerId:%@", session.peerId, message.payload, message.toPeerId);
}

- (void)session:(AVSession *)session didReceiveStatus:(AVPeerStatus)status peerIds:(NSArray *)peerIds {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"session:%@ peerIds:%@ status:%@", session.peerId, peerIds, status==AVPeerStatusOffline?@"offline":@"online");
}

- (void)sessionFailed:(AVSession *)session error:(NSError *)error {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"session:%@ error:%@", session.peerId, error);
}


#pragma mark - AVGroupDelegate

- (void)group:(AVGroup *)group didReceiveMessage:(AVMessage *)message {
    [self didReceiveAVMessage:message group:group];
    //[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SESSION_UPDATED object:group.session userInfo:nil];

}

- (void)group:(AVGroup *)group didReceiveEvent:(AVGroupEvent)event peerIds:(NSArray *)peerIds {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"group:%@ event:%u peerIds:%@", group.groupId, event, peerIds);
}

- (void)group:(AVGroup *)group messageSendFinished:(AVMessage *)message {
    [self messageSendFinish:message group:group];
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"group:%@ message:%@", group.groupId, message.payload);
}

- (void)group:(AVGroup *)group messageSendFailed:(AVMessage *)message error:(NSError *)error {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"group:%@ message:%@ error:%@", group.groupId, message.payload, error);

}

- (void)session:(AVSession *)session group:(AVGroup *)group messageSent:(NSString *)message success:(BOOL)success {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"group:%@ message:%@ success:%d", group.groupId, message, success);
}

#pragma mark - end of interface

-(NSString*)getPeerId:(AVUser*)user{
    return user.objectId;
}

#pragma mark - group

-(void)inviteMembersToGroup:(CDChatGroup*) chatGroup userIds:(NSArray*)userIds callback:(AVArrayResultBlock)callback {
    AVGroup* group=[self getGroupById:chatGroup.objectId];
    [group invitePeerIds:userIds callback:callback];
}

-(void)kickMemberFromGroup:(CDChatGroup*)chatGroup userId:(NSString*)userId{
    AVGroup* group=[self getGroupById:chatGroup.objectId];
    NSMutableArray* arr=[[NSMutableArray alloc] init];
    [arr addObject:userId];
    [group kickPeerIds:arr];
}

-(void)quitFromGroup:(CDChatGroup*)chatGroup{
    AVGroup* group=[self getGroupById:chatGroup.objectId];
    [group quit];
}

-(AVGroup*)getGroupById:(NSString*)groupId{
    return [AVGroup getGroupWithGroupId:groupId session:_session];
}

- (AVGroup *)joinGroupById:(NSString *)groupId {
    AVGroup *group = [self getGroupById:groupId];
    group.delegate = self;
    [group join];
    return group;
}

- (void)saveNewGroupWithName:(NSString*)name withCallback:(AVGroupResultBlock)callback {
    [AVGroup createGroupWithSession:_session groupDelegate:self callback:^(AVGroup *group, NSError *error) {
        if(error==nil){
            [CDCloudService saveChatGroupWithId:group.groupId name:name callback:^(id object, NSError *error) {
                callback(group,error);
            }];
        }else{
            callback(group,error);
        }
    }];
}

-(void)refreshCurrentChatGroup:(AVBooleanResultBlock)callback{
    if(self.currentChatGroup!=nil){
        [self.currentChatGroup fetchInBackgroundWithBlock:^(AVObject *object, NSError *error) {
            if(error){
                callback(NO,error);
            }else{
                [self notifyGroupUpdate];
                callback(YES,nil);
            }
        }];
    }else{
        callback(NO,[NSError errorWithDomain:nil code:0 userInfo:@{NSLocalizedDescriptionKey:@"currentChatGroup is nil"}]);
    }
}

#pragma mark - cache

-(void)cacheMsgs:(NSArray*)msgs withCallback:(AVArrayResultBlock)callback{
    NSMutableSet* userIds=[[NSMutableSet alloc] init];
    NSMutableSet* groupIds=[[NSMutableSet alloc] init];
    for(CDMsg* msg in msgs){
        if(msg.roomType==CDMsgRoomTypeSingle){
            [userIds addObject:msg.fromPeerId];
            [userIds addObject:msg.toPeerId];
        }else{
            [userIds addObject:msg.fromPeerId];
            [groupIds addObject:msg.convid];
        }
    }
    [self cacheUsersWithIds:[NSMutableArray arrayWithArray:[userIds allObjects]] callback:^(NSArray *objects, NSError *error) {
        if(error){
            callback(objects,error);
        }else{
            [self cacheChatGroupsWithIds:groupIds withCallback:callback];
        }
    }];
}

-(void)cacheUsersWithIds:(NSMutableArray*)userIds callback:(AVArrayResultBlock)callback{
    NSMutableSet* uncachedUserIds=[[NSMutableSet alloc] init];
    for(NSString* userId in userIds){
        if([self lookupUser:userId]==nil){
            [uncachedUserIds addObject:userId];
        }
    }
    if([uncachedUserIds count]>0){
        [CDUserService findUsersByIds:[[NSMutableArray alloc] initWithArray:[uncachedUserIds allObjects]] callback:^(NSArray *objects, NSError *error) {
            if(objects){
                [self registerUsers:objects];
            }
            callback(objects,error);
        }];
    }else{
        callback([[NSMutableArray alloc] init],nil);
    }
}

#pragma mark - user cache

- (void)registerUsers:(NSArray*)users{
    for(int i=0;i<users.count;i++){
        [self registerUser:[users objectAtIndex:i]];
    }
}

-(void) registerUser:(AVUser*)user{
    [_cachedUsers setObject:user forKey:user.objectId];
}

-(AVUser *)lookupUser:(NSString*)userId{
    return [_cachedUsers valueForKey:userId];
}

#pragma mark - group cache

-(CDChatGroup*)lookupChatGroupById:(NSString*)groupId{
    return [cachedChatGroups valueForKey:groupId];
}

-(void)registerChatGroup:(CDChatGroup*)chatGroup{
    [cachedChatGroups setObject:chatGroup forKey:chatGroup.objectId];
}

-(void)cacheChatGroupsWithIds:(NSMutableSet*)groupIds withCallback:(AVArrayResultBlock)callback{
    NSMutableSet* uncacheGroupIds=[[NSMutableSet alloc] init];
    for(NSString * groupId in groupIds){
        if([self lookupChatGroupById:groupId]==nil){
            [uncacheGroupIds addObject:groupId];
        }
    }
    if([uncacheGroupIds count]>0){
        [CDGroupService findGroupsByIds:uncacheGroupIds withCallback:^(NSArray *objects, NSError *error) {
            [CDUtils filterError:error callback:^{
                for(CDChatGroup* chatGroup in objects){
                    [self registerChatGroup:chatGroup];
                }
                callback(objects,error);
            }];
        }];
    }else{
        callback([[NSMutableArray alloc] init],nil);
    }
}

#pragma mark - signature

//- (AVSignature *)signatureForPeerWithPeerId:(NSString *)peerId watchedPeerIds:(NSArray *)watchedPeerIds action:(NSString *)action{
//    if(watchedPeerIds==nil){
//        watchedPeerIds=[[NSMutableArray alloc] init];
//    }
//    NSDictionary* result=[CDCloudService signWithPeerId:peerId watchedPeerIds:watchedPeerIds];
//    return [self getAVSignatureWithParams:result peerIds:watchedPeerIds];
//}
//
//-(AVSignature*)getAVSignatureWithParams:(NSDictionary*) fields peerIds:(NSArray*)peerIds{
//    AVSignature* avSignature=[[AVSignature alloc] init];
//    NSNumber* timestampNum=[fields objectForKey:@"timestamp"];
//    long timestamp=[timestampNum longValue];
//    NSString* nonce=[fields objectForKey:@"nonce"];
//    NSString* signature=[fields objectForKey:@"signature"];
//    
//    [avSignature setTimestamp:timestamp];
//    [avSignature setNonce:nonce];
//    [avSignature setSignature:signature];;
//    [avSignature setSignedPeerIds:[peerIds copy]];
//    return avSignature;
//}
//
//-(AVSignature*)signatureForGroupWithPeerId:(NSString *)peerId groupId:(NSString *)groupId groupPeerIds:(NSArray *)groupPeerIds action:(NSString *)action{
//    NSDictionary* result=[CDCloudService groupSignWithPeerId:peerId groupId:groupId groupPeerIds:groupPeerIds action:action];
//    return [self getAVSignatureWithParams:result peerIds:groupPeerIds];
//}

@end
