//
//  CDBaseTableController.m
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/24/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDBaseTableVC.h"

@interface CDBaseTableVC ()

@end

@implementation CDBaseTableVC

- (void)loadView {
    [super loadView];
    if ([self respondsToSelector:@selector(automaticalyAdjustsScrollViewInsets)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    [self.view addSubview:self.tableView];
}

- (UITableView *)tableView {
    if (!_tableView) {
        if(!self.tableViewStyle){
            self.tableViewStyle=UITableViewStylePlain;
        }
        _tableView = [[UITableView alloc] initWithFrame:self.view.frame style:self.tableViewStyle];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return  _tableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
//         For insetting with a navigation bar
//        CGRect rect = self.navigationController.navigationBar.frame;
//        UIEdgeInsets insets = UIEdgeInsetsMake(CGRectGetMaxY(rect), 0, CGRectGetHeight(self.tabBarController.tabBar.bounds), 0);
        UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, CGRectGetHeight(self.tabBarController.tabBar.bounds), 0);
        self.tableView.contentInset = insets;
        self.tableView.scrollIndicatorInsets = insets;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}


@end
