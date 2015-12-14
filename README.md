# WHCNetWorkKit

###QQ:712641411  iOS技术交流群:302157745

###目前封装最好使用最简单的文件下载(支持后台下载)iOS网络开源库 该版本进行了增强包括如下功能:
###GET/POST网络请求/多文件上传/后台文件下载/网络状态监控/UIButton,UIImageView 设置网络图片等功能模块。


##运行效果
![](https://github.com/netyouli/WHCNetWorkKit/show.gif)

####网络状态监听 Use Example
```objective-c

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
// Override point for customization after application launch.
    _window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    _window.rootViewController = [[UINavigationController alloc]initWithRootViewController:[ViewController new]];
    [_window makeKeyAndVisible];
    [[WHC_HttpManager shared] registerNetworkStatusMoniterEvent];
    return YES;
}

/// 在其他地方可以这样[WHC_HttpManager shared].networkStatus获取当前网络状态（该网络库每次进行请求都自动处理了网络状态不需要用户进行判断）
self.networkStatus = netStatus;
switch ([WHC_HttpManager shared].networkStatus) {
    case NotReachable:{
        [[[UIAlertView alloc]initWithTitle:nil
        message:@"当前网络不可用请检查网络设置"
        delegate:nil cancelButtonTitle:@"确定"
        otherButtonTitles:nil, nil] show];
        }
    break;
    case ReachableViaWiFi:
        NSLog(@"====当前网络状态为Wifi=======");
    break;
    case ReachableViaWWAN:
        NSLog(@"====当前网络状态为3G=======");
    break;
}

```


####GET请求 Use Example
```objective-c
[[WHC_HttpManager shared] get:@"http://www.baidu.com/"
                  didFinished:^(WHC_BaseOperation *operation,
                                                NSData *data,
                                                NSError *error,
                                                BOOL isSuccess) {
     //处理data数据
}];


```


####POST 请求 Use Example

```objective-c

[[WHC_HttpManager shared] post:@"http://www.baidu.com"
                         param:@"whc"
                   didFinished:^(WHC_BaseOperation *operation,
                                                 NSData *data, 
                                               NSError *error,
                                               BOOL isSuccess) {
        //处理data数据
}];
```

####多文件上传 Use Example
```objective-c
//上传5个文件
for (int i = 0; i < 5; i++) {
    UIImage * image = [UIImage imageNamed:@"whc"];
    NSData * imageData = UIImageJPEGRepresentation(image, 0.5);
    [[WHC_HttpManager shared] addUploadFileData:imageData withFileName:[NSString stringWithFormat:@"image%d",i] mimeType:@"image/jpep" forKey:@"file"];
    //最后一个参数key必须和服务端对应
}
[[WHC_HttpManager shared] upload:@"http://www.baidu.com"
                           param:@"param" didFinished:^(WHC_BaseOperation *operation,
                                                                            NSData *data,
                                                                            NSError *error,
                                                                            BOOL isSuccess) {
        //处理上传结果数据
}];

```

####普通文件下载 Use Example
```objective-c
WHC_DownloadOperation * downloadTask = nil;
downloadTask = [[WHC_HttpManager shared] download:kWHC_DefaultDownloadUrl
                                         savePath:[WHC_DownloadObject videoDirectory]
                                     saveFileName:fileName
                                         response:^(WHC_BaseOperation *operation, NSError *error, BOOL isOK) {
                                        if (isOK) {
                                            [weakSelf.view toast:@"已经添加到下载队列"];
                                            WHC_DownloadOperation * downloadOperation = (WHC_DownloadOperation*)operation;
                                            WHC_DownloadObject * downloadObject = [WHC_DownloadObject new];
                                            downloadObject.fileName = downloadOperation.saveFileName;
                                            downloadObject.downloadPath = downloadOperation.strUrl;
                                            downloadObject.downloadState = WHCDownloading;
                                            downloadObject.currentDownloadLenght = downloadOperation.recvDataLenght;
                                            downloadObject.totalLenght = downloadOperation.fileTotalLenght;
                                            [downloadObject writeDiskCache];
                                        }else {
                                            [weakSelf.view toast:error.userInfo[NSLocalizedDescriptionKey]];
                                        }
                                    } process:^(WHC_BaseOperation *operation, uint64_t recvLength, uint64_t totalLength, NSString *speed) {
                                            NSLog(@"recvLength = %llu totalLength = %llu speed = %@",recvLength , totalLength , speed);
                                    } didFinished:^(WHC_BaseOperation *operation, NSData *data, NSError *error, BOOL isSuccess) {
                                        if (isSuccess) {
                                            [weakSelf.view toast:@"下载成功"];
                                            [weakSelf saveDownloadStateOperation:(WHC_DownloadOperation *)operation];
                                        }else {
                                            [weakSelf.view toast:error.userInfo[NSLocalizedDescriptionKey]];
                                        if (error != nil &&
                                            error.code == WHCCancelDownloadError) {
                                            [weakSelf saveDownloadStateOperation:(WHC_DownloadOperation *)operation];
                                        }
                                    }
}];

```

####后台文件下载 Use Example
```objective-c
[[WHC_SessionDownloadManager shared] setBundleIdentifier:@"com.WHC.WHCNetWorkKit.backgroundsession"];
WHC_DownloadSessionTask * downloadTask = [[WHC_SessionDownloadManager shared]
                                                                    download:kWHC_DefaultDownloadUrl
                                                                    savePath:[WHC_DownloadObject videoDirectory]
                                                                saveFileName:fileName
                                                                    response:^(WHC_BaseOperation *operation, NSError *error, BOOL isOK) {
                                                                    [weakSelf.view toast:@"已经添加到下载队列"];
                                                                    WHC_DownloadOperation * downloadOperation = (WHC_DownloadOperation*)operation;
                                                                    WHC_DownloadObject * downloadObject = [WHC_DownloadObject new];
                                                                    downloadObject.fileName = downloadOperation.saveFileName;
                                                                    downloadObject.downloadPath = downloadOperation.strUrl;
                                                                    downloadObject.downloadState = WHCDownloading;
                                                                    downloadObject.currentDownloadLenght = downloadOperation.recvDataLenght;
                                                                    downloadObject.totalLenght = downloadOperation.fileTotalLenght;
                                                                    [downloadObject writeDiskCache];
                                                                } process:^(WHC_BaseOperation *operation, uint64_t recvLength, uint64_t totalLength, NSString *speed) {
                                                                    NSLog(@"recvLength = %llu , totalLength = %llu , speed = %@",recvLength , totalLength , speed);
                                                                } didFinished:^(WHC_BaseOperation *operation, NSData *data, NSError *error, BOOL isSuccess) {
                                                                    if (isSuccess) {
                                                                        [weakSelf.view toast:@"下载成功"];
                                                                        [weakSelf saveDownloadStateOperation:(WHC_DownloadOperation *)operation];
                                                                    }else {
                                                                        [weakSelf.view toast:error.userInfo[NSLocalizedDescriptionKey]];
                                                                        if (error != nil &&
                                                                            error.code == WHCCancelDownloadError) {
                                                                            [weakSelf saveDownloadStateOperation:(WHC_DownloadOperation *)operation];
                                                                        }
                                                                    }
}];
```
####UIButton设置网络图片  Use Example
```objective-c
UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
[button whc_setBackgroundImageWithURL:@"http://www.baidu.com" forState:UIControlStateNormal];
[button whc_setBackgroundImageWithURL:@"http://www.baidu.com" forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"whc"]];
[button whc_setImageWithUrl:@"http://www.baidu.com" forState:UIControlStateNormal];
[button whc_setImageWithUrl:@"http://www.baidu.com" forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"whc"]];
```

####UIImageView设置网络图片  Use Example
```objective-c
UIImageView * imageView = [UIImageView new];
[imageView whc_setImageWithUrl:@"http://www.baidu.com"];
[imageView whc_setImageWithUrl:@"http://www.baidu.com" placeholderImage:[UIImage imageNamed:@"whc"]];
```