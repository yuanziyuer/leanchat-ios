//
//  LeanChatConversationTableViewCell.m
//  MessageDisplayKitLeanchatExample
//
//  Created by lzw on 15/4/17.
//  Copyright (c) 2015年 iOS软件开发工程师 曾宪华 热衷于简洁的UI QQ:543413507 http://www.pailixiu.com/blog   http://www.pailixiu.com/Jack/personal. All rights reserved.
//

#import "CDChatListRoomCell.h"
#import "JSBadgeView.h"
#import "AVIMConversation+Custom.h"
#import "CDIMConfig.h"
#import "UIView+XHRemoteImage.h"
#import "CDEmotionUtils.h"

static CGFloat kCDImageSize = 35;
static CGFloat kCDVerticalSpacing = 8;
static CGFloat kCDHorizontalSpacing = 10;
static CGFloat kCDTimestampeLabelWidth = 100;

static CGFloat kCDNameLabelHeightProportion = 3.0 / 5;
static CGFloat kCDNameLabelHeight;
static CGFloat kCDMessageLabelHeight;


@interface CDChatListRoomCell ()

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) JSBadgeView *badgeView;
@property (nonatomic, strong) UILabel *timestampLabel;

@end

@implementation CDChatListRoomCell


+ (NSString *)identifier {
    return NSStringFromClass([CDChatListRoomCell class]);
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

#pragma mark

- (NSString *)getMessageTitle:(AVIMTypedMessage *)msg {
    NSString *title;
    AVIMLocationMessage *locationMsg;
    switch (msg.mediaType) {
        case kAVIMMessageMediaTypeText:
            title = [CDEmotionUtils emojiStringFromString:msg.text];
            break;
            
        case kAVIMMessageMediaTypeAudio:
            title = @"声音";
            break;
            
        case kAVIMMessageMediaTypeImage:
            title = @"图片";
            break;
            
        case kAVIMMessageMediaTypeLocation:
            locationMsg = (AVIMLocationMessage *)msg;
            title = locationMsg.text;
            break;
        default:
            break;
    }
    return title;
}


- (void)setRoom:(CDRoom *)room {
    _room = room;
    
    if (room.conv.type == CDConvTypeSingle) {
        id <CDUserModel> user = [[CDIMConfig config].userDelegate getUserById:room.conv.otherId];
        self.nameLabel.text = user.username;
        [self.avatarImageView setImageWithURL:[NSURL URLWithString:user.avatarUrl]];
    }
    else {
        [self.avatarImageView setImage:room.conv.icon];
        self.nameLabel.text = room.conv.displayName;
    }
    self.messageLabel.text = [self getMessageTitle:room.lastMsg];
    
    if (room.unreadCount > 0) {
        self.badgeView.badgeText = [NSString stringWithFormat:@"%ld", (long)room.unreadCount];
    }
    else {
        self.badgeView.badgeText = nil;
    }
    if (room.lastMsg) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM-dd HH:mm"];
        NSString *timeString = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:room.lastMsg.sendTimestamp / 1000]];
        self.timestampLabel.text = timeString;
    }
    else {
        self.timestampLabel.text = @"";
    }
}

- (void)awakeFromNib {
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
