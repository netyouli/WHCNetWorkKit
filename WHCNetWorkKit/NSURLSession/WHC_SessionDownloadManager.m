//
//  WHC_SessionDownloadOperation.m
//  WHCNetWorkKit
//
//  Created by 吴海超 on 15/11/30.
//  Copyright © 2015年 吴海超. All rights reserved.
//
/*
 *  qq:712641411
 *  gitHub:https://github.com/netyouli
 *  csdn:http://blog.csdn.net/windwhc/article/category/3117381
 */
#import "WHC_SessionDownloadManager.h"
#import "WHC_DownloadSessionTask.h"
#import "WHC_HttpManager.h"


@interface WHC_SessionDownloadManager () <NSURLSessionDataDelegate , NSURLSessionDelegate>{
    NSOperationQueue *  _asynQueue;
    NSURLSession     *  _downloadSession;
    NSMutableArray   *  _downloadTaskArr;
    NSMutableDictionary * _resumeDataDictionary;
    NSFileManager    *  _fileManager;
    NSMutableDictionary * _etagDictionary;
    NSString * _resumeDataPath;
}

@end

@implementation WHC_SessionDownloadManager

+ (instancetype)shared {
    static WHC_SessionDownloadManager * downloadManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadManager = [WHC_SessionDownloadManager new];
    });
    return downloadManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _asynQueue = [NSOperationQueue new];
        _asynQueue.maxConcurrentOperationCount = kWHCDefaultDownloadNumber;
        _downloadTaskArr = [NSMutableArray array];
        _resumeDataDictionary = [NSMutableDictionary dictionary];
        _fileManager = [NSFileManager defaultManager];
        _etagDictionary = [NSMutableDictionary dictionary];
        _resumeDataPath = [NSString stringWithFormat:@"%@/Library/Caches/WHCResumeDataCache/",NSHomeDirectory()];
        BOOL isDirectory = YES;
        if (![_fileManager fileExistsAtPath:_resumeDataPath isDirectory:&isDirectory]) {
            [_fileManager createDirectoryAtPath:_resumeDataPath
          withIntermediateDirectories:YES
                           attributes:@{NSFileProtectionKey:NSFileProtectionNone} error:nil];
        }
    }
    return self;
}

- (void)setBundleIdentifier:(nonnull NSString *)identifier {
    if (_downloadSession == nil) {
        _bundleIdentifier = nil;
        _bundleIdentifier = identifier.copy;
        NSURLSessionConfiguration * configuration;
        if ([NSURLSessionConfiguration respondsToSelector:@selector(backgroundSessionConfigurationWithIdentifier:)]){
            configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:_bundleIdentifier];
        }else {
            configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:_bundleIdentifier];
        }
        configuration.discretionary = YES;
        _downloadSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:_asynQueue];
        
    }
}

- (BOOL)waitingDownload {
    return _asynQueue.operations.count > kWHCDefaultDownloadNumber;
}

#pragma mark - 下载对外接口

- (nullable WHC_DownloadSessionTask *)download:(nonnull NSString *)strUrl
                                    savePath:(nonnull NSString *)savePath
                                    delegate:(nullable id<WHC_DownloadDelegate>)delegate {
    return [self download:strUrl savePath:savePath saveFileName:nil delegate:delegate];
}


