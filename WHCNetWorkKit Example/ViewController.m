//
//  ViewController.m
//  WHC_FileDownloadDemo
//
//  Created by 吴海超 on 15/7/27.
//  Copyright (c) 2015年 吴海超. All rights reserved.
//

/*
 *  qq:712641411
 *  iOSqq群:302157745
 *  gitHub:https://github.com/netyouli
 *  csdn:http://blog.csdn.net/windwhc/article/category/3117381
 */

#import "ViewController.h"
#import "WHC_OffLineVideoVC.h"
#import "UIView+WHC_Toast.h"
#import "UIView+WHC_Loading.h"
#import "UIScrollView+WHC_PullRefresh.h"
#import "AppDelegate.h"

#import "WHC_DownloadObject.h"

@import WHCNetWorkKit;

#import <WHCNetWorkKit/WHC_HttpManager.h>
#import <WHCNetWorkKit/UIButton+WHC_HttpButton.h>
#import <WHCNetWorkKit/UIImageView+WHC_HttpImageView.h>

#define kWHC_CellName             (@"WHC：视频下载文件")
#define kWHC_DefaultDownloadUrl   (@"http://dlsw.baidu.com/sw-search-sp/soft/3b/29082/ykkhdmacb0.9.1438938315.dmg")


@interface ViewController ()<WHC_PullRefreshDelegate>{
    NSMutableArray  *  _fileNameArr;
}
@property (nonatomic , strong)IBOutlet UITableView * downloadTv;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
    [self layoutUI];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)initData {
    _fileNameArr = [NSMutableArray array];
    for (NSInteger i = 0; i < 200 ; i++) {
        [_fileNameArr addObject:[NSString stringWithFormat:@"%@%d    (%@)",kWHC_CellName,(int)i + 1,@"单击下载视频文件"]];
    }
}

- (void)layoutUI{
    self.navigationItem.title = @"iOS专业级文件下载解决方案";
    UIBarButtonItem * rightItem = [[UIBarButtonItem alloc]initWithTitle:@"离线视频中心" style:UIBarButtonItemStylePlain target:self action:@selector(clickRightItem:)];
    self.navigationItem.rightBarButtonItem = rightItem;
    [_downloadTv setWHCRefreshStyle:AllStyle delegate:self];
}

- (void)clickRightItem:(UIBarButtonItem *)sender{
    [self.navigationController pushViewController:[WHC_OffLineVideoVC new] animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)alert:(NSString *)msg{
    UIAlertView  * alert = [[UIAlertView alloc]initWithTitle:msg message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];
}

#pragma mark - 上拉下拉刷新代理

//上拉刷新回调
- (void)WHCUpPullRequest{
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSInteger count = _fileNameArr.count - 1;
        for (NSInteger i = count; i < count + 3; i++) {
            [_fileNameArr addObject:[NSString stringWithFormat:@"%@%d    (%@)",kWHC_CellName,(int)i + 1,@"单击下载视频文件"]];
        }
        [_downloadTv WHCDidCompletedWithRefreshIsDownPull:NO];
        [_downloadTv reloadData];
    });

}

