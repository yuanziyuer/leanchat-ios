//
//  CDFileService.m
//  LeanChat
//
//  Created by lzw on 15/1/23.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDFileService.h"

@implementation CDFileService

+(NSString*)getFilesPath{
    NSString* appPath=[NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* filesPath=[appPath stringByAppendingString:@"/files/"];
    NSFileManager *fileMan=[NSFileManager defaultManager];
    NSError *error;
    BOOL isDir=YES;
    if([fileMan fileExistsAtPath:filesPath isDirectory:&isDir]==NO){
        [fileMan createDirectoryAtPath:filesPath withIntermediateDirectories:YES attributes:nil error:&error];
        if(error){
            [NSException raise:@"error when create dir" format:@"error"];
        }
    }
    return filesPath;
}

+(NSString*)getPathByObjectId:(NSString*)objectId{
    return [[self getFilesPath] stringByAppendingFormat:@"%@",objectId];
}


@end
