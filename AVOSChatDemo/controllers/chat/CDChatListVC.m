//
//  CDChatListController.m
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/25/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDChatListVC.h"
#import "CDChatRoomVC.h"
#import "CDPopMenu.h"
#import "CDViews.h"
#import "CDModels.h"
#import "CDService.h"
#import "SRRefreshView.h"

enum : NSUInteger {
    kTagNameLabel = 10000,
};

@interface CDChatListVC ()  {
    CDPopMenu *_popMenu;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property UIRefreshControl* refreshControl;

@property NSMutableArray* rooms;

@property CDStorage* storage;

@property CDIM* im;

@end

@implementation CDChatListVC

static NSString *cellIdentifier = @"ContactCell";

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"消息";
        self.tabBarItem.image = [UIImage imageNamed:@"tabbar_chat_active"];
        _rooms=[[NSMutableArray alloc] init];
        _im=[CDIM sharedInstance];
        _storage=[CDStorage sharedInstance];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString* nibName=NSStringFromClass([CDImageTwoLabelTableCell class]);
    self.tableView.dataSource=self;
    self.tableView.delegate=self;
    [self.tableView registerNib:[UINib nibWithNibName:nibName bundle:nil] forCellReuseIdentifier:cellIdentifier];
    
    _refreshControl=[[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:_refreshControl];
    
    _networkStateView=[[CDSessionStateView alloc] initWithWidth:self.tableView.frame.size.width];
    [_networkStateView setDelegate:self];
    [_networkStateView observeSessionUpdate];
    
//    [_tableView addSubview:self.slimeView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh:) name:NOTIFICATION_MESSAGE_UPDATED object:nil];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self refresh:nil];
    // hide it
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

-(void)refresh:(UIRefreshControl*)refreshControl{
    NSMutableArray* rooms=[[_storage getRooms] mutableCopy];
    [CDUtils showNetworkIndicator];
    [CDCache cacheAndFillRooms:rooms callback:^(BOOL succeeded, NSError *error) {
        [CDUtils hideNetworkIndicator];
        [CDUtils stopRefreshControl:refreshControl];
        if([CDUtils filterError:error]){
            _rooms=rooms;
            [self.tableView reloadData];
            int totalUnreadCount=0;
            for(CDRoom* room in _rooms){
                totalUnreadCount+=room.unreadCount;
            }
            if(totalUnreadCount>0){
                self.tabBarItem.badgeValue=[NSString stringWithFormat:@"%d",totalUnreadCount];
            }else{
                self.tabBarItem.badgeValue=nil;
            }
        }
    }];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_MESSAGE_UPDATED object:nil];
}

#pragma table view

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CD_COMMON_ROW_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_rooms count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CDImageTwoLabelTableCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    CDRoom* room = [_rooms objectAtIndex:indexPath.row];
    CDConvType type=[CDConvService typeOfConv:room.conv];
    if(type==CDConvTypeSingle){
        AVUser* user=[CDCache lookupUser:[CDConvService otherIdOfConv:room.conv]];
        [CDUserService displayAvatarOfUser:user avatarView:cell.myImageView];
        cell.topLabel.text=user.username;
    }else{
        [cell.myImageView setImage:[UIImage imageNamed:@"group_icon"]];
        cell.topLabel.text=[CDConvService nameOfConv:room.conv];
    }
    
    cell.bottomLabel.text=[CDIMUtils getMsgDesc:room.lastMsg];
    cell.unreadCount=room.unreadCount;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CDRoom *room = [_rooms objectAtIndex:indexPath.row];
    CDChatRoomVC *controller = [[CDChatRoomVC alloc] initWithConv:room.conv];
    UINavigationController* nav=[[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark -- CDSessionDelegateMethods

-(void)onSessionBrokenWithStateView:(CDSessionStateView *)view{
    _tableView.tableHeaderView=view;
}

-(void)onSessionFineWithStateView:(CDSessionStateView *)view{
    _tableView.tableHeaderView=nil;
}

@end
