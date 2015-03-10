//
//  CDAVUtils.m
//  LeanChat
//
//  Created by lzw on 15/3/9.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDAVUtils.h"

@implementation CDAVUtils

+(void)setPolicyOfAVQuery:(AVQuery*)query isNetwokOnly:(BOOL)onlyNetwork{
    [query setCachePolicy:onlyNetwork ? kAVCachePolicyNetworkOnly : kAVCachePolicyNetworkElseCache];
}

@end
