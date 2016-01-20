//
//  WHC_DownloadOperation.m
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

#import "WHC_DownloadOperation.h"

@interface WHC_DownloadOperation () {
    uint64_t                  _localFileSizeLenght;   //文件尺寸大小
    NSFileHandle            * _fileHandle;         //文件句柄
}

@end

@implementation WHC_DownloadOperation

- (void)dealloc {
}

#pragma mark - 重写属性方法 -

- (NSString *)saveFileName {
    if (_saveFileName) {
        return _saveFileName;
    }else{
        return [self.strUrl lastPathComponent];
    }
}

- (NSString *)saveFilePath {
    return [_saveFilePath stringByAppendingString:self.saveFileName];
}

- (uint64_t)downloadLenght {
    return self.recvDataLenght;
}

- (uint64_t)fileTotalLenght {
    return _actualFileSizeLenght;
}

- (void)start {
    __autoreleasing  NSError  * error = nil;
    NSFileManager  * fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:self.saveFilePath]) {
        [fm createFileAtPath:self.saveFilePath contents:nil attributes:nil];
    }else {
        _localFileSizeLenght = [[fm attributesOfItemAtPath:self.saveFilePath error:&error] fileSize];
        NSString  * strRange = [NSString stringWithFormat:kWHCRequestRange ,_localFileSizeLenght];
        [self.urlRequest setValue:strRange forHTTPHeaderField:@"Range"];
    }
    
    if(error == nil) {
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.saveFilePath];
        [_fileHandle seekToEndOfFile];
    }else {
        NSLog(@"%@",kWHCCalculateFolderSpaceAvailableFailError);
    }
    [super start];
    [self startRequest];
}

#pragma mark - 私有方法

- (uint64_t)calculateFreeDiskSpace{
    uint64_t  freeDiskLen = 0;
    NSString * docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSFileManager  * fm   = [NSFileManager defaultManager];
    NSDictionary   * dict = [fm attributesOfFileSystemForPath:docPath error:nil];
    if(dict){
        freeDiskLen = [dict[NSFileSystemFreeSize] unsignedLongLongValue];
    }
    return freeDiskLen;
}

- (NSInteger)getCode {
    NSInteger code = WHCGeneralError;
    NSFileManager * fm = [NSFileManager defaultManager];
    if (self.recvDataLenght > 0 ||
        [[fm attributesOfItemAtPath:self.saveFilePath error:nil] fileSize] > 100) {
        code = WHCCancelDownloadError;
    }
    return code;
}

- (void)removeDownloadFile {
    NSFileManager  * fm = [NSFileManager defaultManager];
    if([fm fileExistsAtPath:self.saveFilePath]){
        [fm removeItemAtPath:self.saveFilePath error:nil];
    }
}

#pragma mark - 公共处理方法 -

- (void)cancelDownloadTaskAndDeleteFile:(BOOL)isDelete {
    _isDeleted = isDelete;
    if(self.responseData.length > 0 && _fileHandle){
        [_fileHandle writeData:self.responseData];
        [self clearResponseData];
    }
    self.requestStatus = WHCHttpRequestFinished;
    [self cancelledRequest];
    if(isDelete){
        [self removeDownloadFile];
    }
    NSError * error = nil;
    if (!isDelete) {
        error = [NSError errorWithDomain:kWHCDomain
                            code:[self getCode]
                        userInfo:@{NSLocalizedDescriptionKey:@"下载已取消"}];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.didFinishedBlock) {
            self.didFinishedBlock(self, nil , error , NO);
            self.didFinishedBlock = nil;
        }else if (self.delegate &&
                  [self.delegate respondsToSelector:@selector(WHCDownloadDidFinished:data:error:success:)]) {
            [self.delegate WHCDownloadDidFinished:self data:nil error:error success:NO];
        }
    });
    
}

- (void)appExitHandleDownloadFile:(NSNotification *)notify {
    if (self.urlConnection) {
        [self connectionDidFinishLoading:self.urlConnection];
    }
}

- (void)cancelledRequest{
    [super cancelledRequest];
    if (_fileHandle) {
        [_fileHandle synchronizeFile];
        [_fileHandle closeFile];
        _fileHandle = nil;
    }
}

- (void)handleReqeustError:(NSError *)error code:(NSInteger)code {
    if (code != WHCCancelDownloadError) {
        [self removeDownloadFile];
    }
    [super handleReqeustError:error code:code];
}

#pragma mark - 实现网络代理方法 -

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    BOOL  isCancel = YES;
    NSError  * error = nil;
    NSInteger code = WHCGeneralError;
    if (![self handleResponseError:response]){
        isCancel = NO;
        _actualFileSizeLenght = response.expectedContentLength + _localFileSizeLenght;
        
        if([self calculateFreeDiskSpace] < _actualFileSizeLenght){
            error = [[NSError alloc]initWithDomain:kWHCDomain
                                              code:WHCFreeDiskSpaceLack
                                          userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:kWHCFreeDiskSapceError,_actualFileSizeLenght]}];
            [self removeDownloadFile];
            code = WHCFreeDiskSpaceLack;
            isCancel = YES;
            goto WHC1;
        }else{
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(appExitHandleDownloadFile:)
                                                         name:UIApplicationWillTerminateNotification
                                                       object:nil];
            self.recvDataLenght = _localFileSizeLenght;
            [self clearResponseData];
            goto WHC2;
        }
    }else {
    WHC1:
        [self cancelDownloadTaskAndDeleteFile:NO];
        error = [NSError errorWithDomain:kWHCDomain code:code userInfo:@{NSLocalizedDescriptionKey:response.description}];
        
    WHC2:
        dispatch_async(dispatch_get_main_queue() , ^{
            if (self.responseBlock) {
                self.responseBlock(self, error ,!isCancel);
                self.responseBlock = nil;
            }else if (self.delegate &&
                      [self.delegate respondsToSelector:@selector(WHCDownloadResponse:error:ok:)]) {
                [self.delegate WHCDownloadResponse:self error:error ok:!isCancel];
            }
        });
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
    self.recvDataLenght += data.length;
    self.orderTimeDataLenght += data.length;
    if(self.responseData.length > kWHCWriteSizeLenght && _fileHandle){
        [_fileHandle writeData:self.responseData];
        [self clearResponseData];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.progressBlock) {
            self.progressBlock(self ,self.recvDataLenght , _actualFileSizeLenght , self.networkSpeed);
        }else if (self.delegate &&
                  [self.delegate respondsToSelector:@selector(WHCDownloadProgress:recv:total:speed:)]) {
            [self.delegate WHCDownloadProgress:self recv:self.recvDataLenght total:_actualFileSizeLenght speed:self.networkSpeed];
        }
    });
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if(_fileHandle){
        [_fileHandle writeData:self.responseData];
        [self clearResponseData];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.didFinishedBlock) {
            self.didFinishedBlock(self, nil , nil, YES);
            self.didFinishedBlock = nil;
        }else if (self.delegate &&
                  [self.delegate respondsToSelector:@selector(WHCDownloadDidFinished:data:error:success:)]) {
            [self.delegate WHCDownloadDidFinished:self data:nil error:nil success:YES];
        }
    });
    
    [self cancelledRequest];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self cancelledRequest];
    [self handleReqeustError:error code:[self getCode]];
}

@end
