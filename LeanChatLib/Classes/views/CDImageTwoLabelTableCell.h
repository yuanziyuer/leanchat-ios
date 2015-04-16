//
//  CDImageTwoLabelTableCell.h
//  AVOSChatDemo
//
//  Created by lzw on 14/11/11.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSBadgeView.h"

@interface CDImageTwoLabelTableCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *myImageView;
@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UILabel *bottomLabel;
@property (strong, nonatomic) JSBadgeView *unreadBadge;
@property (nonatomic) NSInteger unreadCount;

@end
