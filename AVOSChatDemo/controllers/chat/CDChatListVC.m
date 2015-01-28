//
//  CDChatListController.m
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/25/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDChatListVC.h"
#import "CDSessionManager.h"
#import "CDChatRoomVC.h"
#import "CDPopMenu.h"
#import "CDRoom.h"
#import "CDImageTwoLabelTableCell.h"
#import "CDUtils.h"
#import "CDCacheService.h"
#import "CDCloudService.h"
#import "CDService.h"
#import "CDDatabaseService.h"
#import "SRRefreshView.h"
#import "CDUpgradeService.h"

enum : NSUInteger {
    kTagNameLabel = 10000,
};

@interface CDChatListVC ()  {
    CDPopMenu *_popMenu;
    NSMutableArray *rooms;
    CDIM* imClient;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong,nonatomic) SRRefreshView* slimeView;

@end

@implementation CDChatListVC

static NSString *cellIdentifier = @"ContactCell";

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"消息";
        self.tabBarItem.image = [UIImage imageNamed:@"tabbar_chat_active"];
        rooms=[[NSMutableArray alloc] init];
        imClient=[CDIM sharedInstance];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showMenuOnView:)];
    NSString* nibName=NSStringFromClass([CDImageTwoLabelTableCell class]);
    self.tableView.dataSource=self;
    self.tableView.delegate=self;
    [self.tableView registerNib:[UINib nibWithNibName:nibName bundle:nil] forCellReuseIdentifier:cellIdentifier];
    
//    UIRefreshControl* refreshControl=[[UIRefreshControl alloc] init];
//    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
//    [self.tableView addSubview:refreshControl];
    _networkStateView=[[CDSessionStateView alloc] initWithWidth:self.tableView.frame.size.width];
    [_networkStateView setDelegate:self];
    [_networkStateView observeSessionUpdate];
    
    [_tableView addSubview:self.slimeView];
    //[_slimeView setLoadingWithExpansion];
    [_slimeView setLoading:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:NOTIFICATION_MESSAGE_UPDATED object:nil];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self refresh:_slimeView];
    // hide it
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

- (SRRefreshView *)slimeView
{
    if (!_slimeView) {
        _slimeView = [[SRRefreshView alloc] init];
        _slimeView.delegate = self;
        _slimeView.upInset = 64;
        _slimeView.slimeMissWhenGoingBack = YES;
        _slimeView.slime.bodyColor = [UIColor grayColor];
        _slimeView.slime.skinColor = [UIColor grayColor];
        _slimeView.slime.lineWith = 1;
        _slimeView.slime.shadowBlur = 4;
        _slimeView.slime.shadowColor = [UIColor grayColor];
        _slimeView.backgroundColor = [UIColor clearColor];
    }
    
    return _slimeView;
}

-(void)refresh{
    [self refresh:nil];
}

-(void)refresh:(SRRefreshView*)refrshView{
    [CDUtils showNetworkIndicator];
    [imClient findRoomsWithCallback:^(NSArray *objects, NSError *error) {
        if(refrshView!=nil){
            [refrshView endRefresh];
        }
        [CDUtils hideNetworkIndicator];
        [CDUtils filterError:error callback:^{
            rooms=[objects mutableCopy];
            [self.tableView reloadData];
            int totalUnreadCount=0;
            if(totalUnreadCount>0){
                self.tabBarItem.badgeValue=[NSString stringWithFormat:@"%d",totalUnreadCount];
            }else{
                self.tabBarItem.badgeValue=nil;
            }
        }];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_MESSAGE_UPDATED object:nil];
}

#pragma table view

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CD_COMMON_ROW_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [rooms count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CDImageTwoLabelTableCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    CDRoom* room = [rooms objectAtIndex:indexPath.row];
    if(room.type==CDConvTypeSingle){
        AVUser* user=[CDCacheService lookupUser:room.otherId];
        [CDUserService displayAvatarOfUser:user avatarView:cell.myImageView];
        cell.topLabel.text=user.username;
    }else{
        [cell.myImageView setImage:[UIImage imageNamed:@"group_icon"]];
        cell.topLabel.text=room.conv.name;
    }
    
    cell.bottomLabel.text=[CDIMUtils getMsgDesc:room.lastMsg];
    cell.unreadCount=0;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CDRoom *room = [rooms objectAtIndex:indexPath.row];
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

-(void)slimeRefreshStartRefresh:(SRRefreshView *)refreshView{
    [self refresh:refreshView];
}

#pragma mark - scrollView delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [_slimeView scrollViewDidScroll];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [_slimeView scrollViewDidEndDraging];
}

@end