- (nullable WHC_DownloadSessionTask *)download:(nonnull NSString *)strUrl
                                    savePath:(nonnull NSString *)savePath
                                saveFileName:(nullable NSString *)saveFileName
                                    delegate:(nullable id<WHC_DownloadDelegate>)delegate {
    WHC_DownloadSessionTask  * downloadTask = nil;
    NSString * fileName = nil;
    if (strUrl != nil && ![[WHC_HttpManager shared].failedUrls containsObject:strUrl]) {
        fileName = [[WHC_HttpManager shared] handleFileName:saveFileName url:strUrl];
        for (WHC_DownloadSessionTask * tempDownloadTask in _downloadTaskArr) {
            if ([fileName isEqualToString: tempDownloadTask.saveFileName]){
                __autoreleasing NSError * error = [[WHC_HttpManager shared] error:[NSString stringWithFormat:@"%@:已经在下载中",fileName]];
                if (delegate && [delegate respondsToSelector:@selector(WHCDownloadResponse:error:ok:)]) {
                    [delegate WHCDownloadResponse:tempDownloadTask error:error ok:NO];
                } else if (delegate && [delegate respondsToSelector:@selector(WHCDownloadDidFinished:data:error:success:)]) {
                    [delegate WHCDownloadDidFinished:tempDownloadTask data:nil error:error success:NO];
                }
                return tempDownloadTask;
            }
        }
        if([[WHC_HttpManager shared] createFileSavePath:savePath]) {
            
            downloadTask = [WHC_DownloadSessionTask new];
            downloadTask.requestType = WHCHttpRequestFileDownload;
            downloadTask.saveFileName = fileName;
            downloadTask.saveFilePath = savePath;
            downloadTask.delegate = delegate;
            downloadTask.strUrl = strUrl;
            downloadTask.delegate = delegate;
            [self startDownload:downloadTask];
        }
    }else {
        __autoreleasing NSError * error = [[WHC_HttpManager shared] error:[NSString stringWithFormat:@"%@:请求失败",strUrl]];
        if (delegate &&
            [delegate respondsToSelector:@selector(WHCDownloadDidFinished:data:error:success:)]) {
            [delegate WHCDownloadDidFinished:downloadTask data:nil error:error success:NO];
        }
    }
    return downloadTask;
    
}

- (nullable WHC_DownloadSessionTask *)download:(nonnull NSString *)strUrl
                                    savePath:(nonnull NSString *)savePath
                                    response:(nullable WHCResponse)responseBlock
                                     process:(nullable WHCProgress)processBlock
                                 didFinished:(nullable WHCDidFinished)finishedBlock {
    return nil;
}

- (nullable WHC_DownloadSessionTask *)download:(nonnull NSString *)strUrl
                                    savePath:(nonnull NSString *)savePath
                                saveFileName:(nullable NSString *)saveFileName
                                    response:(nullable WHCResponse) responseBlock
                                     process:(nullable WHCProgress) processBlock
                                 didFinished:(nullable WHCDidFinished) finishedBlock {
    WHC_DownloadSessionTask  * downloadTask = nil;
    NSString * fileName = nil;
    if (strUrl != nil && ![[WHC_HttpManager shared].failedUrls containsObject:strUrl]) {
        fileName = [[WHC_HttpManager shared] handleFileName:saveFileName url:strUrl];
        for (WHC_DownloadSessionTask * tempDownloadTask in _downloadTaskArr) {
            if ([fileName isEqualToString:tempDownloadTask.saveFileName]){
                __autoreleasing NSError * error = [[WHC_HttpManager shared] error:[NSString stringWithFormat:@"%@:已经在下载中",fileName]];
                if (responseBlock) {
                    responseBlock(tempDownloadTask, error, NO);
                } else if (finishedBlock) {
                    finishedBlock(tempDownloadTask ,nil, error, NO);
                }
                return tempDownloadTask;
            }
        }
        if([[WHC_HttpManager shared] createFileSavePath:savePath]) {
            downloadTask = [WHC_DownloadSessionTask new];
            downloadTask.requestType = WHCHttpRequestFileDownload;
            downloadTask.saveFileName = fileName;
            downloadTask.saveFilePath = savePath;
            downloadTask.progressBlock = processBlock;
            downloadTask.responseBlock = responseBlock;
            downloadTask.strUrl = strUrl;
            downloadTask.didFinishedBlock = ^(WHC_BaseOperation *operation,
                                                   NSData *data,
                                                   NSError *error,
                                                   BOOL isSuccess) {
                if (!isSuccess && error.code == 404) {
                    [[WHC_HttpManager shared].failedUrls addObject:strUrl];
                }
                if (finishedBlock) {
                    finishedBlock(operation , data , error , isSuccess);
                }
            };
            [self startDownload:downloadTask];
        }
    }else {
        __autoreleasing NSError * error = [[WHC_HttpManager shared] error:[NSString stringWithFormat:@"%@:请求失败",strUrl]];
        if (responseBlock) {
            responseBlock(downloadTask , error , NO);
        }else if (finishedBlock) {
            finishedBlock(downloadTask , nil , error , NO);
        }
    }
    return downloadTask;
}

