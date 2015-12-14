//
//  WHC_DownloadObject.h
//  WHC_FileDownloadDemo
//
//  Created by 吴海超 on 15/11/27.
//  Copyright © 2015年 吴海超. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, WHCDownloadState) {
    WHCNone = 1 << 0,
    WHCDownloading = 1 << 1,
    WHCDownloadCompleted = 1 << 2,
    WHCDownloadCanceled = 1 << 3,
    WHCDownloadWaitting = 1 << 4
};

@interface WHC_DownloadObject : NSObject<NSCoding>

@property (nonatomic , copy) NSString * fileName;
@property (nonatomic , copy) NSString * downloadSpeed;
@property (nonatomic , copy) NSString * downloadPath;
@property (nonatomic , assign) UInt64 totalLenght;
@property (nonatomic , assign) UInt64 currentDownloadLenght;
@property (nonatomic , assign , readonly) float downloadProcessValue;
@property (nonatomic , assign) WHCDownloadState downloadState;
@property (nonatomic , copy , readonly)NSString * currentDownloadLenghtToString;
@property (nonatomic , copy , readonly)NSString * totalLenghtToString;
@property (nonatomic , copy , readonly)NSString * downloadProcessText;
@property (nonatomic , copy) NSString * etag;
+ (NSString *)cacheDirectory;
+ (NSString *)cachePlistDirectory;
+ (NSString *)cachePlistPath;
+ (NSString *)videoDirectory;

+ (WHC_DownloadObject *)readDiskCache:(NSString *)downloadPath;

+ (NSArray *)readDiskAllCache;

- (void)writeDiskCache;

- (void)removeFromDisk;
@end
