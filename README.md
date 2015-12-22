# WHCNetWorkKit 网络操作开源库

###QQ:712641411      

###目前封装最好使用最简单的文件下载(支持后台下载)iOS网络开源库 该版本进行了增强包括如下功能:
###GET/POST网络请求/多文件上传/后台文件下载/网络状态监控/UIButton,UIImageView 设置网络图片等功能模块。
###封装网络常用工具类json/xml 转模型类对象 json/xml 解析
###文件下载模块代理可以自由替换代理或者回调块具体详情请参看自带demo

###安装集成方式
```ruby
platform :ios, '7.0'
pod "WHCNetWorkKit", "~> 0.0.2"
```

##运行效果
![](https://github.com/netyouli/WHCNetWorkKit/blob/master/show.gif)

###网络状态监听 Use Example
```objective-c

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
// Override point for customization after application launch.
    [[WHC_HttpManager shared] registerNetworkStatusMoniterEvent];
    return YES;
}

/// 在其他地方可以这样[WHC_HttpManager shared].networkStatus获取当前网络状态
   （该网络库每次进行请求都自动处理了网络状态不需要用户进行判断）
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


###GET请求 Use Example
```objective-c
[[WHC_HttpManager shared] get:@"http://www.baidu.com/"
                  didFinished:^(WHC_BaseOperation *operation,
                                                NSData *data,
                                                NSError *error,
                                                BOOL isSuccess) {
     //处理data数据
}];


```


###POST 请求 Use Example

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

###多文件上传 Use Example
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

###普通文件下载 Use Example
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

###后台文件下载 Use Example
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

###UIButton设置网络图片  Use Example
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

###Json 转模型类  Use Example
###支持无限json嵌套解析转换 (开源MAC工具WHC_DataModelFactory 自动把json或者xml字符串生成模型类.m和.h文件
###省去手工创建模型类繁琐避免出错 开源链接：https://github.com/netyouli/WHC_DataModelFactory)
```objective-c
typedef enum {
    SexMale,
    SexFemale
} sex;

@interface User : NSObject
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *icon;
@property (strong, nonatomic) NSNumber * age;
@property (strong, nonatomic) NSNumber * height;
@property (strong, nonatomic) NSNumber *money;
@property (strong, nonatomic) sex  *sex;
@end

/***********************************************/


NSDictionary *dict = @{
@"name" : @"Jack",
@"icon" : @"lufy.png",
@"age" : @20,
@"height" : @"1.55",
@"money" : @100.9,
@"sex" : @(SexFemale)
};
// JSON -> User
User * user = [WHC_DataModel dataModelWithDictionary:dict className:[User class]];

NSLog(@"name=%@, icon=%@, age=%@, height=%@, money=%@, sex=%@",
user.name, user.icon, user.age, user.height, user.money, user.sex);
// name=Jack, icon=lufy.png, age=20, height=1.550000, money=100.9, sex=1
```

###XML 转模型类 Use Example
```objective-c
NSString  * xml = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>\
<ebMobileStartupInqRq >\
<REQHDR>\
<TrnNum>INHB2015042900000001</TrnNum>\
<TrnCode>1957747793</TrnCode>\
</REQHDR>\
<REQBDY>\
<OS>iPhone</OS>\
<App>CC</App>\
<IconVersion></IconVersion>\
</REQBDY>\
</ebMobileStartupInqRq>";

@interface REQBDY :NSObject
@property (nonatomic , copy) NSString              * OS;
@property (nonatomic , copy) NSString              * App;
@property (nonatomic , copy) NSString              * IconVersion;

@end

@interface REQHDR :NSObject
@property (nonatomic , copy) NSString              * TrnCode;
@property (nonatomic , copy) NSString              * TrnNum;

@end

@interface ebMobileStartupInqRq :NSObject
@property (nonatomic , strong) REQBDY              * REQBDY;
@property (nonatomic , strong) REQHDR              * REQHDR;

@end

@interface User :NSObject
@property (nonatomic , strong) ebMobileStartupInqRq              * ebMobileStartupInqRq;

@end


///上面模型类生成是用开源MAC工具WHC_DataModelFactory 自动生成 
///开源地址：https://github.com/netyouli/WHC_DataModelFactory
///首先用开源WHC_XMLParser 把xml转换为字典对象 然后用WHC_DataModel转模型对象
NSDictionary * xmlDictionary = [WHC_XMLParser dictionaryForXMLString:xml];
User * user = [WHC_DataModel dataModelWithDictionary:xmlDictionary
                                           className:[User class]];
NSLog(@"%@",ebMobile);

```
### 字典转换Json字符串 Use Example
```objective-c
NSDictionary * jsonDictionary = @{@"whc":@"吴海超"};
NSString * json = [WHC_Json jsonWithDictionary:jsonDictionary];
```

### Json字符串/JsonData转NSDictionary对象 Use Example
```objective-c
NSString * json = @"{"whc":"吴海超"}";
NSDictionary * jsonDictionary = [WHC_Json dictionaryWithJson:json];
jsonDictionary = [WHC_Json dictionaryWithJsonData:[json
                dataUsingEncoding:NSUTF8StringEncoding]];
```

### Json字符串/JsonData 转NSArray对象 Use Example
```objective-c
NSString * json = @""WHC":{{"android":"资深android开发者"} , {"iOS":"资深iOS开发者"}}";
NSArray * jsonArray = [WHC_Json arrayWithJson:json];
jsonArray = [WHC_Json arrayWithJsonData:[json
                    dataUsingEncoding:NSUTF8StringEncoding]];
```

### NSDictionary/NSArray对象转 Xml字符串
```objective-c
NSDictionary * REQHDR = @{@"TrnNum":@"INHB2015042900000001",@"TrnCode":@"1957747793"};
NSDictionary * REQBDY = @{@"OS":@"iPhone",@"App":@"CC",@"IconVersion":@""};
NSDictionary * ebMobileStartupInqR = @{@"REQHDR":REQHDR,@"REQBDY":REQBDY};
NSDictionary * xmlDic = @{@"ebMobileStartupInqRq":ebMobileStartupInqR};
//use one
NSString  * xmlStringOne = [WHC_Xml xmlWithDictionary:xmlDic];
//use two
NSString  * xmlStringTwo = [WHC_Xml xmlWithDictionary:xmlDic 
            rootAttribute:@"xmlns = \"http://ns.chinatrust.com.tw/XSD/CTCB/ESB/Message/BSMF/ebMobileStartupInqRq/01\""];

NSLog(@"xmlStringOne = %@",xmlStringOne);
//xmlStringOne =     NSString  * xml = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>\
<ebMobileStartupInqRq >\
<REQHDR>\
<TrnNum>INHB2015042900000001</TrnNum>\
<TrnCode>1957747793</TrnCode>\
</REQHDR>\
<REQBDY>\
<OS>iPhone</OS>\
<App>CC</App>\
<IconVersion></IconVersion>\
</REQBDY>\
</ebMobileStartupInqRq>";


NSLog(@"xmlStringTwo = %@",xmlStringTwo);
//xmlStringTwo =     NSString  * xml = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>\
<ebMobileStartupInqRq xmlns=\"http://ns.chinatrust.com.tw/XSD/CTCB/ESB/Message/BSMF/ebMobileStartupInqRq/01\">\
<REQHDR>\
<TrnNum>INHB2015042900000001</TrnNum>\
<TrnCode>1957747793</TrnCode>\
</REQHDR>\
<REQBDY>\
<OS>iPhone</OS>\
<App>CC</App>\
<IconVersion></IconVersion>\
</REQBDY>\
</ebMobileStartupInqRq>";

```

## License

WHCNetWorkKit is released under the MIT license. See LICENSE for details.
