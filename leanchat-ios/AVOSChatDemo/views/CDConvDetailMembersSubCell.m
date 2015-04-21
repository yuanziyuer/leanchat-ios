//
//  CDConvDetailMembersSubCell.m
//  LeanChat
//
//  Created by lzw on 15/4/21.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDConvDetailMembersSubCell.h"

@interface CDConvDetailMembersSubCell ()

@end

@implementation CDConvDetailMembersSubCell

+(CGFloat)heightForCell{
    return kCDConvDetailMemberSubCellAvatarSize+kCDConvDetailMemberSubCellSeparator+kCDConvDetailMemberSubCellLabelHeight;
}

+(CGFloat)widthForCell{
    return kCDConvDetailMemberSubCellAvatarSize;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.avatarImageView];
        [self addSubview:self.usernameLabel];
    }
    return self;
}

-(UIImageView*)avatarImageView{
    if(_avatarImageView==nil){
        _avatarImageView=[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kCDConvDetailMemberSubCellAvatarSize, kCDConvDetailMemberSubCellAvatarSize)];
    }
    return _avatarImageView;
}

-(UILabel*)usernameLabel{
    if(_usernameLabel==nil){
        _usernameLabel=[[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_avatarImageView.frame)+kCDConvDetailMemberSubCellSeparator, CGRectGetWidth(_avatarImageView.frame), kCDConvDetailMemberSubCellLabelHeight)];
        _usernameLabel.textAlignment=NSTextAlignmentCenter;
        _usernameLabel.font=[UIFont systemFontOfSize:12];
    }
    return _usernameLabel;
}

@end
