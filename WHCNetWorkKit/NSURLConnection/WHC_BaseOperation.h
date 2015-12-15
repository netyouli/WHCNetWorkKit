//
//  WHC_BaseOperation.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern  NSTimeInterval const kWHCRequestTimeout;
extern  NSTimeInterval const kWHCDownloadSpeedDuring;
extern  CGFloat   const kWHCWriteSizeLenght;

extern  NSString * const _Nullable kWHCDomain;
extern  NSString * const _Nullable kWHCInvainUrlError;
extern  NSString * const _Nullable kWHCCalculateFolderSpaceAvailableFailError;
extern  NSString * const _Nullable kWHCErrorCode;
extern  NSString * const _Nullable kWHCFreeDiskSapceError;
extern  NSString * const _Nullable kWHCRequestRange;
extern  NSString * const _Nullable kWHCUploadCode;

/**
 * WHCHttpRequestStatus  网络请求状态枚举标识
 */

typedef NS_OPTIONS(NSUInteger, WHCHttpRequestStatus) {
    WHCHttpRequestNone = 1 << 0,
    WHCHttpRequestExecuting = 1 << 1,
    WHCHttpRequestCanceled = 1 << 2,
    WHCHttpRequestFinished = 1 << 3
};

/**
 * WHCHttpRequestStatus  网络请求类型枚举标识
 */

typedef NS_OPTIONS(NSUInteger, WHCHttpRequestType) {
    WHCHttpRequestGet = 1 << 4,
    WHCHttpRequestPost = 1 << 5,
    WHCHttpRequestFileDownload = 1 << 6,
    WHCHttpRequestFileUpload = 1 << 7
};


/**
 * WHCHttpRequestStatus  网络请求错误枚举标识
 */

typedef NS_OPTIONS(NSUInteger, WHCHttpErrorType) {
    WHCFreeDiskSpaceLack = 2 << 0,
    WHCGeneralError = 2 << 1,
    WHCCancelDownloadError = 2 << 2,
    WHCNetWorkError = 2 << 3
};

@class WHC_BaseOperation;
@class WHC_DownloadOperation;

/**
 * WHC_DownloadDelegate  网络下载回调代理
 */

@protocol  WHC_DownloadDelegate<NSObject>

@optional

/**
 * 下载应答回调方法
 * @param: operation 当前下载操作对象
 * @param: error 响应错误对象
 * @param: isOK 是否可以下载
 */

- (void)WHCDownloadResponse:(nonnull WHC_DownloadOperation *)operation
                      error:(nullable NSError *)error
                         ok:(BOOL)isOK;

/**
 * 下载过程回调方法
 * @param: operation 当前下载操作对象
 * @param: recvLength 当前接收下载字节数
 * @param: totalLength 总字节数
 * @param: speed 下载速度
 */

- (void)WHCDownloadProgress:(nonnull WHC_DownloadOperation *)operation
                       recv:(uint64_t)recvLength
                      total:(uint64_t)totalLength
                      speed:(nullable NSString *)speed;

/**
 * 下载结束回调方法
 * @param: operation 当前下载操作对象
 * @param: data 当前接收数据 （在requestType = WHCHttpRequestGet 该参数才有用 否则为nil）
 * @param: error 下载错误对象
 * @param: success 下载是否成功
 */

- (void)WHCDownloadDidFinished:(nonnull WHC_DownloadOperation *)operation
                          data:(nullable NSData *)data
                         error:(nullable NSError *)error
                       success:(BOOL)isSuccess;

@end


/**
 * 下载结束回调块
 * @param: operation 当前下载操作对象
 * @param: data 当前接收数据 （在requestType = WHCHttpRequestGet 该参数才有用 否则为nil）
 * @param: error 下载错误对象
 * @param: success 下载是否成功
 */

typedef void (^WHCDidFinished) (WHC_BaseOperation * _Nullable operation ,NSData * _Nullable data ,  NSError * _Nullable  error , BOOL isSuccess);

/**
 * 下载应答回调块
 * @param: operation 当前下载操作对象
 * @param: error 响应错误对象
 * @param: isOK 是否可以下载
 */

