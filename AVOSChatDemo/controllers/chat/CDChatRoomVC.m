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

#import "CDConvDetailVC.h"
#import "CDAddMemberVC.h"

#import "XHDisplayTextViewController.h"
#import "XHDisplayMediaViewController.h"
#import "XHDisplayLocationViewController.h"
#import "XHContactDetailTableViewController.h"
#import "XHAudioPlayerHelper.h"

#import "CDService.h"

#define ONE_PAGE_SIZE 20

typedef void(^CDNSArrayCallback)(NSArray* objects,NSError* error);

@interface CDChatRoomVC () <UINavigationControllerDelegate,CDSessionStateProtocal>

@property CDStorage* storage;

@property NSMutableDictionary* loadedImages;

@property NSMutableDictionary* avatars;

@property NSMutableArray* msgs;

@property CDIM* im;

@property CDNotify* notify;

@property BOOL isLoadingMsg;

@property UIImage* defaultAvatar;

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
        _isLoadingMsg=NO;
        _loadedImages = [[NSMutableDictionary alloc] init];
        _avatars=[[NSMutableDictionary alloc] init];
        _im=[CDIM sharedInstance];
        _notify=[CDNotify sharedInstance];
        _storage=[CDStorage sharedInstance];
        _defaultAvatar=[UIImage imageNamed:@"default_user_avatar"];
    }
    return self;
}

-(instancetype)initWithConv:(AVIMConversation*)conv{
    self=[self init];
    [CDCache setCurConv:conv];
    return self;
}

+(void)goWithUserId:(NSString*)userId fromVC:(UIViewController*)vc {
    CDIM* im=[CDIM sharedInstance];
    [im fetchConvWithUserId:userId callback:^(AVIMConversation *conversation, NSError *error) {
        [CDUtils filterError:error callback:^{
            CDChatRoomVC *controller = [[CDChatRoomVC alloc] initWithConv:conversation];
            UINavigationController* nav=[[UINavigationController alloc] initWithRootViewController:controller];
            [vc presentViewController:nav animated:YES completion:nil];
        }];
    }];
}

-(void)initBarButton{
    UIImage* _peopleImage=[CDUtils resizeImage:[UIImage imageNamed:@"chat_menu_people"] toSize:CGSizeMake(25, 25)];
    UIBarButtonItem* item=[[UIBarButtonItem alloc] initWithImage:_peopleImage style:UIBarButtonItemStyleDone target:self action:@selector(goChatGroupDetail:)];
    self.navigationItem.rightBarButtonItem=item;
    UIBarButtonItem *backBtn =[[UIBarButtonItem alloc] initWithTitle:@"返回"
                                                               style:UIBarButtonItemStyleBordered
                                                              target:nil
                                                              action:nil];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop                                                                                          target:self                                                                                          action:@selector(backPressed:)];
    [[self navigationItem] setBackBarButtonItem:backBtn];
}

-(void)initSessionStateView{
    _sessionStateView=[[CDSessionStateView alloc] initWithFrame:CGRectMake(0, 64, self.messageTableView.frame.size.width, kCDSessionStateViewHight)];
    [_sessionStateView setDelegate:self];
    _sessionStateViewVisiable=NO;
    [_sessionStateView observeSessionUpdate];
}

-(void)initBottomMenuAndEmotionView{
    NSMutableArray *shareMenuItems = [NSMutableArray array];
    NSArray *plugIcons = @[@"sharemore_pic", @"sharemore_video"];
    NSArray *plugTitle = @[@"照片", @"拍摄"];
    for (NSString *plugIcon in plugIcons) {
        XHShareMenuItem *shareMenuItem = [[XHShareMenuItem alloc] initWithNormalIconImage:[UIImage imageNamed:plugIcon] title:[plugTitle objectAtIndex:[plugIcons indexOfObject:plugIcon]]];
        [shareMenuItems addObject:shareMenuItem];
    }
    self.shareMenuItems = shareMenuItems;
    [self.shareMenuView reloadData];
    
    _emotionManagers=[CDEmotionUtils getEmotionManagers];
    self.emotionManagerView.isShowEmotionStoreButton=YES;
    [self.emotionManagerView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initBarButton];
    [self initBottomMenuAndEmotionView];
    [self initSessionStateView];
    
    AVUser* curUser=[AVUser currentUser];
    // 设置自身用户名
    self.messageSender = [curUser username];
    
    [_storage insertRoomWithConvid:self.conv.conversationId];
    [_storage clearUnreadWithConvid:self.conv.conversationId];
    [_notify addConvObserver:self selector:@selector(refreshConv)];
}

