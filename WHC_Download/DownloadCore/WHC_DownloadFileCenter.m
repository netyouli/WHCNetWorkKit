//
//  WHC_DownFileCenter.m
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

#import "WHC_DownloadFileCenter.h"
#define kWHC_FilePathCreateFailTxt  (@"WHC_DownloadFileCenter ：文件存储路径创建失败")
#define kWHC_FilePathErrorTxt       (@"WHC_DownloadFileCenter ：文件存储路径错误不能为空")
#define kWHC_DownloadObjectNilTxt   (@"下载对象为Nil")

@interface WHC_DownloadFileCenter (){
    NSOperationQueue      *     _WHCDownloadQueue;   //下载队列
    NSMutableArray        *     _cancleDownloadArr;  //所取消的下载
    NSUInteger                  _maxDownloadCount;   //最大下载数
}

@end

@implementation WHC_DownloadFileCenter

static  WHC_DownloadFileCenter  * downloadFileCenter = nil;

+ (instancetype)sharedWHCDownloadFileCenter{
    
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        downloadFileCenter = [WHC_DownloadFileCenter new];
    });
    return downloadFileCenter;
}

- (instancetype)init{
    self = [super init];
    if(self){
        _WHCDownloadQueue = [[NSOperationQueue alloc]init];
        _WHCDownloadQueue.maxConcurrentOperationCount = kWHC_DefaultMaxDownloadCount;
        _maxDownloadCount = kWHC_DefaultMaxDownloadCount;
        _cancleDownloadArr = [NSMutableArray new];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDownloadDidCompleteNotification:) name:kWHC_DownloadDidCompleteNotification object:nil];
    }
    return self;
}

- (void)handleDownloadDidCompleteNotification:(NSNotification *)notify{
    WHC_Download  * download = notify.object;
    BOOL isFinished = download.downloadComplete;
    if(!isFinished){
        [_cancleDownloadArr addObject:download];
    }else if([_cancleDownloadArr containsObject:download]){
        [_cancleDownloadArr removeObject:download];
    }
    if(isFinished){
        download = nil;
    }
}
#pragma mark - publicMethod

//获取下载列表
- (NSArray *)downloadList{
    return _WHCDownloadQueue.operations;
}

//是否存在取消的下载
- (BOOL)existCancelDownload{
    return _cancleDownloadArr.count > 0;
}

//返回指定文件名下载对象
- (WHC_Download *)downloadWithFileName:(NSString *)fileName{
    WHC_Download * download = nil;
    for (WHC_Download * tempDownload in _WHCDownloadQueue.operations) {
        if([tempDownload.saveFileName isEqualToString:fileName]){
            download = tempDownload;
            break;
        }
    }
    return download;
}

/**
 参数说明：
 url:下载路径
 savePath:文件本地存储路径
 delegate:下载状态监控代理
 */
- (WHC_Download *)startDownloadWithURL:(NSURL *)url
                              savePath:(NSString *)savePath
                              delegate:(id<WHCDownloadDelegate>)delegate{
    
    return [self startDownloadWithURL:url savePath:savePath savefileName:nil delegate:delegate];
}

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
                              delegate:(id<WHCDownloadDelegate>)delegate{
    WHC_Download  * download = nil;
    NSString * fielName = nil;
    if(savefileName){
        NSString * format = [self fileFormat:url.absoluteString];
        if([format isEqualToString:[NSString stringWithFormat:@".%@",[[savefileName componentsSeparatedByString:@"."] lastObject]]]){
            fielName = savefileName;
        }else{
            fielName = [NSString stringWithFormat:@"%@%@",savefileName,format];
        }
    }
    for (WHC_Download * tempDownload in _WHCDownloadQueue.operations) {
        if ([fielName isEqualToString:tempDownload.saveFileName]){
            if(delegate && [delegate respondsToSelector:@selector(WHCDownload:filePath:hasACompleteDownload:)]){
                [delegate WHCDownload:tempDownload filePath:savePath hasACompleteDownload:YES];
            }
            return tempDownload;
        }
    }
    if([self createFileSavePath:savePath]){
        download = [WHC_Download new];
        download.delegate = delegate;
        download.saveFileName = fielName;
        download.saveFilePath = savePath;
        download.downUrl = url;
        [_WHCDownloadQueue addOperation:download];
    }
    return download;
}

