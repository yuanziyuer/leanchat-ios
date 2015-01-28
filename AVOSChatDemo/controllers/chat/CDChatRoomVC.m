//
//  CDChatRoomController.m
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/28/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDChatRoomVC.h"
#import "QBImagePickerController.h"
#import "UIImage+Resize.h"

#import "CDGroupDetailVC.h"
#import "CDGroupAddMemberVC.h"

#import "XHDisplayTextViewController.h"
#import "XHDisplayMediaViewController.h"
#import "XHDisplayLocationViewController.h"
#import "XHContactDetailTableViewController.h"
#import "XHAudioPlayerHelper.h"

#import "CDService.h"


#define ONE_PAGE_SIZE 20

typedef void(^CDNSArrayCallback)(NSArray* objects,NSError* error);

@interface CDChatRoomVC () <UINavigationControllerDelegate,CDSessionStateProtocal> {
    NSMutableDictionary *_loadedImages;
    NSMutableDictionary *_avatars;
    NSMutableArray* _msgs;
    CDIM* im;
    UIImage* defaultAvatar;
    BOOL isLoadingMsg;
}

@property (nonatomic, strong) XHMessageTableViewCell *currentSelectedCell;

@property (nonatomic, strong) NSArray *emotionManagers;

@property (nonatomic,strong) CDSessionStateView* sessionStateView;

@property (nonatomic,assign) BOOL sessionStateViewVisiable;

@end

@implementation CDChatRoomVC

#pragma mark - life cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        // 配置输入框UI的样式
        //self.allowsSendVoice = NO;
        //self.allowsSendFace = NO;
        //self.allowsSendMultiMedia = NO;
        isLoadingMsg=NO;
        _loadedImages = [[NSMutableDictionary alloc] init];
        _avatars=[[NSMutableDictionary alloc] init];
        im=[CDIM sharedInstance];
        defaultAvatar=[UIImage imageNamed:@"default_user_avatar"];
    }
    return self;
}

-(instancetype)initWithConv:(AVIMConversation*)conv{
    self=[self init];
    [CDCacheService setCurConv:conv];
    return self;
}

