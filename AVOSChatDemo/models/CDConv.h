//
//  CDConvUtils.h
//  LeanChat
//
//  Created by lzw on 15/1/27.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CONV_TYPE @"type"

@interface CDConv : NSObject

typedef enum : NSUInteger {
    CDConvTypeSingle = 0,
    CDConvTypeGroup=1,
} CDConvType;

@end