/**
 说明：
 在外部创建下载队列进行下载
 */
- (WHC_Download *)startDownloadWithWHCDownload:(WHC_Download *)download{
    if(download){
        [_WHCDownloadQueue addOperation:download];
    }else{
        NSLog(kWHC_DownloadObjectNilTxt);
    }
    return download;
}

/**
 note:该方法必须在开始下载之前调用
 说明：
 设置最大下载数量
 */
- (void)setMaxDownloadCount:(NSUInteger)count{
    _maxDownloadCount = count;
    _WHCDownloadQueue.maxConcurrentOperationCount = _maxDownloadCount;
}

/**
 说明:返回下载中心最大同时下载操作个数
 */
- (NSInteger)maxDownloadCount{
    return _WHCDownloadQueue.maxConcurrentOperationCount;
}

/**
 说明：
 取消所有正下载并是否取消删除文件
 */
- (void)cancelAllDownloadTaskAndDelFile:(BOOL)isDel{
    for (WHC_Download * download in _WHCDownloadQueue.operations) {
        if(![_WHCDownloadQueue.operations containsObject:download]){
            [download cancelDownloadTaskAndDelFile:isDel];
        }
    }
}

/**
 说明：
 取消指定正下载url的下载
 */
- (void)cancelDownloadWithDownUrl:(NSURL *)downUrl delFile:(BOOL)delFile{
    for(WHC_Download * download in _WHCDownloadQueue.operations){
        if([download.downUrl.absoluteString isEqualToString:downUrl.absoluteString]){
            [download cancelDownloadTaskAndDelFile:delFile];
            break;
        }
    }
}

/**
 说明：
 取消指定正下载文件名的下载
 */
- (void)cancelDownloadWithFileName:(NSString *)fileName delFile:(BOOL)delFile{
    for(WHC_Download * download in _WHCDownloadQueue.operations){
        if([download.saveFileName isEqualToString:fileName]){
            [download cancelDownloadTaskAndDelFile:delFile];
            break;
        }
    }
}

/**
 说明：
 恢复指定暂停正下载文件名的下载并返回新下载
 */
- (WHC_Download *)recoverDownloadWithName:(NSString *)fileName delegate:(id)delegate{
    
    for (int i = 0; i < _cancleDownloadArr.count; i++) {
        WHC_Download * download = _cancleDownloadArr[i];
        if([download.saveFileName isEqualToString:fileName]){
            WHC_Download * nDownload = nil;
            NSString  * strSavePath = [download.saveFilePath stringByReplacingOccurrencesOfString:download.saveFileName withString:@""];
            nDownload = [self startDownloadWithURL:download.downUrl
                                          savePath:strSavePath
                                      savefileName:download.saveFileName
                                          delegate:delegate];
            [_cancleDownloadArr removeObject:download];
            download = nil;
            return nDownload;
        }
    }
    return nil;
}


/**
 说明：
 恢复指暂停下载url的下载并返回新下载
 */
- (WHC_Download *)recoverDownloadWithDownUrl:(NSURL *)downUrl delegate:(id)delegate{
    
    for (int i = 0; i < _cancleDownloadArr.count; i++) {
        WHC_Download * download = _cancleDownloadArr[i];
        if([download.downUrl.absoluteString isEqualToString:downUrl.absoluteString]){
            WHC_Download * nDownload = nil;
            NSString  * strSavePath = [download.saveFilePath stringByReplacingOccurrencesOfString:download.saveFileName withString:@""];
            nDownload = [self startDownloadWithURL:download.downUrl
                                          savePath:strSavePath
                                      savefileName:download.saveFileName
                                          delegate:delegate];
            [_cancleDownloadArr removeObject:download];
            download = nil;
            return nDownload;
        }
    }
    return nil;
}

/**
 说明：
 恢复指定暂停的下载并返回新下载
 */

