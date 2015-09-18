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

#define kWHC_DefaultMaxDownloadCount      (2)            //默认最大并发下载数量
#define kWHC_1MB                          (1024 * 1024)  //一兆
@class WHC_DownloadFileCenter;

#define WHCDownloadCenter  ([WHC_DownloadFileCenter sharedWHCDownloadFileCenter])
@interface WHC_DownloadFileCenter : NSObject

+ (instancetype)sharedWHCDownloadFileCenter;
//获取下载列表
- (NSArray *)downloadList;

//是否存在取消的下载
- (BOOL)existCancelDownload;

//返回指定文件名下载对象
- (WHC_Download *)downloadWithFileName:(NSString *)fileName;
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
- (WHC_Download *)recoverDownloadWithName:(NSString *)fileName delegate:(id)delegate;


/**
 说明：
 恢复指暂停下载url的下载并返回新下载
 */
- (WHC_Download *)recoverDownloadWithDownUrl:(NSURL *)downUrl delegate:(id)delegate;

/**
 说明：
 恢复指定暂停的下载并返回新下载
 */

- (WHC_Download *)recoverDownload:(WHC_Download *)download delegate:(id)delegate;

/**
 说明：
 恢复所有暂停的下载并返回新下载集合
 */
- (NSArray *)recoverAllDownloadTaskDelegate:(id)delegate;

/**
 说明：
 替换当前代理通过要下载的文件名
 使用情景:(当从控制器B进入到控制器C然后在控制器C中进行下载，然后下载过程中突然退出到控制器B，
 在又进入到控制器C，这个时候还是在下载但是代理对象和之前的那个控制器C不是一个对象所以要替换)
 */
- (BOOL)replaceCurrentDownloadDelegate:(id)delegate fileName:(NSString *)fileName;

//替换所有当前下载代理
- (BOOL)replaceCurrentDownloadDelegate:(id)delegate;

/**
 说明：
 通过要下载的文件名来判断当前是否在进行下载任务
 */
- (BOOL)currentIsDownloadTaskWithFileName:(NSString *)fileName;

/**
 note:该方法必须在开始下载之前调用
 说明：
 设置最大下载数量
 */
- (void)setMaxDownloadCount:(NSUInteger)count;

/**
 说明:返回下载中心最大同时下载操作个数
 */
- (NSInteger)maxDownloadCount;

//获取要下载的文件格式
- (NSString *)fileFormat:(NSString *)downloadUrl;
@end
