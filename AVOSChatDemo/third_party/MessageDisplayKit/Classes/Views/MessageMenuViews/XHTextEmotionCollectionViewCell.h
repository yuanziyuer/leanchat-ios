//
//  XHTextEmotionCollectionViewCell.h
//  LeanChat
//
//  Created by lzw on 14/11/25.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XHTextEmotion.h"

#define kXHTextEmotionCollectionViewCellIdentifier @"kXHTextEmotionCollectionViewCellIdentifier"

@interface XHTextEmotionCollectionViewCell : UICollectionViewCell

@property (nonatomic,weak) XHTextEmotion* textEmotion;

@end