+(void)chatWithUserId:(NSString*)userId fromVC:(UIViewController*)vc {
    CDIM* im=[CDIM sharedInstance];
    [im fetcgConvWithUserId:userId callback:^(AVIMConversation *conversation, NSError *error) {
        [CDUtils filterError:error callback:^{
            CDChatRoomVC *controller = [[CDChatRoomVC alloc] initWithConv:conversation];
            UINavigationController* nav=[[UINavigationController alloc] initWithRootViewController:controller];
            [vc presentViewController:nav animated:YES completion:nil];
        }];
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    AVUser* curUser=[AVUser currentUser];
    
    UIImage* _peopleImage=[CDUtils resizeImage:[UIImage imageNamed:@"chat_menu_people"] toSize:CGSizeMake(25, 25)];
    UIBarButtonItem* item=[[UIBarButtonItem alloc] initWithImage:_peopleImage style:UIBarButtonItemStyleDone target:self action:@selector(goChatGroupDetail:)];
    self.navigationItem.rightBarButtonItem=item;
    UIBarButtonItem *backBtn =[[UIBarButtonItem alloc] initWithTitle:@"返回"
                                                               style:UIBarButtonItemStyleBordered
                                                              target:nil
                                                              action:nil];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop                                                                                          target:self                                                                                          action:@selector(backPressed:)];
    [[self navigationItem] setBackBarButtonItem:backBtn];
    // 设置自身用户名
    self.messageSender = [curUser username];
    
    // 添加第三方接入数据
    NSMutableArray *shareMenuItems = [NSMutableArray array];
    NSArray *plugIcons = @[@"sharemore_pic", @"sharemore_video"];
    NSArray *plugTitle = @[@"照片", @"拍摄"];
    for (NSString *plugIcon in plugIcons) {
        XHShareMenuItem *shareMenuItem = [[XHShareMenuItem alloc] initWithNormalIconImage:[UIImage imageNamed:plugIcon] title:[plugTitle objectAtIndex:[plugIcons indexOfObject:plugIcon]]];
        [shareMenuItems addObject:shareMenuItem];
    }
   
    _emotionManagers=[CDEmotionUtils getEmotionManagers];
    self.emotionManagerView.isShowEmotionStoreButton=YES;
    [self.emotionManagerView reloadData];
    
    self.shareMenuItems = shareMenuItems;
    [self.shareMenuView reloadData];
    
    _sessionStateView=[[CDSessionStateView alloc] initWithFrame:CGRectMake(0, 64, self.messageTableView.frame.size.width, kCDSessionStateViewHight)];
    [_sessionStateView setDelegate:self];
    _sessionStateViewVisiable=NO;
    [_sessionStateView observeSessionUpdate];
}

-(AVIMConversation*)conv{
    return [CDCacheService getCurConv];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    NSNotificationCenter* center=[NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(loadMessages:) name:NOTIFICATION_MESSAGE_UPDATED object:nil];
    //[CDDatabaseService markHaveReadWithConvid:[self getConvid]];
    //[self loadMsgsIsLoadMore:NO];
    [self refreshConv];
    [self loadMessages:nil];
}

-(void)refreshConv{
    CDConvType type=[CDConv typeOfConv:self.conv];
    if(type==CDConvTypeSingle){
        NSString* otherId=[CDIMUtils getOtherIdOfConv:self.conv];
        AVUser* other=[CDCacheService lookupUser:otherId];
        self.title=other.username;
    }else{
        self.title=self.conv.name;
    }
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    NSNotificationCenter* center=[NSNotificationCenter defaultCenter];
    [center removeObserver:self name:NOTIFICATION_MESSAGE_UPDATED object:nil];
    //[CDDatabaseService markHaveReadWithConvid:[self getConvid]];
}

-(void)dealloc{
    self.emotionManagers = nil;
    [[XHAudioPlayerHelper shareInstance] setDelegate:nil];
    [CDCacheService setCurConv:nil];
}

-(void)backPressed:(id)sender{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[XHAudioPlayerHelper shareInstance] stopAudio];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - message data

-(void)cacheImageOfMsg:(AVIMImageMessage*)msg{
    if([_loadedImages objectForKey:msg.messageId]==nil){
        NSString* path=[CDFileService getPathByObjectId:msg.messageId];
        NSFileManager* fileMan=[NSFileManager defaultManager];
        if([fileMan fileExistsAtPath:path]){
            NSData* data=[fileMan contentsAtPath:path];
            UIImage* image=[UIImage imageWithData:data];
            [_loadedImages setObject:image forKey:msg.messageId];
        }else{
            NSLog(@"file not exists");
        }
    }
}

-(NSDate*)getTimestampDate:(int64_t)timestamp{
    return [NSDate dateWithTimeIntervalSince1970:timestamp/1000];
}

-(XHMessage*)getXHMessageByMsg:(AVIMTypedMessage*)msg{
    AVUser* fromUser=[CDCacheService lookupUser:msg.clientId];
    AVUser* curUser=[AVUser currentUser];
    XHMessage* xhMessage;
    NSDate* time=[self getTimestampDate:msg.sendTimestamp];
    if(msg.mediaType==kAVIMMessageMediaTypeText){
        AVIMTextMessage* textMsg=(AVIMTextMessage*)msg;
        xhMessage=[[XHMessage alloc] initWithText:[CDEmotionUtils convertWithText:textMsg.text toEmoji:YES] sender:fromUser.username timestamp:time];
    }else if(msg.mediaType==kAVIMMessageMediaTypeAudio){
        AVIMAudioMessage* audioMsg=(AVIMAudioMessage*)msg;
        NSString* duration=[NSString stringWithFormat:@"%.0f",audioMsg.duration];
        NSString* voicePath=[CDFileService getPathByObjectId:audioMsg.messageId];
        xhMessage=[[XHMessage alloc] initWithVoicePath:voicePath voiceUrl:nil voiceDuration:duration sender:fromUser.username timestamp:time];
    }else if(msg.mediaType==kAVIMMessageMediaTypeLocation){
        AVIMLocationMessage* locationMsg=(AVIMLocationMessage*)msg;
        xhMessage=[[XHMessage alloc] initWithLocalPositionPhoto:[UIImage imageNamed:@"Fav_Cell_Loc"] geolocations:@"location" location:[[CLLocation alloc] initWithLatitude:locationMsg.latitude longitude:locationMsg.longitude] sender:fromUser.username timestamp:time];
    }else if(msg.mediaType==kAVIMMessageMediaTypeImage){
        AVIMImageMessage* imageMsg=(AVIMImageMessage*)msg;
        NSLog(@"%@",imageMsg);
        NSString* url=imageMsg.file.url;
        xhMessage=[[XHMessage alloc] initWithPhoto:nil thumbnailUrl:url originPhotoUrl:url sender:fromUser.username timestamp:time];
    }
    xhMessage.avator=[_avatars objectForKey:msg.clientId];
    xhMessage.avatorUrl=nil;
    if([curUser.objectId isEqualToString:msg.clientId]){
        xhMessage.bubbleMessageType=XHBubbleMessageTypeSending;
    }else{
        xhMessage.bubbleMessageType=XHBubbleMessageTypeReceiving;
    }
    NSInteger msgStatuses[4]={AVIMMessageStatusSending,AVIMMessageStatusSent,AVIMMessageStatusDelivered,AVIMMessageStatusNone};
    NSInteger xhMessageStatuses[4]={XHMessageStatusSending,XHMessageStatusSent,XHMessageStatusReceived,XHMessageStatusFailed};
    
    if(xhMessage.bubbleMessageType==XHBubbleMessageTypeSending){
        XHMessageStatus status=XHMessageStatusReceived;
        int i;
        for(i=0;i<4;i++){
            if(msgStatuses[i]==msg.status){
                status=xhMessageStatuses[i];
                break;
            }
        }
        xhMessage.status=status;
//        if(msg.roomType==CDMsgRoomTypeGroup){
//            if(status==CDMsgStatusSendSucceed){
//                xhMessage.status=XHMessageStatusReceived;
//            }
//        }
    }else{
        xhMessage.status=XHMessageStatusReceived;
    }
    return xhMessage;
}

-(void)cacheAvatarByUserId:(NSString*)userId{
    if([_avatars objectForKey:userId]==nil){
        [_avatars setObject:defaultAvatar forKey:userId];
        
        AVUser* user=[CDCacheService lookupUser:userId];
        if(user==nil){
            [CDUtils alert:@"can not find the user"];
            return;
        }
        UIImage* avatar=[CDUserService getAvatarOfUser:user];
        [_avatars setObject:avatar forKey:userId];
    }
}

#pragma mark - next controller

- (void)goChatGroupDetail:(id)sender {
//    CDGroupDetailController *controller=[[CDGroupDetailController alloc] init];
//    controller.chatGroup=self.chatGroup;
//    [self.navigationController pushViewController: controller animated:YES];

    UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
    [flow setItemSize:CGSizeMake(240, 240)];
    [flow setScrollDirection:UICollectionViewScrollDirectionVertical];
    
    CDGroupDetailVC* controller=[[CDGroupDetailVC alloc] initWithNibName:@"CDGroupDetailController" bundle:nil];
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - messageUpdated

-(NSString*)getOtherId{
//    if(_type==CDMsgRoomTypeSingle){
//        return _chatUser.objectId;
//    }else{
//        return _chatGroup.objectId;
//    }
    return nil;
}

-(void)loadMessages:(NSNotification*)notification{
    NSArray* msgs=[im findMsgsByConvId:self.conv.conversationId];
    [self cacheMsgs:msgs callback:^(BOOL succeeded, NSError *error) {
        [CDUtils filterError:error callback:^{
            self.messages=[self getXHMessages:msgs];
            [self.messageTableView reloadData];
            [self scrollToBottomAnimated:YES];
        }];
    }];
}

- (NSArray *)getXHMessages:(NSArray *)msgs {
    NSMutableArray* messages=[[NSMutableArray alloc] init];
    for(AVIMTypedMessage* msg in msgs){
        [messages addObject:[self getXHMessageByMsg:msg]];
    }
    return messages;
}

-(void)loadMsgsIsLoadMore:(BOOL)isLoadMore{
    if(isLoadingMsg){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self loadMsgsIsLoadMore:isLoadMore];
        });
        NSLog(@"loading msg and return");
        return ;
    }
    isLoadingMsg=YES;
    NSLog(@"%s",__PRETTY_FUNCTION__);
    [CDUtils runInGlobalQueue:^{
        __block NSMutableArray* msgs;
//        FMDatabaseQueue* dbQueue=[CDDatabaseService databaseQueue];
//        [dbQueue inDatabase:^(FMDatabase *db) {
//            int64_t maxTimestamp=(((int64_t)[[NSDate date] timeIntervalSince1970])+10)*1000;
//            if(isLoadMore==NO){
//                int64_t timestamp=maxTimestamp;
//                int limit;
//                int count=[self.messages count];
//                if(count>ONE_PAGE_SIZE){
//                    limit=count;
//                }else{
//                    limit=ONE_PAGE_SIZE;
//                }
//                msgs=[self getDBMsgsWithTimestamp:timestamp limit:limit isLoadMore:isLoadMore db:db];
//            }else{
//                int64_t timestamp;
//                if([self.messages count]>0){
//                    XHMessage* firstMessage=[self.messages objectAtIndex:0];
//                    NSDate* date=firstMessage.timestamp;
//                    timestamp=[date timeIntervalSince1970]*1000;
//                }else{
//                    timestamp=maxTimestamp;
//                }
//                int limit=ONE_PAGE_SIZE;
//                msgs=[self getDBMsgsWithTimestamp:timestamp limit:limit
//                                       isLoadMore:isLoadMore db:db];
//            }
//        }];
        
        
        [self cacheAndLoadMsgs:msgs isLoadMore:isLoadMore];
    }];
}