#pragma mark - 私有方法

- (NSString *)getResumeDataFilePath:(NSString *)fileName {
    if (fileName && fileName.length > 0) {
        return [NSString stringWithFormat:@"%@%@",_resumeDataPath , fileName];
    }
    return nil;
}


- (void)startDownload:(WHC_DownloadSessionTask *)downloadTask {
    if (_downloadSession) {
        NSString * resumeDataFilePath = [self getResumeDataFilePath:downloadTask.saveFileName];
        if (resumeDataFilePath && [_fileManager fileExistsAtPath:resumeDataFilePath]) {
            NSData * resumeData = [NSData dataWithContentsOfFile:resumeDataFilePath];
            downloadTask.downloadTask = [_downloadSession downloadTaskWithResumeData:resumeData];
        }else {
            NSURL * url = [NSURL URLWithString:downloadTask.strUrl];
            NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];
            downloadTask.downloadTask = [_downloadSession downloadTaskWithRequest:urlRequest];
        }
        [downloadTask startSpeedTimer];
        [downloadTask.downloadTask resume];
        [_downloadTaskArr addObject:downloadTask];
    }
}

- (void)cancelDownloadTask:(BOOL)isDelete task:(WHC_DownloadSessionTask *)task {
    if (!isDelete) {
        [task.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            // 存储恢复下载数据在didCompleteWithError处理
        }];
    }else {
        [task cancelDownloadTaskAndDeleteFile:isDelete];
    }
}

#pragma mark - 下载过程对外接口

- (nullable WHC_DownloadSessionTask *)downloadOperationWithFileName:(nonnull NSString *)fileName {
    WHC_DownloadSessionTask * downloadTask = nil;
    for (WHC_DownloadSessionTask * tempDownloadTask in _downloadTaskArr) {
        if([tempDownloadTask.saveFileName isEqualToString:fileName]) {
            downloadTask = tempDownloadTask;
            break;
        }
    }
    return downloadTask;
}

- (void)cancelAllDownloadTaskAndDelFile:(BOOL)isDelete {
    for (WHC_DownloadSessionTask * task in _downloadTaskArr) {
        [self cancelDownloadTask:isDelete task:task];
    }
}

- (void)cancelDownloadWithDownloadUrl:(nonnull NSString *)strUrl deleteFile:(BOOL)isDelete {
    for(WHC_DownloadSessionTask * task in _downloadTaskArr){
        if ([task.strUrl isEqualToString:strUrl]) {
            [self cancelDownloadTask:isDelete task:task];
            break;
        }
    }
}

- (void)cancelDownloadWithFileName:(nonnull NSString *)fileName deleteFile:(BOOL)isDelete {
    for(WHC_DownloadSessionTask * task in _downloadTaskArr){
        if([task.saveFileName isEqualToString:fileName]){
            [self cancelDownloadTask:isDelete task:task];
            break;
        }
    }
}

- (WHC_DownloadSessionTask *)replaceCurrentDownloadOperationBlockResponse:(nullable WHCResponse)responseBlock
                                             process:(nullable WHCProgress)processBlock
                                         didFinished:(nullable WHCDidFinished)didFinishedBlock
                                            fileName:(nonnull NSString *)fileName {
    for (WHC_DownloadSessionTask * downloadTask in _downloadTaskArr) {
        if([downloadTask.saveFileName isEqualToString:fileName]){
            downloadTask.delegate = nil;
            downloadTask.progressBlock = processBlock;
            downloadTask.responseBlock = responseBlock;
            downloadTask.didFinishedBlock = didFinishedBlock;
            return downloadTask;
        }
    }
    return nil;
}

- (WHC_DownloadSessionTask *)replaceCurrentDownloadOperationDelegate:(nullable id<WHC_DownloadDelegate>)delegate
                                       fileName:(nonnull NSString *)fileName {
    for (WHC_DownloadSessionTask * downloadTask in _downloadTaskArr) {
        if([downloadTask.saveFileName isEqualToString:fileName]){
            downloadTask.progressBlock = nil;
            downloadTask.responseBlock = nil;
            downloadTask.didFinishedBlock = nil;
            downloadTask.delegate = delegate;
            return downloadTask;
        }
    }
    return nil;
}

