//
//  ClientAccount.m
//  PhoneBookBag
//
//  Created by 吴海超 on 15/7/6.
//  Copyright (c) 2015年 吴海超. All rights reserved.
//

/*
 *  qq:712641411
 *  iOS大神qq群:460122071
 *  gitHub:https://github.com/netyouli
 *  csdn:http://blog.csdn.net/windwhc/article/category/3117381
 */

#import "WHC_ClientAccount.h"
#import "WHC_DownloadFileCenter.h"

#define kLoginInfo        (@"LoginInfo")
#define kLoginState       (@"LoginState")
#define kLaunchLoginState (@"LaunchLoginState")
#define kAccountType      (@"AccountType")
#define kAccountPswPlist  (@"AccountPsw.plist")
@implementation WHC_ClientAccount

static WHC_ClientAccount   * _clientAccount = nil;

+ (instancetype)sharedClientAccount{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _clientAccount = [WHC_ClientAccount new];
    });
    return _clientAccount;
}

- (NSString *)videoFolder{
    return [NSString stringWithFormat:@"%@/Library/Caches/WHCVideo/",NSHomeDirectory()];
}

- (NSString *)docFileFolder{
    return [NSString stringWithFormat:@"%@/Library/Caches/WHCFile/",NSHomeDirectory()];
}


- (NSString *)videoFileRecordPath{
    NSFileManager * fm = [NSFileManager defaultManager];
    NSString  * fileDirectory = [NSString stringWithFormat:@"%@/Library/Caches/WHCPlist/",NSHomeDirectory()];
    if(![fm fileExistsAtPath:fileDirectory]){
        [fm createDirectoryAtPath:fileDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [fileDirectory stringByAppendingPathComponent:@"DownloadRecord.plist"];
}


- (BOOL)existFileName:(NSString *)fileName{
    NSFileManager  * fileManager = [NSFileManager defaultManager];
    NSError        * error = nil;
    NSArray * fileArr = [[fileManager contentsOfDirectoryAtPath:self.videoFolder error:&error] mutableCopy];
    if(fileArr){
        for (NSString * tempFileName in fileArr){
            if([tempFileName isEqualToString:fileName]){
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)downloadStateVoideFile:(NSString *)fileName{
    NSDictionary * downloadRecordDict = [NSMutableDictionary dictionaryWithContentsOfFile:self.videoFileRecordPath];
    NSDictionary * dict = downloadRecordDict[fileName];
    if(dict && [dict[@"state"] integerValue] == Downloading){
        return YES;
    }
    return NO;
}

- (void)saveDownloadRecord{
    NSArray  * downloadArr = [WHCDownloadCenter downloadList];
    NSMutableDictionary * downloadRecordDict = [NSMutableDictionary dictionaryWithContentsOfFile:self.videoFileRecordPath];
    for (WHC_Download * download in downloadArr) {
        NSMutableDictionary * dict = downloadRecordDict[download.saveFileName];
        CGFloat  percent = (CGFloat)(download.downloadLen) / download.totalLen * 100.0;
        if(dict == nil){
            [downloadRecordDict setObject:@{@"fileName":download.saveFileName,
                                            @"currentDownloadLen":[NSString stringWithFormat:@"%.1fMB",((CGFloat)(download.downloadLen) / kWHC_1MB)],
                                            @"totalLen":[NSString stringWithFormat:@"%.1fMB",((CGFloat)(download.totalLen) / kWHC_1MB)],
                                            @"speed":@"0KB/S",
                                            @"processValue":@(percent / 100.0),
                                            @"downPath":download.downPath,
                                            @"state":@(DownloadUncompleted)}.mutableCopy forKey:download.saveFileName];
            [downloadRecordDict writeToFile:self.videoFileRecordPath atomically:YES];
        }else{
            [dict setObject:([NSString stringWithFormat:@"%.1fMB",((CGFloat)(download.downloadLen) / kWHC_1MB)]).copy forKey:@"currentDownloadLen"];
            [dict setObject:[NSString stringWithFormat:@"%.1fMB",((CGFloat)(download.totalLen) / kWHC_1MB)] forKey:@"totalLen"];
            [dict setObject:@(percent / 100.0) forKey:@"processValue"];
            [dict setObject:@(DownloadUncompleted) forKey:@"state"];
            if([dict[@"downPath"] isEqualToString:@""]){
                [dict setObject:download.downPath forKey:@"downPath"];
            }
            [downloadRecordDict setObject:dict forKey:download.saveFileName];
            [downloadRecordDict writeToFile:self.videoFileRecordPath atomically:YES];
        }
        
    }
}

@end
