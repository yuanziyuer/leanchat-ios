//
//  CDFileService.h
//  LeanChat
//
//  Created by lzw on 15/1/23.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CDFileService : NSObject

+(NSString*)getPathByObjectId:(NSString*)objectId;

+(NSString*)tmpPath;

@end
