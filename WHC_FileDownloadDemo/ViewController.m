//
//  ViewController.m
//  WHC_FileDownloadDemo
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

#import "ViewController.h"
#import "WHC_DownloadFileCenter.h"
#import "WHC_OffLineVideoVC.h"
#import "UIView+WHC_Toast.h"
#import "UIView+WHC_Loading.h"
#import "UIScrollView+WHC_PullRefresh.h"

#define kWHC_CellName             (@"WHC：视频下载文件")
#define kWHC_DefaultDownloadUrl   (@"http://s.dingboshi.cn:8080/school/file/201507/resource/79e01f8be9db444291257b067ccffbc7.mp4")
@interface ViewController ()<WHCDownloadDelegate,WHC_PullRefreshDelegate>{
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

- (void)initData{
    _fileNameArr = [NSMutableArray array];
    for (NSInteger i = 0; i < 10 ; i++) {
        [_fileNameArr addObject:[NSString stringWithFormat:@"%@%ld    (%@)",kWHC_CellName,i + 1,@"单击下载视频文件"]];
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
            [_fileNameArr addObject:[NSString stringWithFormat:@"%@%ld    (%@)",kWHC_CellName,i + 1,@"单击下载视频文件"]];
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
    NSString * fileName = _fileNameArr[indexPath.row];
    if([Account downloadStateVoideFile:fileName]){
        [self.view toast:@"该视频已在个人中心离线视频中"];
        return;
    }
    if([WHCDownloadCenter downloadList].count < [WHCDownloadCenter maxDownloadCount]){
        [self.view startLoading];
        self.navigationController.navigationBar.userInteractionEnabled = NO;
    }else{
        [self.view toast:@"已经添加到了下载缓存"];
    }
    NSString * saveFilePath = Account.videoFolder;
    [WHCDownloadCenter startDownloadWithURL:[NSURL URLWithString:kWHC_DefaultDownloadUrl] savePath:saveFilePath savefileName:fileName delegate:self];
}

#pragma mark - WHCDownloadDelegate
//得到第一相应并判断要下载的文件是否已经完整下载了
- (void)WHCDownload:(WHC_Download *)download filePath:(NSString *)filePath hasACompleteDownload:(BOOL)has{
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    [self.view stopLoading];
    if(has){
        [self.view toast:@"该文件已下载请前往个人离线视频中心"];
    }else{
        [self.view toast:@"已经添加到了下载缓存"];
        NSMutableDictionary * downloadRecordDict = [NSMutableDictionary dictionaryWithContentsOfFile:Account.videoFileRecordPath];
        NSMutableDictionary * dict = downloadRecordDict[download.saveFileName];
        CGFloat  percent = (CGFloat)(download.downloadLen) / download.totalLen * 100.0;
        if(dict == nil){
            [downloadRecordDict setObject:@{@"fileName":download.saveFileName,
                                            @"currentDownloadLen":[NSString stringWithFormat:@"%.1fMB",((CGFloat)(download.downloadLen) / kWHC_1MB)],
                                            @"totalLen":[NSString stringWithFormat:@"%.1fMB",((CGFloat)(download.totalLen) / kWHC_1MB)],
                                            @"speed":@"0KB/S",
                                            @"processValue":@(percent / 100.0),
                                            @"downPath":download.downPath,
                                            @"state":@(Downloading)}.mutableCopy forKey:download.saveFileName];
            [downloadRecordDict writeToFile:Account.videoFileRecordPath atomically:YES];
        }else{
            [dict setObject:([NSString stringWithFormat:@"%.1fMB",((CGFloat)(download.downloadLen) / kWHC_1MB)]).copy forKey:@"currentDownloadLen"];
            [dict setObject:[NSString stringWithFormat:@"%.1fMB",((CGFloat)(download.totalLen) / kWHC_1MB)] forKey:@"totalLen"];
            [dict setObject:@(percent / 100.0) forKey:@"processValue"];
            [dict setObject:@(Downloading) forKey:@"state"];
            if([dict[@"downPath"] isEqualToString:@""]){
                [dict setObject:download.downPath forKey:@"downPath"];
            }
            [downloadRecordDict setObject:dict forKey:download.saveFileName];
            [downloadRecordDict writeToFile:Account.videoFileRecordPath atomically:YES];
        }
    }
}

//下载出错
- (void)WHCDownload:(WHC_Download *)download error:(NSError *)error{
    [self.view toast:[NSString stringWithFormat:@"文件:%@下载错误%@",download.saveFileName , error]];
    [self.view stopLoading];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}

//跟新下载进度
- (void)WHCDownload:(WHC_Download *)download
     didReceivedLen:(uint64_t)receivedLen
           totalLen:(uint64_t)totalLen
       networkSpeed:(NSString *)networkSpeed{
    
}

//下载结束
- (void)WHCDownload:(WHC_Download *)download filePath:(NSString *)filePath isSuccess:(BOOL)success{
    if(success){
        [self.view toast:[NSString stringWithFormat:@"文件:%@下载成功",download.saveFileName]];
    }
    [self.view stopLoading];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}

@end
