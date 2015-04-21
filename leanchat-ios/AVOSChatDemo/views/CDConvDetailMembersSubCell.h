//
//  CDConvDetailMembersSubCell.h
//  LeanChat
//
//  Created by lzw on 15/4/21.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import <UIKit/UIKit.h>

static CGFloat kCDConvDetailMemberSubCellAvatarSize=60;
static CGFloat kCDConvDetailMemberSubCellLabelHeight=20;
static CGFloat kCDConvDetailMemberSubCellSeparator=5;

@interface CDConvDetailMembersSubCell : UICollectionViewCell

@property (nonatomic,strong) UIImageView *avatarImageView;

@property (nonatomic,strong) UILabel *usernameLabel;

+(CGFloat)heightForCell;

+(CGFloat)widthForCell;

@end