- (void)cacheMsgs:(NSArray *)msgs callback:(AVBooleanResultBlock)callback{
    __block NSMutableSet* userIds=[[NSMutableSet alloc] init];
    for(AVIMTypedMessage* msg in msgs){
        [userIds addObject:msg.clientId];
    }
    [CDCacheService cacheUsersWithIds:userIds callback:^(NSArray *objects, NSError *error) {
        if(error){
            callback(NO,error);
        }else{
            [CDUtils runInGlobalQueue:^{
                for(NSString* userId in userIds){
                    [self cacheAvatarByUserId:userId];
                }
                for(AVIMTypedMessage* msg in msgs){
                    if(msg.mediaType==kAVIMMessageMediaTypeImage){
                        [self cacheImageOfMsg:(AVIMImageMessage*)msg];
                    }
                }
                [CDUtils runInMainQueue:^{
                    callback(YES,nil);
                }];
            }];
        }
    }];
}

- (void)cacheAndLoadMsgs:(NSMutableArray *)msgs isLoadMore:(BOOL)isLoadMore {
    [CDUtils runInMainQueue:^{
        __block NSMutableSet* userIds=[[NSMutableSet alloc] init];
        for(CDMsg* msg in msgs){
            [userIds addObject:msg.fromPeerId];
        }
        [CDCacheService cacheUsersWithIds:userIds callback:^(NSArray *objects, NSError *error) {
            if(error){
                [CDUtils alertError:error];
                isLoadingMsg=NO;
            }else{
                [CDUtils runInGlobalQueue:^{
                    for(NSString* userId in userIds){
                        [self cacheAvatarByUserId:userId];
                    }
                    [CDUtils runInMainQueue:^{
                        NSMutableArray *messages= [self getXHMessages:msgs];
                        if(isLoadMore==NO){
                            self.messages=messages;
                            _msgs=msgs;
                            [self.messageTableView reloadData];
                            [self scrollToBottomAnimated:NO];
                            isLoadingMsg=NO;
                        }else{
                            NSMutableArray* newMsgs=[NSMutableArray arrayWithArray:msgs];
                            [newMsgs addObjectsFromArray:_msgs];
                            _msgs=newMsgs;
                            [self insertOldMessages:messages completion:^{
                                isLoadingMsg=NO;
                            }];
                        }
                    }];
                }];
            }
        }];
    }];
}

