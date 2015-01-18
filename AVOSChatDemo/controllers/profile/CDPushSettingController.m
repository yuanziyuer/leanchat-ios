//
//  CDPushSettingController.m
//  LeanChat
//
//  Created by lzw on 15/1/15.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDPushSettingController.h"
#import "CDModels.h"
#import "CDService.h"

@interface CDPushSettingController ()

@property (strong,nonatomic) UITableViewCell* receiveMessageCell;

@property (strong,nonatomic) UISwitch* receiveSwitch;

@property (nonatomic,assign) BOOL receiveOn;

@end

static NSString* cellIndentifier=@"cellIndentifier";

@implementation CDPushSettingController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:@"消息通知"];
    
    UIApplication *application = [UIApplication sharedApplication];
    
    BOOL enabled;
    if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)]){
        // ios8
        enabled = [application isRegisteredForRemoteNotifications];
    }else{
        UIRemoteNotificationType types = [application enabledRemoteNotificationTypes];
        enabled = types & UIRemoteNotificationTypeAlert;
    }
    
    _receiveOn=enabled;
    self.tableView.allowsSelection=NO;
    [self setTableViewCellInSection:0];
    
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 40;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 10;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

-(UISwitch*)switchView:(UITableViewCell*)cell{
    CGFloat width=60;
    CGFloat height=30;
    CGFloat horizontalPad=10;
    CGFloat verticalPad=(CGRectGetHeight(cell.frame)-height)/2;
    UISwitch* switchView=[[UISwitch alloc] initWithFrame:CGRectMake(CGRectGetWidth(cell.frame)-width-horizontalPad, verticalPad, width, height)];
    return  switchView;
}

-(void)setTableViewCellInSection:(int)section{
    UITableViewCell* cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIndentifier];
    if(_receiveOn){
      cell.detailTextLabel.text=@"已开启";
    }else{
      cell.detailTextLabel.text=@"已关闭";
    }
    cell.textLabel.text=@"接收新消息通知";
    _receiveMessageCell=cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section==0){
        return _receiveMessageCell;
    }
    return nil;
}

-(UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if(section==0){
        CGFloat pad=30;
        UILabel* label=[[UILabel alloc] initWithFrame:CGRectMake(pad, 0, tableView.frame.size.width-2*pad, 40)];
        label.bounds=CGRectInset(label.frame, 20, 20);
        [label setFont:[UIFont systemFontOfSize:10]];
        [label setTextColor:[UIColor grayColor]];
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.textAlignment=NSTextAlignmentCenter;
        label.numberOfLines = 0;
        label.text=@"如果你要关闭或开启 LeanChat 的新消息通知，请在 iPhone 的\"设置\"-\"通知\"功能中，找到应用程序 LeanChat 更改。";
        return label;
    }
    return nil;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
