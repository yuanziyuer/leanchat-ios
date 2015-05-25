//
//  LeanChatConversationTableViewCell.m
//  MessageDisplayKitLeanchatExample
//
//  Created by lzw on 15/4/17.
//  Copyright (c) 2015年 iOS软件开发工程师 曾宪华 热衷于简洁的UI QQ:543413507 http://www.pailixiu.com/blog   http://www.pailixiu.com/Jack/personal. All rights reserved.
//

#import "LZConversationCell.h"
#import "JSBadgeView.h"

static CGFloat kCDImageSize = 35;
static CGFloat kCDVerticalSpacing = 8;
static CGFloat kCDHorizontalSpacing = 10;
static CGFloat kCDTimestampeLabelWidth = 100;

static CGFloat kCDNameLabelHeightProportion = 3.0 / 5;
static CGFloat kCDNameLabelHeight;
static CGFloat kCDMessageLabelHeight;


@interface LZConversationCell ()

@property (nonatomic, strong) JSBadgeView *badgeView;

@end

@implementation LZConversationCell


+ (NSString *)identifier {
    return NSStringFromClass([LZConversationCell class]);
}

+ (CGFloat)heightOfCell {
    return kCDImageSize + kCDVerticalSpacing * 2;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    kCDNameLabelHeight = kCDImageSize * kCDNameLabelHeightProportion;
    kCDMessageLabelHeight = kCDImageSize - kCDNameLabelHeight;
    
    [self addSubview:self.avatarImageView];
    [self addSubview:self.timestampLabel];
    [self addSubview:self.nameLabel];
    [self addSubview:self.messageLabel];
}

- (UIImageView *)avatarImageView {
    if (_avatarImageView == nil) {
        _avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(kCDHorizontalSpacing, kCDVerticalSpacing, kCDImageSize, kCDImageSize)];
    }
    return _avatarImageView;
}

- (UILabel *)timestampLabel {
    if (_timestampLabel == nil) {
        _timestampLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth([UIScreen mainScreen].bounds) - kCDHorizontalSpacing - kCDTimestampeLabelWidth, CGRectGetMinY(_avatarImageView.frame), kCDTimestampeLabelWidth, kCDNameLabelHeight)];
        _timestampLabel.font = [UIFont systemFontOfSize:13];
        _timestampLabel.textAlignment = NSTextAlignmentRight;
        _timestampLabel.textColor = [UIColor grayColor];
    }
    return _timestampLabel;
}

- (UILabel *)nameLabel {
    if (_nameLabel == nil) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_avatarImageView.frame) + kCDHorizontalSpacing, CGRectGetMinY(_avatarImageView.frame), CGRectGetMinX(_timestampLabel.frame) - kCDHorizontalSpacing * 3 - kCDImageSize, kCDNameLabelHeight)];
        _nameLabel.font = [UIFont systemFontOfSize:17];
    }
    return _nameLabel;
}

- (UILabel *)messageLabel {
    if (_messageLabel == nil) {
        _messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(_nameLabel.frame), CGRectGetMaxY(_nameLabel.frame), CGRectGetWidth([UIScreen mainScreen].bounds)- 3 * kCDHorizontalSpacing - kCDImageSize, kCDMessageLabelHeight)];
        _messageLabel.font = [UIFont systemFontOfSize:14];
        _messageLabel.textColor = [UIColor grayColor];
    }
    return _messageLabel;
}

- (JSBadgeView *)badgeView {
    if (_badgeView == nil) {
        _badgeView = [[JSBadgeView alloc] initWithParentView:_avatarImageView alignment:JSBadgeViewAlignmentTopRight];
    }
    return _badgeView;
}

- (void)setUnreadCount:(NSInteger)unreadCount {
    if (unreadCount > 0) {
        self.badgeView.badgeText = [NSString stringWithFormat:@"%ld", (long)unreadCount];
    }
    else {
        self.badgeView.badgeText = nil;
    }
}

- (void)awakeFromNib {
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
