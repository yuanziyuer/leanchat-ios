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
@property (strong,nonatomic) UITableViewCell* soundCell;

@property (strong,nonatomic) UISwitch* receiveSwitch;
@property (strong,nonatomic) UISwitch* soundSwitch;

@property (strong,nonatomic) CDSetting* setting;

@property BOOL receiveOn;
@property BOOL soundOn;
@property BOOL dataChanged;

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
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.tableView.allowsSelection=NO;
    [self setTableViewCellInSection:0];
    [self setTableViewCellInSection:1];
    _dataChanged=NO;
    
    [CDUtils showNetworkIndicator];
    [CDSettingService getSettingWithBlock:^(id object, NSError *error) {
        [CDUtils hideNetworkIndicator];
        [CDUtils filterError:error callback:^{
            _setting=object;
            if(_setting==nil){
                _receiveOn=YES;
                _soundOn=YES;
            }else{
                _receiveOn=_setting.msgPush;
                _soundOn=_setting.sound;
            }
            [self setSwitchStatus];
        }];
    }];
    //[self.tableView setBackgroundColor:[UIColor redColor]];
    //self.tableView.autoresizingMask=UIViewAutoresizingFlexibleHeight;
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    if(_dataChanged){
        [CDUtils showNetworkIndicator];
        [CDSettingService changeSetting:_setting msgPush:_receiveOn sound:_soundOn block:^(id object, NSError *error) {
            [CDUtils hideNetworkIndicator];
            [CDUtils filterError:error callback:nil];
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 10;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 10;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
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
    UITableViewCell* cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIndentifier];
    UISwitch* switchView=[self switchView:cell];
    [cell addSubview:switchView];
    [switchView addTarget:self action:@selector(switchStateChanged:) forControlEvents:UIControlEventValueChanged];
    if(section==0){
        cell.textLabel.text=@"接收消息通知";
        switchView.tag=0;
        _receiveSwitch=switchView;
        _receiveMessageCell=cell;
    }else if(section==1){
        cell.textLabel.text=@"声音";
        switchView.tag=1;
        _soundSwitch=switchView;
        _soundCell=cell;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section==0){
        return _receiveMessageCell;
    }else{
        return _soundCell;
    }
}

-(void)switchStateChanged:(UISwitch*)switchView{
    _dataChanged=YES;
    int tag=switchView.tag;
    BOOL on=[switchView isOn];
    if(tag==0){
        _receiveOn=on;
        if(_receiveOn==NO){
            _soundOn=NO;
        }
    }else{
        _soundOn=on;
    }
    [self setSwitchStatus];
}

-(void)setSwitchStatus{
    [_receiveSwitch setOn:_receiveOn];
    [_soundSwitch setOn:_soundOn];
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