- (WHC_DownloadSessionTask *)replaceAllDownloadOperationBlockResponse:(nullable WHCResponse)responseBlock
                                         process:(nullable WHCProgress)processBlock
                                     didFinished:(nullable WHCDidFinished)didFinishedBlock {
    if (_downloadTaskArr.count > 0) {
        for (WHC_DownloadSessionTask * downloadTask in _downloadTaskArr) {
            downloadTask.delegate = nil;
            downloadTask.progressBlock = processBlock;
            downloadTask.responseBlock = responseBlock;
            downloadTask.didFinishedBlock = didFinishedBlock;
        }
        return nil;
    }
    return nil;
}

- (WHC_DownloadSessionTask *)replaceAllDownloadOperationDelegate:(nullable id<WHC_DownloadDelegate>)delegate {
    if (_downloadTaskArr.count > 0) {
        for (WHC_DownloadSessionTask * downloadTask in _downloadTaskArr) {
            downloadTask.progressBlock = nil;
            downloadTask.responseBlock = nil;
            downloadTask.didFinishedBlock = nil;
            downloadTask.delegate = delegate;
        }
        return nil;
    }
    return nil;
}


- (BOOL)existDownloadOperationTaskWithFileName:(nonnull NSString *)fileName {
    BOOL  result = NO;
    for (WHC_DownloadSessionTask * downloadTask in _downloadTaskArr) {
        if([downloadTask.saveFileName isEqualToString:fileName]){
            result = YES;
            break;
        }
    }
    return result;
}

- (BOOL)existDownloadOperationTaskWithUrl:(nonnull NSString *)strUrl {
    BOOL  result = NO;
    for (WHC_DownloadSessionTask * downloadTask in _downloadTaskArr) {
        if([downloadTask.strUrl isEqualToString:strUrl]){
            result = YES;
            break;
        }
    }
    return result;
}


- (WHC_DownloadSessionTask *)getCurrentDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    WHC_DownloadSessionTask * whc_downloadTask = nil;
    for (WHC_DownloadSessionTask * tempDownloadTask in _downloadTaskArr) {
        if ([tempDownloadTask.downloadTask isEqual:downloadTask]) {
            whc_downloadTask = tempDownloadTask;
            break;
        }
    }
    return whc_downloadTask;
}

- (void)removeDownloadTask:(WHC_DownloadSessionTask *)downloadTask {
    downloadTask.delegate = nil;
    downloadTask.downloadTask = nil;
    downloadTask.responseBlock = nil;
    downloadTask.didFinishedBlock = nil;
    downloadTask.progressBlock = nil;
    [_downloadTaskArr removeObject:downloadTask];
}


- (void)saveDownloadFile:(NSString *)path downloadTask:(WHC_DownloadSessionTask *)downloadTask {
    if (path) {
        if ([_fileManager fileExistsAtPath:downloadTask.saveFilePath isDirectory:NULL]) {
            NSFileHandle * fileHandle = [NSFileHandle fileHandleForWritingAtPath:downloadTask.saveFilePath];
            [fileHandle seekToEndOfFile];
            NSData * data = [NSData dataWithContentsOfFile:path];
            if (data) {
                [fileHandle writeData:data];
                [fileHandle synchronizeFile];
                [fileHandle closeFile];
            }
        }else {
            [_fileManager moveItemAtPath:path toPath:downloadTask.saveFilePath error:NULL];
        }
    }
}

