# WHC_FileDownloadDemo
/*
*  qq:712641411
*  iOS大神qq群:460122071
*/

目前封装最好使用最简单的文件下载第三方iOS网络下载库
#具体使用方式请下载demo阅读里面很详细

##运行效果
![](https://github.com/netyouli/WHC_FileDownloadDemo/tree/master/WHC_FileDownloadDemo/show.gif)

####Use Example
```objective-c
//开始下载文件代码片段
BOOL            _isDownload;
//保存下载文件路径
NSString      * _filePath = [NSString stringWithFormat:@"%@/Library/Caches/WHCFiles/",NSHomeDirectory()]; 
//自定义存储下载文件名
NSString      * _fileName = @"吴海超下载测试文件.mp4";
//当前下载对象
WHC_Download  * _download = [WHCDownloadCenter startDownloadWithURL:url 
                                                           savePath:_filePath  
                                                       savefileName:_fileName 
                                                           delegate:self];

//下载代理实现
#pragma mark - WHCDownloadDelegate
//得到第一响应
- (void)WHCDownload:(WHC_Download *)download 
           filePath:(NSString *)filePath 
          hasACompleteDownload:(BOOL)has{

    //has 表示是否磁盘有一个完整下载的文件如果has = YES 表示有无需下载 否则可继续下载
    NSLog(@"下载开始");
}

//接受下载数据处理下载显示进度以及下载速度
- (void)WHCDownload:(WHC_Download *)download 
     didReceivedLen:(uint64_t)receivedLen 
           totalLen:(uint64_t)totalLen 
       networkSpeed:(NSString *)networkSpeed{

    CGFloat  percent = (CGFloat)receivedLen / totalLen * 100.0;
    _percentLab.text = [NSString stringWithFormat:@"%.1f%%",percent];  //显示下载百分比
    _downProgressV.progress = percent / 100.0;                         //显示下载进度
    //显示下载文件大小
    _curDownloadSizeLab.text = [NSString stringWithFormat:@"%.1fMB/%.1fMB",((CGFloat)receivedLen / 1024.0) / 1024.0 ,((CGFloat)totalLen / 1024.0) / 1024.0];
    _downloadSpeedLab.text = networkSpeed; //显示当前下载速度
}

//下载出错处理
- (void)WHCDownload:(WHC_Download *)download error:(NSError *)error{
    if(error){
        NSString  * strError = error.description;
        switch (error.code) {
            case GeneralErrorInfo:
                NSLog(@"一般出错");
            break;
            case NetWorkErrorInfo:
                NSLog(@"网络错误");
            break;
            case FreeDiskSpaceLack:
                NSLog(@"磁盘剩余空间不足");
            break;
            default:
            break;
        }
        UIAlertView  * alert = [[UIAlertView alloc]initWithTitle:@"下载出错误" 
                                                         message:strError 
                                                        delegate:nil 
                                               cancelButtonTitle:@"确定" 
                                               otherButtonTitles:nil, nil];
        [alert show];
    }
    _isDownload = NO;
}

//下载结束处理
- (void)WHCDownload:(WHC_Download *)download 
           filePath:(NSString *)filePath 
          isSuccess:(BOOL)success{

    NSLog(@"filePath = %@",filePath);
    if(success){
        UIAlertView  * alert = [[UIAlertView alloc]initWithTitle:@"阿超已经帮你下载完成" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
    }
    _isDownload = NO;
}

```