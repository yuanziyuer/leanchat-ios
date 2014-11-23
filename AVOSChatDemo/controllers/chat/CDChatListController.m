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
#import "ChatRoom.h"
#import "CDImageTwoLabelTableCell.h"
#import "Utils.h"
#import "CloudService.h"

enum : NSUInteger {
    kTagNameLabel = 10000,
};

@interface CDChatListController ()  {
    CDPopMenu *_popMenu;
    CDSessionManager* sessionManager;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation CDChatListController

static NSString *cellIdentifier = @"ContactCell";

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"消息";
        self.tabBarItem.image = [UIImage imageNamed:@"wechat"];
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
    sessionManager=[CDSessionManager sharedInstance];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self refresh];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageUpdated) name:NOTIFICATION_MESSAGE_UPDATED object:nil];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_MESSAGE_UPDATED object:nil];
}

-(void)messageUpdated{
    [self refresh];
}

-(void)refresh{
    [Utils showNetworkIndicator];
    [sessionManager findConversationsWithCallback:^(NSArray *objects, NSError *error) {
        [Utils hideNetworkIndicator];
        [Utils filterError:error callback:^{
            [self.tableView reloadData];
        }];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showMenuOnView:(UIBarButtonItem *)buttonItem {
    [self.popMenu showMenuOnView:self.navigationController.view atPoint:CGPointZero];
}

#pragma table view

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[sessionManager chatRooms] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CDImageTwoLabelTableCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    ChatRoom *chatRoom = [[[CDSessionManager sharedInstance] chatRooms] objectAtIndex:indexPath.row];
    CDMsgRoomType type=[chatRoom roomType];
    NSMutableString *nameString = [[NSMutableString alloc] init];
    if (type == CDMsgRoomTypeGroup) {
        NSString* groupName=chatRoom.chatGroup.name;
        [nameString appendFormat:@"%@", groupName];
        [cell.myImageView setImage:[UIImage imageNamed:@"group_icon"]];
    } else {
        [UserService displayAvatarOfUser:chatRoom.chatUser avatarView:cell.myImageView];
        [nameString appendFormat:@"%@", chatRoom.chatUser.username];
    }
    cell.topLabel.text=nameString;
    cell.bottomLabel.text=[chatRoom.latestMsg getMsgDesc];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ChatRoom *chatRoom = [[[CDSessionManager sharedInstance] chatRooms] objectAtIndex:indexPath.row];
    CDMsgRoomType type = chatRoom.roomType;
    CDChatRoomController *controller = [[CDChatRoomController alloc] init];
    controller.type = type;
    if (type == CDMsgRoomTypeGroup) {
        controller.chatGroup=chatRoom.chatGroup;
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
