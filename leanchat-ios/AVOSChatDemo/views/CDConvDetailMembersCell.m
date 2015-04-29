//
//  CDConvDetailMembersHeaderView.m
//  LeanChat
//
//  Created by lzw on 15/4/20.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDConvDetailMembersCell.h"
#import "CDCache.h"
#import "CDUserService.h"
#import "CDConvDetailMembersSubCell.h"

static NSString* kCDConvDetailMembersHeaderViewCellIndentifer=@"memberCell";

@interface CDConvDetailMembersCell ()<UICollectionViewDataSource,UICollectionViewDelegate,UIGestureRecognizerDelegate>

@property (nonatomic,strong) UICollectionView *membersCollectionView;

@end

@implementation CDConvDetailMembersCell

+(NSString*)reuseIdentifier{
    return NSStringFromClass([CDConvDetailMembersCell class]);
}

+(CGFloat)heightForMembers:(NSArray*)members{
    if(members==0){
        return 0;
    }
    NSInteger column=(CGRectGetWidth([UIScreen mainScreen].bounds)-kCDConvDetailMembersCellInterItemSpacing)/([CDConvDetailMembersSubCell widthForCell]+kCDConvDetailMembersCellInterItemSpacing);
    NSInteger rows=members.count/column+(members.count%column? 1:0);
    return rows*[CDConvDetailMembersSubCell heightForCell]+(rows+1)*kCDConvDetailMembersCellLineSpacing;
}

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self=[super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self){
        [self.contentView addSubview:self.membersCollectionView];
    }
    return self;
}

-(UICollectionView*)membersCollectionView{
    if(_membersCollectionView==nil){
        UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
        layout.minimumLineSpacing=kCDConvDetailMembersCellLineSpacing;
        layout.minimumInteritemSpacing=kCDConvDetailMembersCellInterItemSpacing;
        layout.itemSize=CGSizeMake([CDConvDetailMembersSubCell widthForCell], [CDConvDetailMembersSubCell heightForCell]);
        _membersCollectionView=[[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        [_membersCollectionView registerClass:[CDConvDetailMembersSubCell class] forCellWithReuseIdentifier:kCDConvDetailMembersHeaderViewCellIndentifer];
        _membersCollectionView.backgroundColor=[UIColor whiteColor];
        _membersCollectionView.showsVerticalScrollIndicator=YES;
        _membersCollectionView.delegate=self;
        _membersCollectionView.dataSource=self;
        UILongPressGestureRecognizer* gestureRecognizer=[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressUser:)];
        gestureRecognizer.delegate=self;
        [_membersCollectionView addGestureRecognizer:gestureRecognizer];
    }
    return _membersCollectionView;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    self.membersCollectionView.frame=CGRectMake(kCDConvDetailMembersCellInterItemSpacing, kCDConvDetailMembersCellLineSpacing, CGRectGetWidth(self.frame)-2*kCDConvDetailMembersCellInterItemSpacing, CGRectGetHeight(self.frame)-2*kCDConvDetailMembersCellLineSpacing);
}

-(void)setMembers:(NSArray *)members{
    _members=members;
    [self.membersCollectionView reloadData];
    [self setNeedsLayout];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.members.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CDConvDetailMembersSubCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCDConvDetailMembersHeaderViewCellIndentifer forIndexPath:indexPath];
    AVUser* user=[self.members objectAtIndex:indexPath.row];
    [CDUserService displayAvatarOfUser:user avatarView:cell.avatarImageView];
    cell.usernameLabel.text=user.username;
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    AVUser* user=[self.members objectAtIndex:indexPath.row];
    if([self.membersCellDelegate respondsToSelector:@selector(didSelectMember:)]){
        [self.membersCellDelegate didSelectMember:user];
    }
    return YES;
}

#pragma mark - Gesture

-(void)longPressUser:(UILongPressGestureRecognizer*)gestureRecognizer{
    if(gestureRecognizer.state!=UIGestureRecognizerStateBegan){
        return;
    }
    CGPoint p=[gestureRecognizer locationInView:self.membersCollectionView];
    NSIndexPath* indexPath=[self.membersCollectionView indexPathForItemAtPoint:p];
    if(indexPath==nil){
        DLog(@"can't not find index path");
    }else{
        if([self.membersCellDelegate respondsToSelector:@selector(didLongPressMember:)]){
            [self.membersCellDelegate didLongPressMember:self.members[indexPath.row]];
        }
    }
}


@end