-(AVIMConversation*)conv{
    return [CDCache getCurConv];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [_notify addMsgObserver:self selector:@selector(loadMsg:)];
    [self refreshConv];
    [self loadMsgsWithLoadMore:NO];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [_notify removeMsgObserver:self];
    [[XHAudioPlayerHelper shareInstance] stopAudio];
}

-(void)dealloc{
    self.emotionManagers = nil;
    [[XHAudioPlayerHelper shareInstance] setDelegate:nil];
    [CDCache setCurConv:nil];
    [_notify removeConvObserver:self];
}

#pragma mark - prev and next controller

- (void)goChatGroupDetail:(id)sender {
    CDConvDetailVC* controller=[[CDConvDetailVC alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

-(void)backPressed:(id)sender{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - message data

-(void)loadMsg:(NSNotification*)notification{
    [self loadMsgsWithLoadMore:NO];
}

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
    AVUser* fromUser=[CDCache lookupUser:msg.clientId];
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
    }else{
        DLog();
    }
    xhMessage.avator=[_avatars objectForKey:msg.clientId];
    xhMessage.avatorUrl=nil;
    if([curUser.objectId isEqualToString:msg.clientId]){
        xhMessage.bubbleMessageType=XHBubbleMessageTypeSending;
    }else{
        xhMessage.bubbleMessageType=XHBubbleMessageTypeReceiving;
    }
    NSInteger msgStatuses[4]={AVIMMessageStatusSending,AVIMMessageStatusSent,AVIMMessageStatusDelivered,AVIMMessageStatusFailed};
    NSInteger xhMessageStatuses[4]={XHMessageStatusSending,XHMessageStatusSent,XHMessageStatusReceived,XHMessageStatusFailed};
    
    if([CDConvService typeOfConv:self.conv]==CDConvTypeGroup){
        if(msg.status==AVIMMessageStatusSent){
            msg.status=AVIMMessageStatusDelivered;
        }
    }
    
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
    }else{
        xhMessage.status=XHMessageStatusReceived;
    }
    return xhMessage;
}

-(void)cacheAvatarByUserId:(NSString*)userId{
    if([_avatars objectForKey:userId]==nil){
        [_avatars setObject:_defaultAvatar forKey:userId];
        
        AVUser* user=[CDCache lookupUser:userId];
        if(user==nil){
            [CDUtils alert:@"can not find the user"];
            return;
        }
        UIImage* avatar=[CDUserService getAvatarOfUser:user];
        [_avatars setObject:avatar forKey:userId];
    }
}

-(void)refreshConv{
    NSString* name=[CDConvService nameOfConv:self.conv];
    if([CDConvService typeOfConv:self.conv]==CDConvTypeGroup){
        name=[NSString stringWithFormat:@"%@(%d)",name,self.conv.members.count];
    }
    self.title=name;
}

- (NSArray *)getXHMessages:(NSArray *)msgs {
    NSMutableArray* messages=[[NSMutableArray alloc] init];
    for(CDMsg* msg in msgs){
        XHMessage* xhMsg=[self getXHMessageByMsg:msg.innerMsg];
        if(xhMsg){
            [messages addObject:xhMsg];
        }
    }
    return messages;
}

-(void)loadMsgsWithLoadMore:(BOOL)isLoadMore{
    if(_isLoadingMsg){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self loadMsgsWithLoadMore:isLoadMore];
        });
        NSLog(@"loading msg and return");
        return ;
    }
    _isLoadingMsg=YES;
    DLog();
    [CDUtils runInGlobalQueue:^{
        __block NSMutableArray* msgs;
        FMDatabaseQueue* dbQueue=[_storage getDBQueue];
        [dbQueue inDatabase:^(FMDatabase *db) {
            int64_t maxTimestamp=(((int64_t)[[NSDate date] timeIntervalSince1970])+10)*1000;
            int64_t timestamp;
            int limit;
            NSString* convid=self.conv.conversationId;
            if(isLoadMore==NO){
                timestamp=maxTimestamp;
                int count=[_msgs count];
                if(count>ONE_PAGE_SIZE){
                    // more than one page msgs, get that many msgs
                    limit=count;
                }else{
                    limit=ONE_PAGE_SIZE;
                }
            }else{
                if([self.messages count]>0){
                    XHMessage* firstMsg=[self.messages objectAtIndex:0];
                    NSDate* date=firstMsg.timestamp;
                    timestamp=[date timeIntervalSince1970]*1000;
                }else{
                    timestamp=maxTimestamp;
                }
                limit=ONE_PAGE_SIZE;
            }
            msgs=[[_storage getMsgsWithConvid:convid maxTime:timestamp limit:limit db:db] mutableCopy];
        }];
        
        [self cacheMsgs:msgs callback:^(BOOL succeeded, NSError *error) {
            [CDUtils runInMainQueue:^{
                if([CDUtils filterError:error]){
                    NSMutableArray *xhMsgs= [[self getXHMessages:msgs] mutableCopy];
                    if(isLoadMore==NO){
                        self.messages=xhMsgs;
                        _msgs=msgs;
                        [self.messageTableView reloadData];
                        [self scrollToBottomAnimated:NO];
                        _isLoadingMsg=NO;
                    }else{
                        NSMutableArray* newMsgs=[NSMutableArray arrayWithArray:msgs];
                        [newMsgs addObjectsFromArray:_msgs];
                        _msgs=newMsgs;
                        [self insertOldMessages:xhMsgs completion:^{
                            _isLoadingMsg=NO;
                        }];
                    }
                }
            }];
        }];
    }];
}

