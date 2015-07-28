//
//  WHC_DownFileCenter.h
//  PhoneBookBag
//
//  Created by 吴海超 on 15/7/27.
//  Copyright (c) 2015年 吴海超. All rights reserved.
//

/*
 *  qq:712641411
 *  iOS大神qq群:460122071
 *  gitHub:https://github.com/netyouli
 *  csdn:http://blog.csdn.net/windwhc/article/category/3117381
 */

#import <Foundation/Foundation.h>
#import "WHC_Download.h"

#define kWHC_DefaultMaxDownloadCount      (3)       //默认最大并发下载数量
@class WHC_DownloadFileCenter;

#define WHCDownloadCenter  ([WHC_DownloadFileCenter sharedWHCDownloadFileCenter])
@interface WHC_DownloadFileCenter : NSObject

+ (instancetype)sharedWHCDownloadFileCenter;

/**
 参数说明：
 url:下载路径
 savePath:文件本地存储路径
 delegate:下载状态监控代理
 */

- (WHC_Download *)startDownloadWithURL:(NSURL *)url
                              savePath:(NSString *)savePath
                              delegate:(id<WHCDownloadDelegate>)delegate;

/**
 参数说明：
 url:下载路径
 savePath:文件本地存储路径
 savefileName:下载要存储的文件名
 delegate:下载状态监控代理
 */
- (WHC_Download *)startDownloadWithURL:(NSURL *)url
                              savePath:(NSString *)savePath
                          savefileName:(NSString*)savefileName
                                delegate:(id<WHCDownloadDelegate>)delegate;


/**
 说明：
 在外部创建下载队列进行下载
 */
- (WHC_Download *)startDownloadWithWHCDownload:(WHC_Download *)download;

/**
 说明：
 取消所有正等待下载并是否取消删除文件
 */
- (void)cancelAllWaitDownloadTaskAndDelFile:(BOOL)isDel;

/**
 说明：
 取消指定正等待下载url的下载
 */
- (void)cancelWaitDownloadWithDownUrl:(NSURL *)downUrl delFile:(BOOL)delFile;

/**
 说明：
 取消指定正等待下载文件名的下载
 */
- (void)cancelWaitDownloadWithFileName:(NSString *)fileName delFile:(BOOL)delFile;

/**
 说明：
 取消所有正在下载并是否取消删除文件
 */
- (void)cancelAllDownloadTaskAndDelFile:(BOOL)isDel;

/**
 说明：
 取消指定正在等待下载url的下载
 */
- (void)cancelDownloadWithDownUrl:(NSURL *)downUrl delFile:(BOOL)delFile;

/**
 说明：
 取消指定正在等待下载文件名的下载
 */
- (void)cancelDownloadWithFileName:(NSString *)fileName delFile:(BOOL)delFile;

/**
 说明：
 恢复指定暂停正下载文件名的下载并返回新下载
 */
- (WHC_Download *)recoverDownloadWithName:(NSString *)fileName;


/**
 说明：
 恢复指暂停下载url的下载并返回新下载
 */
- (WHC_Download *)recoverDownloadWithDownUrl:(NSURL *)downUrl;

/**
 说明：
 恢复指定暂停的下载并返回新下载
 */

- (WHC_Download *)recoverDownload:(WHC_Download *)download;

/**
 说明：
 恢复所有暂停的下载并返回新下载集合
 */
- (NSArray *)recoverAllDownloadTask;


/**
 note:该方法必须在开始下载之前调用
 说明：
 设置最大下载数量
 */
- (void)setMaxDownloadCount:(NSUInteger)count;
@end