-(NSString*)getConvid{
    return self.conv.conversationId;
}

-(NSMutableArray*)getDBMsgsWithTimestamp:(int64_t)timestamp limit:(int)limit isLoadMore:(BOOL)isLoadMore db:(FMDatabase*)db{
    NSString* convid=[self getConvid];
    NSMutableArray *msgs=[[CDDatabaseService getMsgsWithConvid:convid maxTimestamp:timestamp limit:limit db:db] mutableCopy];
    return msgs;
}

#pragma mark - send message

- (void)sendAttachmentWithObjectId:(NSString *)objectId type:(CDMsgType)type{
    //todo
}

-(void)sendImage:(UIImage*)image{
    NSData *imageData = UIImageJPEGRepresentation(image, 0.6);
    
    NSString* objectId=[CDUtils uuid];
    NSString* path=[CDFileService getPathByObjectId:objectId];
    NSError* error;
    [imageData writeToFile:path options:NSDataWritingAtomic error:&error];
    NSLog(@" save path=%@",path);
    if(error==nil){
        AVIMImageMessage* message=[AVIMImageMessage messageWithText:nil attachedFilePath:path attributes:nil];
        [im sendMsg:message conv:self.conv callback:^(BOOL succeeded, NSError *error) {
            NSLog(@"send succeed");
        }];
    }else{
        [CDUtils alert:@"write image to file error"];
    }
}

