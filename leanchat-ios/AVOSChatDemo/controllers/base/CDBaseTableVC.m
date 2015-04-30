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


- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
}

- (CGFloat)getAdapterHeight {
    CGFloat adapterHeight = 0;
    if ([[[UIDevice currentDevice] systemVersion] integerValue] < 7.0) {
        adapterHeight = 44;
    }
    return adapterHeight;
}

-(UITableView*)tableView{
    if(_tableView==nil){
        CGRect tableViewFrame = self.view.bounds;
        tableViewFrame.size.height -= (self.navigationController.viewControllers.count > 1 ? 0 : (CGRectGetHeight(self.tabBarController.tabBar.bounds)))+[self getAdapterHeight];
        _tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:self.tableViewStyle];
        _tableView.delegate=self;
        _tableView.dataSource=self;
    }
    return _tableView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)dealloc{
}

-(NSMutableArray*)dataSource{
    if(_dataSource==nil){
        _dataSource=[NSMutableArray array];
    }
    return _dataSource;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSource.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    return nil;
}

@end