//下拉刷新回调
- (void)WHCDownPullRequest{
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSInteger count = _fileNameArr.count - 1;
        for (NSInteger i = count; i > count - 3; i--) {
            [_fileNameArr removeObjectAtIndex:i];
        }
        [_downloadTv WHCDidCompletedWithRefreshIsDownPull:YES];
        [_downloadTv reloadData];
    });

}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma mark - 列表代理方法
#pragma mark - UITableViewDelegate UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return [UIView new];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _fileNameArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell  * cell = [tableView dequeueReusableCellWithIdentifier:kWHC_CellName];
    if(cell == nil){
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kWHC_CellName];
    }
    cell.textLabel.font = [UIFont systemFontOfSize:14.0];
    cell.textLabel.text = _fileNameArr[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSString * suffix = [[WHC_HttpManager shared] fileFormatWithUrl:kWHC_DefaultDownloadUrl];
    NSString * fileName = [NSString stringWithFormat:@"%@%@",
                           _fileNameArr[indexPath.row],
                           suffix != nil ? suffix : @".dmg"];
    __weak typeof(self) weakSelf = self;
#if WHC_BackgroundDownload
    [[WHC_SessionDownloadManager shared] setBundleIdentifier:@"com.WHC.WHCNetWorkKit.backgroundsession"];
    WHC_DownloadSessionTask * downloadTask = [[WHC_SessionDownloadManager shared]
          download:kWHC_DefaultDownloadUrl
          savePath:[WHC_DownloadObject videoDirectory]
      saveFileName:fileName
          response:^(WHC_BaseOperation *operation, NSError *error, BOOL isOK) {
          } process:^(WHC_BaseOperation *operation, uint64_t recvLength, uint64_t totalLength, NSString *speed) {
              WHC_DownloadOperation * downloadOperation = (WHC_DownloadOperation*)operation;
              if (![WHC_DownloadObject existLocalSavePath:downloadOperation.saveFileName]) {
                  WHC_DownloadObject * downloadObject = [WHC_DownloadObject new];
                  [weakSelf.view toast:@"已经添加到下载队列"];
                  downloadObject.fileName = downloadOperation.saveFileName;
                  downloadObject.downloadPath = downloadOperation.strUrl;
                  downloadObject.downloadState = WHCDownloading;
                  downloadObject.currentDownloadLenght = downloadOperation.recvDataLenght;
                  downloadObject.totalLenght = downloadOperation.fileTotalLenght;
                  [downloadObject writeDiskCache];
              }
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

#else
    WHC_DownloadOperation * downloadTask = nil;
    downloadTask = [[WHC_HttpManager shared] download:kWHC_DefaultDownloadUrl
         savePath:[WHC_DownloadObject videoDirectory]
     saveFileName:fileName
         response:^(WHC_BaseOperation *operation, NSError *error, BOOL isOK) {
             if (isOK) {
                 
                 WHC_DownloadOperation * downloadOperation = (WHC_DownloadOperation*)operation;
                 WHC_DownloadObject * downloadObject = [WHC_DownloadObject readDiskCache:downloadOperation.saveFileName];
                 if (downloadObject == nil) {
                     [weakSelf.view toast:@"已经添加到下载队列"];
                     downloadObject = [WHC_DownloadObject new];
                 }
                 downloadObject.fileName = downloadOperation.saveFileName;
                 downloadObject.downloadPath = downloadOperation.strUrl;
                 downloadObject.downloadState = WHCDownloading;
                 downloadObject.currentDownloadLenght = downloadOperation.recvDataLenght;
                 downloadObject.totalLenght = downloadOperation.fileTotalLenght;
                 [downloadObject writeDiskCache];
             }else {
                 [weakSelf errorHandle:(WHC_DownloadOperation *)operation error:error];
             }
         } process:^(WHC_BaseOperation *operation, uint64_t recvLength, uint64_t totalLength, NSString *speed) {
             NSLog(@"recvLength = %llu totalLength = %llu speed = %@",recvLength , totalLength , speed);
         } didFinished:^(WHC_BaseOperation *operation, NSData *data, NSError *error, BOOL isSuccess) {
             if (isSuccess) {
                 [weakSelf.view toast:@"下载成功"];
                 [weakSelf saveDownloadStateOperation:(WHC_DownloadOperation *)operation];
             }else {
                  [weakSelf errorHandle:(WHC_DownloadOperation *)operation error:error];
                 if (error != nil &&
                     error.code == WHCCancelDownloadError) {
                     [weakSelf saveDownloadStateOperation:(WHC_DownloadOperation *)operation];
                 }
             }
         }];

    #endif
    if (downloadTask.requestStatus == WHCHttpRequestNone) {
#if WHC_BackgroundDownload 
        if (![[WHC_SessionDownloadManager shared] waitingDownload]) {
            return;
        }
#else
        if (![[WHC_HttpManager shared] waitingDownload]) {
            return;
        }
#endif
        WHC_DownloadObject * downloadObject = [WHC_DownloadObject readDiskCache:downloadTask.saveFileName];
        if (downloadObject == nil) {
            [weakSelf.view toast:@"已经添加到下载队列"];
            downloadObject = [WHC_DownloadObject new];
            downloadObject.fileName = fileName;
            downloadObject.downloadPath = kWHC_DefaultDownloadUrl;
            downloadObject.downloadState = WHCDownloadWaitting;
            downloadObject.currentDownloadLenght = 0;
            downloadObject.totalLenght = 0;
            [downloadObject writeDiskCache];
        }
    }
}

- (void)saveDownloadStateOperation:(WHC_DownloadOperation *)operation {
    WHC_DownloadObject * downloadObject = [WHC_DownloadObject readDiskCache:operation.strUrl];
    if (downloadObject != nil) {
        downloadObject.currentDownloadLenght = operation.recvDataLenght;
        downloadObject.totalLenght = operation.fileTotalLenght;
        [downloadObject writeDiskCache];
    }
}

- (void) errorHandle:(WHC_DownloadOperation *)operation error:(NSError *)error {
    NSString * errInfo = error.userInfo[NSLocalizedDescriptionKey];
    if ([errInfo containsString:@"404"]) {
        [self.view toast:@"该文件不存在"];
        WHC_DownloadObject * downloadObject = [WHC_DownloadObject readDiskCache:operation.strUrl];
        if (downloadObject != nil) {
            [downloadObject removeFromDisk];
        }
    }else {
        if ([errInfo containsString:@"已经在下载中"]) {
            [self.view toast:errInfo];
        }else {
            [self.view toast:@"下载失败"];
        }
    }
}

@end