- (WHC_Download *)recoverDownload:(WHC_Download *)download delegate:(id)delegate{
    
    if(download){
        for (int i = 0; i < _cancleDownloadArr.count; i++) {
            WHC_Download * tempDownload = _cancleDownloadArr[i];
            if([tempDownload isEqual:download]){
                WHC_Download * nDownload = nil;
                NSString  * strSavePath = [tempDownload.saveFilePath stringByReplacingOccurrencesOfString:tempDownload.saveFileName withString:@""];
                nDownload = [self startDownloadWithURL:tempDownload.downUrl
                                              savePath:strSavePath
                                          savefileName:tempDownload.saveFileName
                                              delegate:delegate];
                [_cancleDownloadArr removeObject:tempDownload];
                tempDownload = nil;
                return nDownload;
            }
        }
    }
    return nil;
}

/**
 说明：
 替换当前代理通过要下载的文件名
 使用情景:(当从控制器B进入到控制器C然后在控制器C中进行下载，然后下载过程中突然退出到控制器B，
 在又进入到控制器C，这个时候还是在下载但是代理对象和之前的那个控制器C不是一个对象所以要替换)
 */
- (BOOL)replaceCurrentDownloadDelegate:(id)delegate fileName:(NSString *)fileName{
    NSArray   *  operations = _WHCDownloadQueue.operations;
    if(operations){
        for (WHC_Download * download in operations) {
            if([download.saveFileName isEqualToString:fileName]){
                download.delegate = delegate;
                return YES;
            }
        }
    }
    return NO;
}

//替换所有当前下载代理
- (BOOL)replaceCurrentDownloadDelegate:(id)delegate{
    BOOL result = NO;
    NSArray   *  operations = _WHCDownloadQueue.operations;
    if(operations.count > 0){
        result = YES;
    }
    if(operations){
        for (WHC_Download * download in operations) {
            download.delegate = delegate;
        }
    }
    return result;
}

/**
 说明：
 通过要下载的文件名来判断当前是否在进行下载任务
 */
- (BOOL)currentIsDownloadTaskWithFileName:(NSString *)fileName{
    BOOL  result = NO;
    NSArray   *  operations = _WHCDownloadQueue.operations;
    if(operations){
        for (WHC_Download * download in operations) {
            if([download.saveFileName isEqualToString:fileName]){
                result = YES;
                break;
            }
        }
    }
    return result;
}

/**
 说明：
 恢复所有暂停的下载并返回新下载集合
 */
- (NSArray *)recoverAllDownloadTaskDelegate:(id)delegate{
    NSMutableArray  * downloadArr = [NSMutableArray new];
    for (int i = 0; i < _cancleDownloadArr.count; i++) {
        WHC_Download * download = _cancleDownloadArr[i];
        WHC_Download * nDownload = nil;
        NSString  * strSavePath = [download.saveFilePath stringByReplacingOccurrencesOfString:download.saveFileName withString:@""];
        nDownload = [self startDownloadWithURL:download.downUrl
                                      savePath:strSavePath
                                  savefileName:download.saveFileName
                                      delegate:delegate];
        [_cancleDownloadArr removeObject:download];
        download = nil;
        [downloadArr addObject:nDownload];
    }
    return downloadArr;
}

//获取要下载的文件格式
- (NSString *)fileFormat:(NSString *)downloadUrl{
    NSArray  * strArr = [downloadUrl componentsSeparatedByString:@"."];
    if(strArr && strArr.count > 0){
        return [NSString stringWithFormat:@".%@",strArr.lastObject];
    }else{
        return nil;
    }
}

#pragma mark - privateMothed


- (BOOL)createFileSavePath:(NSString *)savePath{
    BOOL  result = YES;
    if(savePath != nil && savePath.length > 0){
        NSFileManager  * fm = [NSFileManager defaultManager];
        if(![fm fileExistsAtPath:savePath]){
            __autoreleasing NSError *error = nil;
            [fm createDirectoryAtPath:savePath withIntermediateDirectories:YES attributes:nil error:&error];
            if(error){
                result = NO;
                NSLog(kWHC_FilePathCreateFailTxt);
            }
        }
    }else{
        result = NO;
        NSLog(kWHC_FilePathErrorTxt);
    }
    return result;
}

@end
