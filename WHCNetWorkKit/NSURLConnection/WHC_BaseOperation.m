//
//  WHC_BaseOperation.m
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
#import "WHC_HttpManager.h"

NSTimeInterval const kWHCRequestTimeout = 60;
NSTimeInterval const kWHCDownloadSpeedDuring = 1.5;
CGFloat        const kWHCWriteSizeLenght = 1024 * 1024;
NSString  * const  kWHCDomain = @"WHC_HTTP_OPERATION";
NSString  * const  kWHCInvainUrlError = @"无效的url:%@";
NSString  * const  kWHCCalculateFolderSpaceAvailableFailError = @"计算文件夹存储空间失败";
NSString  * const  kWHCErrorCode = @"错误码:%ld";
NSString  * const  kWHCFreeDiskSapceError = @"磁盘可用空间不足需要存储空间:%llu";
NSString  * const  kWHCRequestRange = @"bytes=%lld-";
NSString  * const  kWHCUploadCode = @"WHC";

@interface WHC_BaseOperation () {
    NSTimer * _speedTimer;
}

@end

@implementation WHC_BaseOperation

#pragma mark - 重写属性方法 -
- (void)setStrUrl:(NSString *)strUrl {
    _strUrl = nil;
    _strUrl = strUrl.copy;
    NSString * newUrl = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                              (CFStringRef)_strUrl,
                                                                                              (CFStringRef)@"!$&'()*-,-./:;=?@_~%#[]",
                                                                                              NULL,
                                                                                              kCFStringEncodingUTF8));
    _urlRequest = [[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:newUrl]];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _timeoutInterval = kWHCRequestTimeout;
        _requestType = WHCHttpRequestGet;
        _requestStatus = WHCHttpRequestNone;
        _cachePolicy = NSURLRequestUseProtocolCachePolicy;
        _responseData = [NSMutableData data];
    }
    return self;
}

- (void)dealloc{
    [self cancelledRequest];
}


#pragma mark - 重写队列操作方法 -

- (void)start {
    if ([NSURLConnection canHandleRequest:self.urlRequest]) {
        self.urlRequest.timeoutInterval = self.timeoutInterval;
        self.urlRequest.cachePolicy = self.cachePolicy;
        [_urlRequest setValue:self.contentType forHTTPHeaderField: @"Content-Type"];
        switch (self.requestType) {
            case WHCHttpRequestGet:
            case WHCHttpRequestFileDownload:{
                [_urlRequest setHTTPMethod:@"GET"];
            }
                break;
            case WHCHttpRequestPost:
            case WHCHttpRequestFileUpload:{
                [_urlRequest setHTTPMethod:@"POST"];
                if([WHC_HttpManager shared].cookie && [WHC_HttpManager shared].cookie.length > 0) {
                    [_urlRequest setValue:[WHC_HttpManager shared].cookie forHTTPHeaderField:@"Cookie"];
                }
                if (self.postParam != nil) {
                    NSData * paramData = nil;
                    if ([self.postParam isKindOfClass:[NSData class]]) {
                        paramData = (NSData *)self.postParam;
                    }else if ([self.postParam isKindOfClass:[NSString class]]) {
                        paramData = [((NSString *)self.postParam) dataUsingEncoding:self.encoderType allowLossyConversion:YES];
                    }
                    if (paramData) {
                        [_urlRequest setHTTPBody:paramData];
                        [_urlRequest setValue:[NSString stringWithFormat:@"%zd", paramData.length] forHTTPHeaderField: @"Content-Length"];
                    }
                }
            }
                break;
            default:
                break;
        }
        if(self.urlConnection == nil){
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            self.urlConnection = [[NSURLConnection alloc]initWithRequest:_urlRequest delegate:self startImmediately:NO];
        }
    }else {
        [self handleReqeustError:nil code:WHCGeneralError];
    }
}

- (BOOL)isExecuting {
    return _requestStatus == WHCHttpRequestExecuting;
}

- (BOOL)isCancelled {
    return _requestStatus == WHCHttpRequestCanceled ||
    _requestStatus == WHCHttpRequestFinished;
}

- (BOOL)isFinished {
    return _requestStatus == WHCHttpRequestFinished;
}

- (BOOL)isConcurrent{
    return YES;
}


#pragma mark - 公共方法 -