/*
 [self removeMessageAtIndexPath:indexPath];
 [self insertOldMessages:self.messages];
 */

#pragma mark - XHMessageTableViewCell delegate

- (void)multiMediaMessageDidSelectedOnMessage:(id<XHMessageModel>)message atIndexPath:(NSIndexPath *)indexPath onMessageTableViewCell:(XHMessageTableViewCell *)messageTableViewCell {
    UIViewController *disPlayViewController;
    switch (message.messageMediaType) {
        case XHBubbleMessageMediaTypeVideo:
        case XHBubbleMessageMediaTypePhoto: {
            DLog(@"message : %@", message.photo);
            NSLog(@"message thumbnail Url:%@",message.thumbnailUrl);
            DLog(@"message : %@", message.videoConverPhoto);
            XHDisplayMediaViewController *messageDisplayTextView = [[XHDisplayMediaViewController alloc] init];
            messageDisplayTextView.message = message;
            disPlayViewController = messageDisplayTextView;
            break;
        }
            break;
        case XHBubbleMessageMediaTypeVoice: {
            // Mark the voice as read and hide the red dot.
            //message.isRead = YES;
            //messageTableViewCell.messageBubbleView.voiceUnreadDotImageView.hidden = YES;
            
            [[XHAudioPlayerHelper shareInstance] setDelegate:self];
            if (_currentSelectedCell) {
                [_currentSelectedCell.messageBubbleView.animationVoiceImageView stopAnimating];
            }
            if (_currentSelectedCell == messageTableViewCell) {
                [messageTableViewCell.messageBubbleView.animationVoiceImageView stopAnimating];
                [[XHAudioPlayerHelper shareInstance] stopAudio];
                self.currentSelectedCell = nil;
            } else {
                self.currentSelectedCell = messageTableViewCell;
                [messageTableViewCell.messageBubbleView.animationVoiceImageView startAnimating];
                [[XHAudioPlayerHelper shareInstance] managerAudioWithFileName:message.voicePath toPlay:YES];
            }
            break;
        }
        case XHBubbleMessageMediaTypeEmotion:
            DLog(@"facePath : %@", message.emotionPath);
            break;
        case XHBubbleMessageMediaTypeLocalPosition: {
            DLog(@"facePath : %@", message.localPositionPhoto);
            XHDisplayLocationViewController *displayLocationViewController = [[XHDisplayLocationViewController alloc] init];
            displayLocationViewController.message = message;
            disPlayViewController = displayLocationViewController;
            break;
        }
        default:
            break;
    }
    if (disPlayViewController) {
        [self.navigationController pushViewController:disPlayViewController animated:YES];
    }
}

- (void)didDoubleSelectedOnTextMessage:(id<XHMessageModel>)message atIndexPath:(NSIndexPath *)indexPath {
    DLog(@"text : %@", message.text);
    XHDisplayTextViewController *displayTextViewController = [[XHDisplayTextViewController alloc] init];
    displayTextViewController.message = message;
    [self.navigationController pushViewController:displayTextViewController animated:YES];
}