- (void)saveDidFinishDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                            toUrl:(NSURL *)location {
    WHC_DownloadSessionTask * whc_downloadTask = [self getCurrentDownloadTask:downloadTask];
    if (whc_downloadTask) {
        whc_downloadTask.actualFileSizeLenght = downloadTask.countOfBytesExpectedToReceive;
        whc_downloadTask.recvDataLenght = downloadTask.countOfBytesReceived;
        whc_downloadTask.requestStatus = WHCHttpRequestFinished;
        [self saveDownloadFile:location.path downloadTask:whc_downloadTask];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (whc_downloadTask.delegate &&
                [whc_downloadTask.delegate respondsToSelector:@selector(WHCDownloadProgress:recv:total:speed:)]) {
                [whc_downloadTask.delegate WHCDownloadProgress:whc_downloadTask
                                                          recv:downloadTask.countOfBytesReceived
                                                         total:downloadTask.countOfBytesExpectedToReceive
                                                         speed:whc_downloadTask.networkSpeed];
                if ([whc_downloadTask.delegate respondsToSelector:@selector(WHCDownloadDidFinished:data:error:success:)]) {
                    [whc_downloadTask.delegate WHCDownloadDidFinished:whc_downloadTask
                                                                 data:nil
                                                                error:nil
                                                              success:YES];
                }
            }else {
                if (whc_downloadTask.progressBlock) {
                    whc_downloadTask.progressBlock(whc_downloadTask ,
                                                   downloadTask.countOfBytesReceived ,
                                                   downloadTask.countOfBytesExpectedToReceive ,
                                                   whc_downloadTask.networkSpeed);
                }
                if (whc_downloadTask.didFinishedBlock) {
                    whc_downloadTask.didFinishedBlock(whc_downloadTask , nil , nil , YES);
                }
            }
            [self removeDownloadTask:whc_downloadTask];
        });
    }
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    [self saveDidFinishDownloadTask:downloadTask toUrl:location];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    WHC_DownloadSessionTask * whc_downloadTask = [self getCurrentDownloadTask:(NSURLSessionDownloadTask *)task];
    if (whc_downloadTask.delegate &&
        [whc_downloadTask.delegate respondsToSelector:@selector(WHCDownloadDidFinished:data:error:success:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error &&
                [error.userInfo[NSLocalizedDescriptionKey] isEqualToString:@"cancelled"]) {
                NSData * resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData];
                if (resumeData) {
                    [resumeData writeToFile:[self getResumeDataFilePath:whc_downloadTask.saveFileName] atomically:YES];
                }
                if (whc_downloadTask.delegate &&
                    [whc_downloadTask.delegate respondsToSelector:@selector(WHCDownloadDidFinished:data:error:success:)]) {
                    [whc_downloadTask.delegate WHCDownloadDidFinished:whc_downloadTask
                                                                 data:nil
                                                                error:error
                                                              success:NO];
                }else {
                    if (whc_downloadTask.didFinishedBlock) {
                        whc_downloadTask.didFinishedBlock(whc_downloadTask , nil , error , NO);
                    }
                }
                [self removeDownloadTask:whc_downloadTask];
            }
        });
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    WHC_DownloadSessionTask * whc_downloadTask = [self getCurrentDownloadTask:downloadTask];
    whc_downloadTask.recvDataLenght += bytesWritten;
    whc_downloadTask.orderTimeDataLenght += bytesWritten;
    if (whc_downloadTask.actualFileSizeLenght < 10) {
        whc_downloadTask.actualFileSizeLenght = totalBytesExpectedToWrite;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
       if (whc_downloadTask.delegate &&
           [whc_downloadTask.delegate respondsToSelector:@selector(WHCDownloadProgress:recv:total:speed:)]) {
           [whc_downloadTask.delegate WHCDownloadProgress:whc_downloadTask
                                                     recv:totalBytesWritten
                                                    total:totalBytesExpectedToWrite
                                                    speed:whc_downloadTask.networkSpeed];
       }else {
           if (whc_downloadTask.progressBlock) {
               whc_downloadTask.progressBlock(whc_downloadTask ,
                                              totalBytesWritten ,
                                              totalBytesExpectedToWrite ,
                                              whc_downloadTask.networkSpeed);
           }
       }
    });
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {
    WHC_DownloadSessionTask * whc_downloadTask = [self getCurrentDownloadTask:downloadTask];
    whc_downloadTask.orderTimeDataLenght = fileOffset;
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    WHC_DownloadSessionTask * whc_downloadTask = [self getCurrentDownloadTask:(NSURLSessionDownloadTask *)dataTask];
    [whc_downloadTask handleResponse:response];
    if (whc_downloadTask.requestStatus == WHCHttpRequestFinished ) {
        [self removeDownloadTask:whc_downloadTask];
    }
}
@end