- (void)calculateNetworkSpeed {
    float downloadSpeed = (float)_orderTimeDataLenght / (kWHCDownloadSpeedDuring * 1024.0);
    _networkSpeed = [NSString stringWithFormat:@"%.1fKB/s", downloadSpeed];
    if (downloadSpeed >= 1024.0) {
        downloadSpeed = ((float)_orderTimeDataLenght / 1024.0) / (kWHCDownloadSpeedDuring * 1024.0);
        _networkSpeed = [NSString stringWithFormat:@"%.1fMB/s",downloadSpeed];
    }
    _orderTimeDataLenght = 0;
}


- (void)clearResponseData {
    [self.responseData resetBytesInRange:NSMakeRange(0, self.responseData.length)];
    [self.responseData setLength:0];
}

- (void)startRequest {
    NSRunLoop * urnLoop = [NSRunLoop currentRunLoop];
    [_urlConnection scheduleInRunLoop:urnLoop forMode:NSDefaultRunLoopMode];
    [self willChangeValueForKey:@"isExecuting"];
    _requestStatus = WHCHttpRequestExecuting;
    [self didChangeValueForKey:@"isExecuting"];
    [_urlConnection start];
    [urnLoop run];
}

- (void)addDependOperation:(WHC_BaseOperation *)operation {
    [self addDependency:operation];
}

- (void)startSpeedTimer {
    if (!_speedTimer && (_requestType == WHCHttpRequestFileUpload ||
                         _requestType == WHCHttpRequestFileDownload ||
                         _requestType == WHCHttpRequestGet)) {
        _speedTimer = [NSTimer scheduledTimerWithTimeInterval:kWHCDownloadSpeedDuring
                                                       target:self
                                                     selector:@selector(calculateNetworkSpeed)
                                                     userInfo:nil
                                                      repeats:YES];
        [self calculateNetworkSpeed];
    }
}

- (BOOL)handleResponseError:(NSURLResponse * )response {
    BOOL isError = NO;
    NSHTTPURLResponse  *  headerResponse = (NSHTTPURLResponse *)response;
    if(headerResponse.statusCode >= 400){
        isError = YES;
        self.requestStatus = WHCHttpRequestFinished;
        if (self.requestType != WHCHttpRequestFileDownload) {
            [self cancelledRequest];
            NSError * error = [NSError errorWithDomain:kWHCDomain
                                                  code:WHCGeneralError
                                              userInfo:@{NSLocalizedDescriptionKey:
                                                             [NSString stringWithFormat:kWHCErrorCode,
                                                              (long)headerResponse.statusCode]}];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.didFinishedBlock) {
                    self.didFinishedBlock(self, nil , error , NO);
                    self.didFinishedBlock = nil;
                }else if (self.delegate &&
                          [self.delegate respondsToSelector:@selector(WHCDownloadDidFinished:data:error:success:)]) {
                    if (headerResponse.statusCode == 404) {
                        [[WHC_HttpManager shared].failedUrls addObject: self.strUrl];
                    }
                    [self.delegate WHCDownloadDidFinished:(WHC_DownloadOperation *)self data:nil error:error success:NO];
                }
            });
        }
    }else {
        _responseDataLenght = headerResponse.expectedContentLength;
        [self startSpeedTimer];
    }
    return isError;
}

- (void)endRequest {
    self.didFinishedBlock = nil;
    self.progressBlock = nil;
    [self cancelledRequest];
}

- (void)cancelledRequest{
    if (_urlConnection) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        _requestStatus = WHCHttpRequestFinished;
        [self willChangeValueForKey:@"isCancelled"];
        [self willChangeValueForKey:@"isFinished"];
        [_urlConnection cancel];
        _urlConnection = nil;
        [self didChangeValueForKey:@"isCancelled"];
        [self didChangeValueForKey:@"isFinished"];
        if (_requestType == WHCHttpRequestFileUpload ||
            _requestType == WHCHttpRequestFileDownload) {
            if (_speedTimer) {
                [_speedTimer invalidate];
                [_speedTimer fire];
                _speedTimer = nil;
            }
        }
    }
}

- (void)handleReqeustError:(NSError *)error code:(NSInteger)code {
    if(error == nil){
        error = [[NSError alloc]initWithDomain:kWHCDomain
                                          code:code
                                      userInfo:@{NSLocalizedDescriptionKey:
                                                     [NSString stringWithFormat:kWHCInvainUrlError,self.strUrl]}];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.didFinishedBlock) {
            self.didFinishedBlock (self, nil, error , NO);
            self.didFinishedBlock = nil;
        }else if (self.delegate &&
                  [self.delegate respondsToSelector:@selector(WHCDownloadDidFinished:data:error:success:)]) {
            [self.delegate WHCDownloadDidFinished:(WHC_DownloadOperation *)self data:nil error:error success:NO];
        }
    });
    
}

@end
