//
//  CDChatListController.m
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/25/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDChatListController.h"
#import "CDSessionManager.h"
#import "CDChatRoomController.h"
#import "CDPopMenu.h"
#import "CDChatConfirmController.h"
#import "CDChatRoom.h"
#import "CDImageTwoLabelTableCell.h"
#import "CDUtils.h"
#import "CDCloudService.h"

enum : NSUInteger {
    kTagNameLabel = 10000,
};

@interface CDChatListController ()  {
    CDPopMenu *_popMenu;
    CDSessionManager* sessionManager;
    NSMutableArray *chatRooms;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation CDChatListController

static NSString *cellIdentifier = @"ContactCell";

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"消息";
        self.tabBarItem.image = [UIImage imageNamed:@"tabbar_chat_active"];
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
    chatRooms=[[NSMutableArray alloc] init];
    sessionManager=[CDSessionManager sharedInstance];
    
    UIRefreshControl* refreshControl=[[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self refresh:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh:) name:NOTIFICATION_MESSAGE_UPDATED object:nil];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_MESSAGE_UPDATED object:nil];
}

-(void)refresh:(UIRefreshControl*)refreshControl{
    [CDUtils showNetworkIndicator];
    [sessionManager findConversationsWithCallback:^(NSArray *objects, NSError *error) {
        [CDUtils stopRefreshControl:refreshControl];
        [CDUtils hideNetworkIndicator];
        [CDUtils filterError:error callback:^{
            chatRooms=[objects mutableCopy];
            [self.tableView reloadData];
        }];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
}

- (void)showMenuOnView:(UIBarButtonItem *)buttonItem {
    [self.popMenu showMenuOnView:self.navigationController.view atPoint:CGPointZero];
}

#pragma table view

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [chatRooms count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CDImageTwoLabelTableCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    CDChatRoom *chatRoom = [chatRooms objectAtIndex:indexPath.row];
    CDMsgRoomType type=[chatRoom roomType];
    NSMutableString *nameString = [[NSMutableString alloc] init];
    if (type == CDMsgRoomTypeGroup) {
        [nameString appendFormat:@"%@", [chatRoom.chatGroup getTitle]];
        [cell.myImageView setImage:[UIImage imageNamed:@"group_icon"]];
    } else {
        [CDUserService displayAvatarOfUser:chatRoom.chatUser avatarView:cell.myImageView];
        [nameString appendFormat:@"%@", chatRoom.chatUser.username];
    }
    cell.topLabel.text=nameString;
    cell.bottomLabel.text=[chatRoom.latestMsg getMsgDesc];
    cell.unreadCount=chatRoom.unreadCount;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CDChatRoom *chatRoom = [chatRooms objectAtIndex:indexPath.row];
    CDMsgRoomType type = chatRoom.roomType;
    CDChatRoomController *controller = [[CDChatRoomController alloc] init];
    controller.type = type;
    if (type == CDMsgRoomTypeGroup) {
        CDSessionManager* manager=[CDSessionManager sharedInstance];
        [manager setCurrentChatGroup:chatRoom.chatGroup];
    } else {
        controller.chatUser=chatRoom.chatUser;
    }
    UINavigationController* nav=[[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:nav animated:YES completion:nil];
}

- (CDPopMenu *)popMenu {
    if (!_popMenu) {
        int count = 2;
        NSMutableArray *popMenuItems = [[NSMutableArray alloc] initWithCapacity:count];
        for (int i = 0; i < count; ++i) {
            NSString *imageName = nil;
            NSString *title;
            switch (i) {
                case 0: {
                    imageName = @"menu_add_newmessage";
                    title = @"发起群聊";
                    break;
                }
                case 1: {
                    imageName = @"menu_add_scan";
                    title = @"扫一扫";
                    break;
                }
                default:
                    break;
            }
            UIImage *image = [UIImage imageNamed:imageName];
            CDPopMenuItem *popMenuItem = [[CDPopMenuItem alloc] initWithImage:image title:title];
            [popMenuItems addObject:popMenuItem];
        }
        CDPopMenu *popMenu = [[CDPopMenu alloc] initWithMenus:popMenuItems];
        popMenu.popMenuSelected = ^(NSInteger index, CDPopMenuItem *item) {
            switch (index) {
                case 0:
                    break;
                case 1:
                    break;
                    
                default:
                    break;
            }
        };
        _popMenu = popMenu;
    }
    return _popMenu;
}

#pragma mark - ZXingDelegateMethods

-(void)zxingScanResult:(NSString*)result{
    NSLog(@"%s %@", __PRETTY_FUNCTION__, result);
    [self dismissViewControllerAnimated:NO completion:^{
        NSDictionary *dict = nil;
        NSError *error = nil;
        NSData *data = [result dataUsingEncoding:NSUTF8StringEncoding];
        dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (dict) {
            CDMsgRoomType type = [[dict objectForKey:@"type"] integerValue];
            NSString *otherId = [dict objectForKey:@"id"];
            CDChatConfirmController *controller = [[CDChatConfirmController alloc] init];
            controller.type = type;
            controller.otherId = otherId;
            [self.navigationController pushViewController:controller animated:YES];
        }
    }];
    // [self dismissViewControllerAnimated:NO completion:nil];
}

@end
