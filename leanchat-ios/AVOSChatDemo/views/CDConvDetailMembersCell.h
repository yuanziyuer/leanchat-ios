//
//  CDConvDetailMembersHeaderView.h
//  LeanChat
//
//  Created by lzw on 15/4/20.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CDCommon.h"

static CGFloat kCDConvDetailMembersCellLineSpacing = 10;
static CGFloat kCDConvDetailMembersCellInterItemSpacing = 20;

@protocol CDConvDetailMembersHeaderViewDelegate <NSObject>

- (void)didSelectMember:(AVUser *)member;

- (void)didLongPressMember:(AVUser *)member;

@end

@interface CDConvDetailMembersCell : UITableViewCell

@property (nonatomic, strong) NSArray *members;

@property (nonatomic, strong) id <CDConvDetailMembersHeaderViewDelegate> membersCellDelegate;

+ (CGFloat)heightForMembers:(NSArray *)members;

+ (NSString *)reuseIdentifier;

@end