- (void)didSelectedAvatorOnMessage:(id<XHMessageModel>)message atIndexPath:(NSIndexPath *)indexPath {
    DLog(@"indexPath : %@", indexPath);
//    XHContact *contact = [[XHContact alloc] init];
//    contact.contactName = [message sender];
//    
//    contact.contactIntroduction = @"自定义描述，这个需要和业务逻辑挂钩";
//    XHContactDetailTableViewController *contactDetailTableViewController = [[XHContactDetailTableViewController alloc] initWithContact:contact];
//    [self.navigationController pushViewController:contactDetailTableViewController animated:YES];
}

- (void)menuDidSelectedAtBubbleMessageMenuSelecteType:(XHBubbleMessageMenuSelecteType)bubbleMessageMenuSelecteType {
    
}

-(void)didRetrySendMessage:(id<XHMessageModel>)message atIndexPath:(NSIndexPath *)indexPath{
    CDMsg* msg=[_msgs objectAtIndex:indexPath.row];
    msg.status=CDMsgStatusSendStart;
    
    XHMessage* xhMsg=(XHMessage*)message;
    xhMsg.status=XHMessageStatusSending;
    [self.messageTableView reloadData];
    
    //NSLog(@"resend");
    //[sessionManager resendMsg:msg toPeerId:_chatUser.objectId group:_group];
}

#pragma mark - XHAudioPlayerHelper Delegate

- (void)didAudioPlayerStopPlay:(AVAudioPlayer *)audioPlayer {
    if (!_currentSelectedCell) {
        return;
    }
    [_currentSelectedCell.messageBubbleView.animationVoiceImageView stopAnimating];
    self.currentSelectedCell = nil;
}

#pragma mark - XHEmotionManagerView DataSource

- (NSInteger)numberOfEmotionManagers {
    return self.emotionManagers.count;
}

- (XHEmotionManager *)emotionManagerForColumn:(NSInteger)column {
    return [self.emotionManagers objectAtIndex:column];
}

- (NSArray *)emotionManagersAtManager {
    return self.emotionManagers;
}

#pragma mark - XHMessageTableViewController Delegate

- (BOOL)shouldLoadMoreMessagesScrollToTop {
    return YES;
}

- (void)loadMoreMessagesScrollTotop {
    //[self loadMsgsIsLoadMore:YES];
}

/**
 *  发送文本消息的回调方法
 *
 *  @param text   目标文本字符串
 *  @param sender 发送者的名字
 *  @param date   发送时间
 */
- (void)didSendText:(NSString *)text fromSender:(NSString *)sender onDate:(NSDate *)date {
    if([text length]>0){
//        [sessionManager sendMessageWithObjectId:nil
//                                        content:[CDEmotionUtils convertWithText:text toEmoji:NO]
//                                           type:CDMsgTypeText
//                                       toPeerId:self.chatUser.objectId
//                                          group:self.group];
        [im sendText:text conv:self.conv callback:^(BOOL succeeded, NSError *error) {
            [CDUtils filterError:error callback:^{
                NSLog(@"send succeed");
            }];
        }];
        [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeText];
    }
}

/**
 *  发送图片消息的回调方法
 *
 *  @param photo  目标图片对象，后续有可能会换
 *  @param sender 发送者的名字
 *  @param date   发送时间
 */
- (void)didSendPhoto:(UIImage *)photo fromSender:(NSString *)sender onDate:(NSDate *)date {
    [self sendImage:photo];
    [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypePhoto];
}

/**
 *  发送视频消息的回调方法
 *
 *  @param videoPath 目标视频本地路径
 *  @param sender    发送者的名字
 *  @param date      发送时间
 */
- (void)didSendVideoConverPhoto:(UIImage *)videoConverPhoto videoPath:(NSString *)videoPath fromSender:(NSString *)sender onDate:(NSDate *)date {
}

/**
 *  发送语音消息的回调方法
 *
 *  @param voicePath        目标语音本地路径
 *  @param voiceDuration    目标语音时长
 *  @param sender           发送者的名字
 *  @param date             发送时间
 */