typedef void (^WHCResponse)(WHC_BaseOperation * _Nullable operation , NSError * _Nullable error ,BOOL isOK);

/**
 * 下载过程回调块
 * @param: operation 当前下载操作对象
 * @param: recvLength 当前接收下载字节数
 * @param: totalLength 总字节数
 * @param: speed 下载速度
 */

typedef void (^WHCProgress) (WHC_BaseOperation * _Nullable operation ,uint64_t recvLength , uint64_t totalLength , NSString * _Nullable speed);


/**
 * 说明: WHC_BaseOperation http网络操作对象基类,封装了底层通用操作细节共上层网络操作服务
 */
@interface WHC_BaseOperation : NSOperation <NSURLConnectionDataDelegate , NSURLConnectionDelegate>

/**
 * 网络参数编码类型
 */
@property (nonatomic , assign) NSUInteger     encoderType;

/**
 * 网络请求超时时长
 */
@property (nonatomic , assign) NSTimeInterval timeoutInterval;

/**
 * 网络请求缓存策略
 */
@property (nonatomic , assign) NSURLRequestCachePolicy cachePolicy;

/**
 * 网络请求Url
 */
@property (nonatomic , copy , nonnull) NSString * strUrl;

/**
 * 网络请求内容类型
 */
@property (nonatomic , copy , nonnull) NSString * contentType;

/**
 * POST网络请求参数
 */
@property (nonatomic , copy , nonnull) NSObject * postParam;

/**
 * http网络请求类型
 */
@property (nonatomic , assign) WHCHttpRequestType requestType;

/**
 * http网络请求对象
 */
@property (nonatomic , strong , nullable)NSMutableURLRequest     * urlRequest;

/**
 * http网络请求连接对象
 */
@property (nonatomic , strong , nullable)NSURLConnection         * urlConnection;

/**
 * http网络请求状态
 */
@property (nonatomic , assign)WHCHttpRequestStatus      requestStatus;

/**
 * http网络请求应答数据对象
 */
@property (nonatomic , strong , nullable)NSMutableData           * responseData;

/**
 * http网络请求应答数据对象长度
 */
@property (nonatomic , assign)uint64_t    responseDataLenght;

/**
 * http网络请求定时获取的数据长度
 */
@property (nonatomic , assign)uint64_t    orderTimeDataLenght;

/**
 * http网络请求接收的数据长度
 */
@property (nonatomic , assign)uint64_t    recvDataLenght;

/**
 * http网络下载时下载速度
 */

@property (nonatomic , strong , nullable)NSString  * networkSpeed;

/**
 * 下载完成回调块对象
 */
@property (nonatomic , copy , nullable )WHCDidFinished didFinishedBlock;

/**
 * 下载过程回调块对象
 */
@property (nonatomic , copy , nullable)WHCProgress progressBlock;

/**
 * 下载应答回调块对象
 */
@property (nonatomic, copy , nullable)WHCResponse responseBlock;

/**
 * 下载操作代理对象
 */
@property (nonatomic , weak)id<WHC_DownloadDelegate> delegate;

/**
 * 说明: 清空http 应答数据
 */
- (void)clearResponseData;


/**
 * 说明: 开始http请求
 */
- (void)startRequest;

/**
 * 说明: 开始http请求开启网速监控时钟
 */
- (void)startSpeedTimer;

/**
 * 说明: 结束http请求
 */
- (void)endRequest;

/**
 * 说明: 取消http请求
 */
- (void)cancelledRequest;

/**
 * 通用处理http应答错误
 * @param: response 当前网络操作应答对象
 */
- (BOOL)handleResponseError:(nullable NSURLResponse * )response;

/**
 * 添加依赖下载队列
 * @param: downloadOperation 将要添加的下载队列对象
 */
- (void)addDependOperation:(nonnull WHC_BaseOperation *)operation;

/**
 * 通用处理http请求过程错误
 * @param: error 当前网络错误对象
 * @param: code  错误代码
 */
- (void)handleReqeustError:(nullable NSError *)error code:(NSInteger)code;

/**
 * 说明: 计算网络速度
 */
- (void)calculateNetworkSpeed;


@end