- (void)cacheMsgs:(NSArray *)msgs callback:(AVBooleanResultBlock)callback{
    __block NSMutableSet* userIds=[[NSMutableSet alloc] init];
    for(CDMsg* msg in msgs){
        [userIds addObject:msg.innerMsg.clientId];
        if(msg.innerMsg.mediaType==kAVIMMessageMediaTypeImage ||
           msg.innerMsg.mediaType==kAVIMMessageMediaTypeAudio){
            NSString* path=[CDFileService getPathByObjectId:msg.innerMsg.messageId];
            NSFileManager* fileMan=[NSFileManager defaultManager];
            if([fileMan fileExistsAtPath:path]==NO){
                NSData* data=[msg.innerMsg.file getData];
                [data writeToFile:path atomically:YES];
            }
        }
    }
    [CDCache cacheUsersWithIds:userIds callback:^(NSArray *objects, NSError *error) {
        if(error){
            callback(NO,error);
        }else{
            for(NSString* userId in userIds){
                [self cacheAvatarByUserId:userId];
            }
            for(CDMsg* msg in msgs){
                if(msg.innerMsg.mediaType==kAVIMMessageMediaTypeImage){
                    [self cacheImageOfMsg:(AVIMImageMessage*)msg.innerMsg];
                }
            }
            callback(YES,nil);
        }
    }];
}

#pragma mark - send message

- (void)sendFileMsgWithPath:(NSString*)path type:(AVIMMessageMediaType)type{
    AVIMTypedMessage* msg;
    if(type==kAVIMMessageMediaTypeImage){
        msg=[AVIMImageMessage messageWithText:nil attachedFilePath:path attributes:nil];
    }else{
        msg=[AVIMAudioMessage messageWithText:nil attachedFilePath:path attributes:nil];
    }
    [self sendMsg:msg originFilePath:path];
}

-(void)sendImage:(UIImage*)image{
    NSData *imageData = UIImageJPEGRepresentation(image, 0.6);
    NSString* path=[CDFileService tmpPath];
    NSError* error;
    [imageData writeToFile:path options:NSDataWritingAtomic error:&error];
    if(error==nil){
        [self sendFileMsgWithPath:path type:kAVIMMessageMediaTypeImage];
    }else{
        [CDUtils alert:@"write image to file error"];
    }
}

