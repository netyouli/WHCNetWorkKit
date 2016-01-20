//
//  WHC_DownloadOperation.h
//  WHCNetWorkKit
//
//  Created by 吴海超 on 15/11/6.
//  Copyright © 2015年 吴海超. All rights reserved.
//

/*
 *  qq:712641411
 *  gitHub:https://github.com/netyouli
 *  csdn:http://blog.csdn.net/windwhc/article/category/3117381
 */

#import "WHC_BaseOperation.h"


@interface WHC_DownloadOperation : WHC_BaseOperation

/**
 * 下载操作下标
 */

@property (nonatomic , assign)NSInteger index;
/**
 * 保存文件路径
 */
@property (nonatomic , copy)NSString       *   saveFilePath;

/**
 * 保存文件名
 */
@property (nonatomic , copy)NSString       *   saveFileName;
/**
 * 下载是否完成标记
 */
@property (nonatomic , assign , readonly)BOOL               isDownloadCompleted;
/**
 * 文件实际总长度
 */
@property (nonatomic , assign , readonly)uint64_t           fileTotalLenght;
/**
 * 文件实际总长度
 */
@property (nonatomic , assign)uint64_t                      actualFileSizeLenght;
/**
 * 本地缓存文件总长度
 */
@property (nonatomic , assign)uint64_t                      localFileLenght;

/**
 * 下载任务是否删除
 */
@property (nonatomic , assign)BOOL isDeleted;

/**
 * 函数说明: 取消当前下载任务
 * @param: isDelete 取消下载任务的同时是否删除下载缓存的文件
 */

- (void)cancelDownloadTaskAndDeleteFile:(BOOL)isDelete;

/**
 * 函数说明: 下载请求响应
 * @param: response 下载请求应答对象
 */

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
@end
