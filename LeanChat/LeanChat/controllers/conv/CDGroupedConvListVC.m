//
//  CDGroupTableViewController.m
//
//
//  Created by lzw on 14/11/6.
//
//

#import "CDGroupedConvListVC.h"
#import "CDIMService.h"
#import "CDUtils.h"
#import "CDImageLabelTableCell.h"
#import <LeanChatLib/CDChatManager.h>

@interface CDGroupedConvListVC () {
    NSArray *convs;
    id groupUpdatedObserver;
}

@end

static NSString *cellIndentifier = @"cell";

@implementation CDGroupedConvListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    convs = [[NSMutableArray alloc] init];
    self.title = @"群组";
    NSString *nibName = NSStringFromClass([CDImageLabelTableCell class]);
    UINib *nib = [UINib nibWithNibName:nibName bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:cellIndentifier];
    [self refresh:nil];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh:) name:kCDNotificationConversationUpdated object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCDNotificationConversationUpdated object:nil];
}

- (void)refresh:(UIRefreshControl *)refreshControl {
    [[CDChatManager manager] findGroupedConvsWithBlock: ^(NSArray *objects, NSError *error) {
        [CDUtils stopRefreshControl:refreshControl];
        convs = objects;
        [self.tableView reloadData];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return convs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CDImageLabelTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[CDImageLabelTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    AVIMConversation *conv = [convs objectAtIndex:indexPath.row];
    cell.myLabel.text = conv.title;
    [cell.myImageView setImage:conv.icon];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    AVIMConversation *conv = [convs objectAtIndex:indexPath.row];
    [[CDIMService service] goWithConv:conv fromNav:self.navigationController];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        AVIMConversation *conv = [convs objectAtIndex:indexPath.row];
        WEAKSELF
        [conv quitWithCallback : ^(BOOL succeeded, NSError *error) {
            if ([self filterError:error]) {
                [weakSelf refresh:nil];
            }
        }];
    }
}

@end
