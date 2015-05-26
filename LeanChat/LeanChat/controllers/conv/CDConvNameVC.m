//
//  CDConvNameVC.m
//  LeanChat
//
//  Created by lzw on 15/2/5.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDConvNameVC.h"
#import <LeanChatLib/LeanChatLib.h>

@interface CDConvNameVC ()

@property (strong, nonatomic) IBOutlet UITableViewCell *tableCell;

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;

@property (nonatomic, strong) CDIM *im;

@property (nonatomic, strong) CDNotify *notify;

@end

@implementation CDConvNameVC

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.tableViewStyle = UITableViewStyleGrouped;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"群聊名称";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveName:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(backPressed)];
    self.nameTextField.text = _conv.displayName;
    _im = [CDIM sharedInstance];
    _notify = [CDNotify sharedInstance];
}

- (void)backPressed {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveName:(id)sender {
    if (_nameTextField.text.length > 0) {
        AVIMConversationUpdateBuilder *updateBuilder = [_conv newUpdateBuilder];
        [updateBuilder setName:_nameTextField.text];
        [_conv update:[updateBuilder dictionary] callback: ^(BOOL succeeded, NSError *error) {
            if ([self filterError:error]) {
                [_notify postConvNotify];
                [self backPressed];
            }
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return _tableCell;
}

@end
