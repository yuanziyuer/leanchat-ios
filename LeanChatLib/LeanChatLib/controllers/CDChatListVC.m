//
//  CDChatListController.m
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/25/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDChatListVC.h"
#import "CDSessionStateView.h"
#import "CDStorage.h"
#import "CDImageTwoLabelTableCell.h"
#import "UIView+XHRemoteImage.h"

@interface CDChatListVC ()<CDSessionStateProtocal>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) CDSessionStateView* networkStateView;

@property (nonatomic,strong) UIRefreshControl* refreshControl;

@property (nonatomic,strong) NSMutableArray* rooms;

@property (nonatomic,strong) CDNotify* notify;

@property (nonatomic,strong) CDIM* im;

@property (nonatomic,strong) CDStorage* storage;

@property (nonatomic,strong) CDIMConfig* imConfig;

@end

static NSMutableArray* cacheConvs;

@implementation CDChatListVC

static NSString *cellIdentifier = @"ContactCell";

- (instancetype)init {
    if ((self = [super init])) {
        _rooms=[[NSMutableArray alloc] init];
        _im=[CDIM sharedInstance];
        _storage=[CDStorage sharedInstance];
        _notify=[CDNotify sharedInstance];
        _imConfig=[CDIMConfig config];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString* nibName=NSStringFromClass([CDImageTwoLabelTableCell class]);
    self.tableView.dataSource=self;
    self.tableView.delegate=self;
    [self.tableView registerNib:[UINib nibWithNibName:nibName bundle:nil] forCellReuseIdentifier:cellIdentifier];
    
    [self.tableView addSubview:self.refreshControl];
    
    _networkStateView=[[CDSessionStateView alloc] initWithWidth:self.tableView.frame.size.width];
    [_networkStateView setDelegate:self];
    [_networkStateView observeSessionUpdate];
    
    [_notify addMsgObserver:self selector:@selector(refresh)];
    [_notify addSessionObserver:self selector:@selector(sessionChanged)];
}

-(UIRefreshControl*)refreshControl{
    if(_refreshControl==nil){
        _refreshControl=[[UIRefreshControl alloc] init];
        [_refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    }
    return _refreshControl;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self runAfterSecs:0.5 block:^{
        [self refresh:nil];
    }];
}

-(void)sessionChanged{
}

-(void)refresh{
    [self.refreshControl beginRefreshing];
    [self refresh:self.refreshControl];
}

-(void)stopRefreshControl:(UIRefreshControl*)refreshControl{
    if(refreshControl!=nil && [[refreshControl class] isSubclassOfClass:[UIRefreshControl class]]){
        [refreshControl endRefreshing];
    }
}

-(void)refresh:(UIRefreshControl*)refreshControl{
    if([_im isOpened]==NO){
        [self stopRefreshControl:refreshControl];
        //return;
    }
    NSMutableArray* rooms=[[_storage getRooms] mutableCopy];
    [self showNetworkIndicator];
    [self.im cacheAndFillRooms:rooms callback:^(BOOL succeeded, NSError *error) {
        [self hideNetworkIndicator];
        [self stopRefreshControl:refreshControl];
        if([self filterError:error]){
            _rooms=rooms;
            [self.tableView reloadData];
            NSInteger totalUnreadCount=0;
            for(CDRoom* room in _rooms){
                totalUnreadCount+=room.unreadCount;
            }
            if([self.chatListDelegate respondsToSelector:@selector(setBadgeWithTotalUnreadCount:)]){
                [self.chatListDelegate setBadgeWithTotalUnreadCount:totalUnreadCount];
            }
        }
    }];
}

- (void)dealloc{
    [_notify removeMsgObserver:self];
    [_notify removeSessionObserver:self];
}

#pragma table view

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_rooms count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CDImageTwoLabelTableCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    CDRoom* room = [_rooms objectAtIndex:indexPath.row];
    if(room.conv.type==CDConvTypeSingle){
        id<CDUserModel> user= [self.imConfig.userDelegate getUserById:room.conv.otherId];
        cell.topLabel.text=user.username;
        [cell.myImageView setImageWithURL:[NSURL URLWithString:user.avatarUrl]];
    }else{
        [cell.myImageView setImage:[UIImage imageNamed:@"group_icon"]];
        cell.topLabel.text=room.conv.displayName;
    }
    cell.bottomLabel.text=[self.im getMsgTitle:room.lastMsg];
    cell.unreadCount=room.unreadCount;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CDRoom *room = [_rooms objectAtIndex:indexPath.row];
    if([self.chatListDelegate respondsToSelector:@selector(viewController:didSelectConv:)]){
        [self.chatListDelegate viewController:self didSelectConv:room.conv];
    }
}

#pragma mark -- CDSessionDelegateMethods

-(void)onSessionBrokenWithStateView:(CDSessionStateView *)view{
    self.tableView.tableHeaderView=view;
}

-(void)onSessionFineWithStateView:(CDSessionStateView *)view{
    self.tableView.tableHeaderView=nil;
}

@end