- (void)didSendVoice:(NSString *)voicePath voiceDuration:(NSString *)voiceDuration fromSender:(NSString *)sender onDate:(NSDate *)date {
    AVIMAudioMessage* msg=[AVIMAudioMessage messageWithText:nil attachedFilePath:voicePath attributes:nil];
    [im sendMsg:msg conv:self.conv callback:^(BOOL succeeded, NSError *error) {
        NSString* path=[CDFileService getPathByObjectId:msg.messageId];
        NSError* error1;
        [[NSFileManager defaultManager] copyItemAtPath:voicePath toPath:path error:&error1];
        if(error1==nil){
            NSLog(@"succeed");
        }
    }];
}

/**
 *  发送第三方表情消息的回调方法
 *
 *  @param facePath 目标第三方表情的本地路径
 *  @param sender   发送者的名字
 *  @param date     发送时间
 */
- (void)didSendEmotion:(NSString *)emotion fromSender:(NSString *)sender onDate:(NSDate *)date {
    UITextView *textView=self.messageInputView.inputTextView;
    NSRange range=[textView selectedRange];
    NSMutableString* str=[[NSMutableString alloc] initWithString:textView.text];
    [str deleteCharactersInRange:range];
    [str insertString:emotion atIndex:range.location];
    textView.text=[CDEmotionUtils convertWithText:str toEmoji:YES];
    textView.selectedRange=NSMakeRange(range.location+emotion.length, 0);
    [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeEmotion];
}

- (void)didSendGeoLocationsPhoto:(UIImage *)geoLocationsPhoto geolocations:(NSString *)geolocations location:(CLLocation *)location fromSender:(NSString *)sender onDate:(NSDate *)date {
    [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeLocalPosition];
}

/**
 *  是否显示时间轴Label的回调方法
 *
 *  @param indexPath 目标消息的位置IndexPath
 *
 *  @return 根据indexPath获取消息的Model的对象，从而判断返回YES or NO来控制是否显示时间轴Label
 */
- (BOOL)shouldDisplayTimestampForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row==0){
        return YES;
    }else{
        XHMessage* msg=[self.messages objectAtIndex:indexPath.row];
        XHMessage* lastMsg=[self.messages objectAtIndex:indexPath.row-1];
        int interval=[msg.timestamp timeIntervalSinceDate:lastMsg.timestamp];
        if(interval>60*3){
            return YES;
        }else{
            return NO;
        }
    }
}

/**
 *  配置Cell的样式或者字体
 *
 *  @param cell      目标Cell
 *  @param indexPath 目标Cell所在位置IndexPath
 */
- (void)configureCell:(XHMessageTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    XHMessage* msg=[self.messages objectAtIndex:indexPath.row];
    if([self shouldDisplayTimestampForRowAtIndexPath:indexPath]){
        NSDate* ts=msg.timestamp;
        NSDateFormatter* dateFormatter=[[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM-dd HH:mm"];
        NSString* str=[dateFormatter stringFromDate:ts];
        cell.timestampLabel.text=str;
    }
    SETextView* textView=cell.messageBubbleView.displayTextView;
    if(msg.bubbleMessageType==XHBubbleMessageTypeSending){
        [textView setTextColor:[UIColor whiteColor]];
    }else{
        [textView setTextColor:[UIColor blackColor]];
    }
}

/**
 *  协议回掉是否支持用户手动滚动
 *
 *  @return 返回YES or NO
 */
- (BOOL)shouldPreventScrollToBottomWhileUserScrolling {
    return YES;
}

-(void)didSelecteShareMenuItem:(XHShareMenuItem *)shareMenuItem atIndex:(NSInteger)index{
    [super didSelecteShareMenuItem:shareMenuItem atIndex:index];
}


#pragma mark - session protocal

-(void)onSessionBrokenWithStateView:(CDSessionStateView *)view{
    if(_sessionStateViewVisiable==NO){
        _sessionStateViewVisiable=YES;
        [self.view addSubview:_sessionStateView];
        [self.view bringSubviewToFront:_sessionStateView];
    }
}

-(void)onSessionFineWithStateView:(CDSessionStateView *)view{
    if(_sessionStateViewVisiable==YES){
        _sessionStateViewVisiable=NO;
        [_sessionStateView removeFromSuperview];
    }
}

@end

