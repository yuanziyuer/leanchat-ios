//
//  CDContactListController.m
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/27/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDContactListController.h"
#import "CDCommon.h"
#import "CDUserService.h"
#import "CDAddFriendController.h"
#import "CDBaseNavigationController.h"
#import "CDNewFriendTableViewController.h"
#import "CDUserInfoController.h"
#import "CDSessionManager.h"
#import "CDImageLabelTableCell.h"
#import "CDGroupTableViewController.h"
#import "CDUtils.h"
#import "CDCacheService.h"
#import "CDService.h"
#import "JSBadgeView.h"

enum : NSUInteger {
    kTagNameLabel = 10000,
};
@interface CDContactListController()<UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *users;
@property (weak, nonatomic) IBOutlet UIView *myNewFriendView;
@property (weak, nonatomic) IBOutlet UIView *groupView;
@property (nonatomic,assign) int addRequestN;
@property (weak, nonatomic) IBOutlet UIImageView *myNewFriendIcon;
@property JSBadgeView* badgeView;

@end

@implementation CDContactListController

#pragma mark - Life Cycle
- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"联系人";
        self.tabBarItem.image = [UIImage imageNamed:@"tabbar_contacts_active"];
        [self setBadgeIncludeBadgeView:NO];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]
                                            initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                            target:self action:@selector(goAddFriend:)];
    self.tableView.delegate=self;
    self.tableView.dataSource=self;
    
    UITapGestureRecognizer *singleTap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goNewFriend:)];
    [self.myNewFriendView addGestureRecognizer:singleTap];
    
    singleTap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goGroup:)];
    [self.groupView addGestureRecognizer:singleTap];
    
    //[self.myNewFriendView addGestureRecognizer:singleTap];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh:) name:CD_FRIENDS_UPDATE object:nil];
    
    UIRefreshControl* refreshControl=[[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    [self refresh:nil];
    UILongPressGestureRecognizer *recogizer=[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    recogizer.minimumPressDuration=1.0;
    [self.tableView addGestureRecognizer:recogizer];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CD_FRIENDS_UPDATE object:nil];
}

-(void)goNewFriend:(id)sender{
    [CDLocalService setAddRequestN:_addRequestN];
    [_badgeView removeFromSuperview];
    CDNewFriendTableViewController *controller=[[CDNewFriendTableViewController alloc] init];
    [[self navigationController] pushViewController:controller animated:YES];
    self.tabBarItem.badgeValue=nil;
}

-(void)goGroup:(id)sender{
    CDGroupTableViewController *controller=[[CDGroupTableViewController alloc] init];
    [[self navigationController] pushViewController:controller animated:YES];
}

-(void)goAddFriend:(UIBarButtonItem*)buttonItem{
    CDAddFriendController *controller = [[CDAddFriendController alloc] init];
    [[self navigationController] pushViewController:controller animated:YES];
}

-(void)refresh:(UIRefreshControl*)refreshControl{
    BOOL networkOnly= refreshControl!=nil;
    [CDUtils showNetworkIndicator];
    //[CDUserService findFriendsWithCallback:^(NSArray *objects, NSError *error) {
    //}];
    [CDUserService findFriendsIsNetworkOnly:networkOnly callback:^(NSArray *objects, NSError *error) {
        [CDUtils stopRefreshControl:refreshControl];
        [CDUtils hideNetworkIndicator];
        CDBlock callback=^{
            self.users = [objects mutableCopy];
            [CDCacheService registerUsers:self.users];
            [CDCacheService setFriends:objects];
            [self.tableView reloadData];
        };
        if(error && (error.code==kAVErrorCacheMiss || error.code==1)){
            // for the first start
            objects=[NSMutableArray array];
            callback();
        }else{
            [CDUtils filterError:error callback:callback];
        }
    }];
    
    [self setBadgeIncludeBadgeView:YES];
}

-(void)setBadgeIncludeBadgeView:(BOOL)includeBadgeView{
    [CDAddRequestService countAddRequestsWithBlock:^(NSInteger number, NSError *error) {
        [CDUtils logError:error callback:^{
            _addRequestN=number;
            int oldN=[CDLocalService getAddRequestN];
            if(_addRequestN>oldN){
                NSString* badge=[NSString stringWithFormat:@"%d",_addRequestN-oldN];;
                if(includeBadgeView){
                    if(_badgeView!=nil){
                        [_badgeView removeFromSuperview];
                    }
                    _badgeView=[[JSBadgeView alloc] initWithParentView:_myNewFriendIcon alignment:JSBadgeViewAlignmentTopRight];
                    _badgeView.badgeText=badge;
                }
                self.tabBarItem.badgeValue=badge;
            }else{
                self.tabBarItem.badgeValue=nil;
            }
        }];
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CD_COMMON_ROW_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"ContactCell";
    static BOOL isRegisterNib=NO;
    if(isRegisterNib==NO){
        [tableView registerNib:[UINib nibWithNibName:@"CDImageLabelTableCell" bundle:nil]
          forCellReuseIdentifier:cellIdentifier];
    }
    CDImageLabelTableCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    CDImageLabelTableCell* tableCell=(CDImageLabelTableCell*)cell;
    AVUser *user = [self.users objectAtIndex:indexPath.row];
    [CDUserService displayAvatarOfUser:user avatarView:tableCell.myImageView];
    tableCell.myLabel.text = user.username;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AVUser *user = [self.users objectAtIndex:indexPath.row];
    CDUserInfoController *controller=[[CDUserInfoController alloc] initWithUser:user];
    [self.navigationController pushViewController:controller animated:YES];
}

-(void)handleLongPress:(UILongPressGestureRecognizer*)recognizer{
    CGPoint point=[recognizer locationInView:self.tableView];
    NSIndexPath *path=[self.tableView indexPathForRowAtPoint:point];
    if(path!=nil && recognizer.state==UIGestureRecognizerStateBegan){
        UIAlertView* alertView=[[UIAlertView alloc] initWithTitle:@"" message:@"解除好友关系吗" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
        alertView.tag=path.row;
        [alertView show];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex==0){
        int row=alertView.tag;
        AVUser* user=[_users objectAtIndex:row];
        [CDUtils showNetworkIndicator];
        [CDUserService removeFriend:user callback:^(BOOL succeeded, NSError *error) {
            [CDUtils hideNetworkIndicator];
            [CDUtils filterError:error callback:^{
                [self refresh:nil];
            }];
        }];
    }
}
@end