-(void)sendMsg:(AVIMTypedMessage*)msg originFilePath:(NSString*)path{
    [self.conv sendMessage:msg options:AVIMMessageSendOptionRequestReceipt callback:^(BOOL succeeded, NSError *error) {
        if(error){
            msg.messageId=[CDUtils uuid];
            msg.sendTimestamp=[[NSDate date] timeIntervalSince1970]*1000;
        }
        if(path && error==nil){
            NSString* newPath=[CDFileService getPathByObjectId:msg.messageId];
            NSError* error1;
            [[NSFileManager defaultManager] moveItemAtPath:path toPath:newPath error:&error1];
        }
        [_storage insertMsg:msg];
        [self loadMsgsWithLoadMore:NO];
    }];
}

-(void)resendMsg:(CDMsg*)msg{
    [self.conv sendMessage:msg.innerMsg options:AVIMMessageSendOptionRequestReceipt callback:^(BOOL succeeded, NSError *error) {
        if(error){
        }else{
            [_storage updateFailedMsg:msg.innerMsg byLocalId:msg.localId];
        }
        [self loadMsgsWithLoadMore:NO];
    }];
}

#pragma mark - XHMessageTableViewCell delegate

- (void)multiMediaMessageDidSelectedOnMessage:(id<XHMessageModel>)message atIndexPath:(NSIndexPath *)indexPath onMessageTableViewCell:(XHMessageTableViewCell *)messageTableViewCell {
    UIViewController *disPlayViewController;
    switch (message.messageMediaType) {
        case XHBubbleMessageMediaTypeVideo:
        case XHBubbleMessageMediaTypePhoto: {
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
//    contact.contactIntroduction = @"自定义描述，这个需要和业务逻辑挂钩";
//    XHContactDetailTableViewController *contactDetailTableViewController = [[XHContactDetailTableViewController alloc] initWithContact:contact];
//    [self.navigationController pushViewController:contactDetailTableViewController animated:YES];
}

- (void)menuDidSelectedAtBubbleMessageMenuSelecteType:(XHBubbleMessageMenuSelecteType)bubbleMessageMenuSelecteType {
    
}

-(void)didRetrySendMessage:(id<XHMessageModel>)message atIndexPath:(NSIndexPath *)indexPath{
    CDMsg* msg=[_msgs objectAtIndex:indexPath.row];
    XHMessage* xhMsg=(XHMessage*)message;
    xhMsg.status=XHMessageStatusSending;
    [self.messageTableView reloadData];
    [self resendMsg:msg];
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
    [self loadMsgsWithLoadMore:YES];
}

//发送文本消息的回调方法
- (void)didSendText:(NSString *)text fromSender:(NSString *)sender onDate:(NSDate *)date {
    if([text length]>0){
        AVIMTextMessage* msg=[AVIMTextMessage messageWithText:[CDEmotionUtils convertWithText:text toEmoji:NO] attributes:nil];
        [self sendMsg:msg originFilePath:nil];
        [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeText];
    }
}

//发送图片消息的回调方法
- (void)didSendPhoto:(UIImage *)photo fromSender:(NSString *)sender onDate:(NSDate *)date {
    [self sendImage:photo];
    [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypePhoto];
}

// 发送视频消息的回调方法
- (void)didSendVideoConverPhoto:(UIImage *)videoConverPhoto videoPath:(NSString *)videoPath fromSender:(NSString *)sender onDate:(NSDate *)date {
}

// 发送语音消息的回调方法
- (void)didSendVoice:(NSString *)voicePath voiceDuration:(NSString *)voiceDuration fromSender:(NSString *)sender onDate:(NSDate *)date {
    [self sendFileMsgWithPath:voicePath type:kAVIMMessageMediaTypeAudio];
}

// 发送表情消息的回调方法
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

// 是否显示时间轴Label的回调方法
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

// 配置Cell的样式或者字体
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

// 协议回掉是否支持用户手动滚动
- (BOOL)shouldPreventScrollToBottomWhileUserScrolling {
    return YES;
}

-(void)didSelecteShareMenuItem:(XHShareMenuItem *)shareMenuItem atIndex:(NSInteger)index{
    [super didSelecteShareMenuItem:shareMenuItem atIndex:index];
}


#pragma mark - session state

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

