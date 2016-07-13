//
//  WHC_OffLineVideoVC.m
//  DingLibrary
//
//  Created by 吴海超 on 15/7/9.
//  Copyright (c) 2015年 Rudy. All rights reserved.
//

/*
 *  qq:712641411
 *  iOSqq群:302157745
 *  gitHub:https://github.com/netyouli
 *  csdn:http://blog.csdn.net/windwhc/article/category/3117381
 */

#import "WHC_OffLineVideoVC.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MediaPlayer/MPMoviePlayerViewController.h>
#import <MediaPlayer/MPMusicPlayerController.h>
#import "WHC_FillScreenPlayerVC.h"
#import "UIView+WHC_Loading.h"
#import "UIView+WHC_ViewProperty.h"
#import "UIView+WHC_Toast.h"
#import "AppDelegate.h"

@import WHCNetWorkKit;

#define kFontSize             (15.0)
#define kCellHeight           (57.0)                   //cell高度
#define kMinPlaySize          (10.0)                   //最小播放尺寸
#define kCellName             (@"WHC_OffLineVideoCell")//cell名称

@interface WHC_OffLineVideoCell ()<WHC_DownloadDelegate>{
    UIButton                    * _downloadArrowButton;
    WHC_DownloadObject          * _downloadObject;
    BOOL                          _hasDownloadAnimation;
}
@property (nonatomic , strong)IBOutlet UILabel          * titleLabel;
@property (nonatomic , strong)IBOutlet UILabel          * downloadValueLabel;
@property (nonatomic , strong)IBOutlet UILabel          * speedLabel;
@property (nonatomic , strong)IBOutlet UIProgressView   * progressBar;
@property (nonatomic , strong)IBOutlet UIButton         * downloadButton;
@end

@implementation WHC_OffLineVideoCell

- (void)awakeFromNib{
    [super awakeFromNib];
    _downloadButton.clipsToBounds = true;
    [_downloadButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
}

- (void)addDownloadAnimation {
    if(_downloadArrowButton){
        [UIView animateWithDuration:1.2 animations:^{
            _downloadArrowButton.y = _downloadArrowButton.height;
        }completion:^(BOOL finished) {
            _downloadArrowButton.y = -_downloadArrowButton.height;
            [self addDownloadAnimation];
        }];
    }
}

- (void)startDownloadAnimation {
    if (_downloadArrowButton == nil) {
        _downloadArrowButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _downloadArrowButton.enabled = false;
        _downloadArrowButton.frame = _downloadButton.bounds;
        [_downloadArrowButton setTitle:@"↓" forState:UIControlStateNormal];
        [_downloadArrowButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _downloadArrowButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    }
    if (!_hasDownloadAnimation) {
        _hasDownloadAnimation = true;
        _downloadArrowButton.y = -_downloadArrowButton.height;
        [_downloadButton addSubview:_downloadArrowButton];
        [self addDownloadAnimation];
    }
}

- (void)removeDownloadAnimtion {
    _hasDownloadAnimation = false;
    if (_downloadArrowButton != nil) {
        [_downloadArrowButton removeFromSuperview];
        _downloadArrowButton = nil;
    }
}

- (void)updateDownloadValue {
    _titleLabel.text = _downloadObject.fileName;
    _progressBar.progress = _downloadObject.downloadProcessValue;
    _downloadValueLabel.text = _downloadObject.downloadProcessText;
    NSString * strSpeed = _downloadObject.downloadSpeed;
    if (_downloadObject.downloadState != WHCDownloading) {
        [self removeDownloadAnimtion];
    }else {
        [self startDownloadAnimation];
    }
    switch (_downloadObject.downloadState) {
        case WHCDownloadWaitting:
            [_downloadButton setTitle:@"🕘" forState:UIControlStateNormal];
            strSpeed = @"等待";
            break;
        case WHCDownloading:
            [_downloadButton setTitle:@"" forState:UIControlStateNormal];
            break;
        case WHCDownloadCanceled:
            [_downloadButton setTitle:@"■" forState:UIControlStateNormal];
            strSpeed = @"暂停";
            break;
        case WHCDownloadCompleted:
            [_downloadButton setTitle:@"▶" forState:UIControlStateNormal];
            strSpeed = @"完成";
        case WHCNone:
            break;
    }
    _speedLabel.text = strSpeed;
}


- (IBAction)clickDownload:(UIButton *)sender {
    switch (_downloadObject.downloadState) {
        case WHCDownloading:
            _downloadObject.downloadState = WHCDownloadCanceled;
    #if WHC_BackgroundDownload
            [[WHC_SessionDownloadManager shared] cancelDownloadWithFileName:_downloadObject.fileName deleteFile:NO];
    #else
            [[WHC_HttpManager shared] cancelDownloadWithFileName:_downloadObject.fileName deleteFile:NO];
    #endif
            break;
        case WHCDownloadCanceled:{
            _downloadObject.downloadState = WHCDownloadWaitting;
    #if WHC_BackgroundDownload
            [[WHC_SessionDownloadManager shared] setBundleIdentifier:@"com.WHC.WHCNetWorkKit.backgroundsession"];
            WHC_DownloadSessionTask * downloadTask = [[WHC_SessionDownloadManager shared] download:_downloadObject.downloadPath
                                                 savePath:[WHC_DownloadObject videoDirectory]
                                             saveFileName:_downloadObject.fileName delegate:self];
            downloadTask.index = self.index;
            
    #else
            WHC_DownloadOperation * operation = [[WHC_HttpManager shared] download:_downloadObject.downloadPath
                                      savePath:[WHC_DownloadObject videoDirectory]
                                  saveFileName:_downloadObject.fileName delegate:self];
            operation.index = self.index;
    #endif
            [self updateDownloadValue];
        }
            break;
        case WHCDownloadWaitting:
            break;
        case WHCDownloadCompleted:
            if (_delegate && [_delegate respondsToSelector:@selector(videoPlayerIndex:)]) {
                [_delegate videoPlayerIndex:_index];
            }
            break;
        default:
            break;
    }
}

- (void)displayCell:(WHC_DownloadObject *)object index:(NSInteger)index {
    self.index = index;
    _downloadObject = object;
    if (_downloadObject.downloadState == WHCNone ||
        _downloadObject.downloadState == WHCDownloading ) {
        _downloadObject.downloadState = WHCDownloadWaitting;
    }
#if WHC_BackgroundDownload
    [[WHC_SessionDownloadManager shared] setBundleIdentifier:@"com.WHC.WHCNetWorkKit.backgroundsession"];
    WHC_DownloadSessionTask * downloadTask = [[WHC_SessionDownloadManager shared] replaceCurrentDownloadOperationDelegate:self fileName:_downloadObject.fileName];
    if ([[WHC_SessionDownloadManager shared] existDownloadOperationTaskWithFileName:_downloadObject.fileName]) {
        if (_downloadObject.downloadState == WHCDownloadCanceled) {
            _downloadObject.downloadState = WHCDownloadWaitting;
        }
    }
    downloadTask.index = index;
#else
    WHC_DownloadOperation * operation = [[WHC_HttpManager shared] replaceCurrentDownloadOperationDelegate:self fileName:_downloadObject.fileName];
    if ([[WHC_HttpManager shared] existDownloadOperationTaskWithFileName:_downloadObject.fileName]) {
        if (_downloadObject.downloadState == WHCDownloadCanceled) {
            _downloadObject.downloadState = WHCDownloadWaitting;
        }
    }
    operation.index = index;
#endif
    [self updateDownloadValue];
    [self removeDownloadAnimtion];
}

- (void)saveDownloadState:(WHC_DownloadOperation *)operation {
    _downloadObject.currentDownloadLenght = operation.recvDataLenght;
    _downloadObject.totalLenght = operation.fileTotalLenght;
    [_downloadObject writeDiskCache];
}

//WHC_DownloadSessionTask : WHC_DownloadOperation

#pragma mark - WHC_DownloadDelegate -
- (void)WHCDownloadResponse:(nonnull WHC_DownloadOperation *)operation
                      error:(nullable NSError *)error
                         ok:(BOOL)isOK {
    if (isOK) {
        if (self.index == operation.index) {
            _downloadObject.downloadState = WHCDownloading;
            _downloadObject.currentDownloadLenght = operation.recvDataLenght;
            _downloadObject.totalLenght = operation.fileTotalLenght;
            [self updateDownloadValue];
        }else {
            WHC_DownloadObject * tempDownloadObject = [WHC_DownloadObject readDiskCache:operation.strUrl];
            if (tempDownloadObject != nil) {
                tempDownloadObject.downloadState = WHCDownloading;
                tempDownloadObject.currentDownloadLenght = operation.recvDataLenght;
                tempDownloadObject.totalLenght = operation.fileTotalLenght;
                [tempDownloadObject writeDiskCache];
                if (_delegate && [_delegate respondsToSelector:@selector(updateDownloadValue: index:)]) {
                    [_delegate updateDownloadValue:tempDownloadObject index:operation.index];
                }
            }
        }
    }else {
        _downloadObject.downloadState = WHCNone;
        if (_delegate &&
            [_delegate respondsToSelector:@selector(videoDownload:index:strUrl:)]) {
            [_delegate videoDownload:error index:_index strUrl:operation.strUrl];
        }
    }
}

- (void)WHCDownloadProgress:(nonnull WHC_DownloadOperation *)operation
                       recv:(uint64_t)recvLength
                      total:(uint64_t)totalLength
                      speed:(nullable NSString *)speed {
    if (operation.index == self.index) {
        if (_downloadObject.totalLenght < 10) {
            _downloadObject.totalLenght = totalLength;
        }
        _downloadObject.currentDownloadLenght = recvLength;
        _downloadObject.downloadSpeed = speed;
        _downloadObject.downloadState = WHCDownloading;
        [self updateDownloadValue];
        [self startDownloadAnimation];
    }
}

- (void)WHCDownloadDidFinished:(nonnull WHC_DownloadOperation *)operation
                          data:(nullable NSData *)data
                         error:(nullable NSError *)error
                       success:(BOOL)isSuccess {
    if (isSuccess) {
        if (self.index == operation.index) {
            _downloadObject.downloadState = WHCDownloadCompleted;
            [self saveDownloadState:operation];
        }else {
            WHC_DownloadObject * tempDownloadObject = [WHC_DownloadObject readDiskCache:operation.strUrl];
            if (tempDownloadObject != nil) {
                tempDownloadObject.downloadState = WHCDownloadCompleted;
                tempDownloadObject.currentDownloadLenght = operation.recvDataLenght;
                tempDownloadObject.totalLenght = operation.fileTotalLenght;
                [tempDownloadObject writeDiskCache];
                if (_delegate && [_delegate respondsToSelector:@selector(updateDownloadValue:index:)]) {
                    [_delegate updateDownloadValue:tempDownloadObject index:operation.index];
                }
            }
        }
    }else {
        
        WHC_DownloadObject * tempDownloadObject;
        if (self.index == operation.index) {
            _downloadObject.downloadState = WHCDownloadCanceled;
        }else {
            tempDownloadObject = [WHC_DownloadObject readDiskCache:operation.strUrl];
            if (tempDownloadObject != nil) {
                tempDownloadObject.downloadState = WHCDownloadCanceled;
            }
        }
        if (error != nil &&
            error.code == WHCCancelDownloadError &&
            !operation.isDeleted) {
                if (self.index == operation.index) {
                    [self saveDownloadState:operation];
                }else {
                    if (tempDownloadObject != nil) {
                        tempDownloadObject.currentDownloadLenght = operation.recvDataLenght;
                        tempDownloadObject.totalLenght = operation.fileTotalLenght;
                        [tempDownloadObject writeDiskCache];
                    }
                    
                }
                [self saveDownloadState:operation];
            }else {
                [[[UIAlertView alloc] initWithTitle:@"下载失败" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            }
        if (tempDownloadObject != nil) {
            if (_delegate && [_delegate respondsToSelector:@selector(updateDownloadValue:index:)]) {
                [_delegate updateDownloadValue:tempDownloadObject index:operation.index];
            }
        }
    }
    if (self.index == operation.index) {
        [self updateDownloadValue];
    }
}


@end

#pragma mark - 控制器部分

@interface WHC_OffLineVideoVC () <WHC_OffLineVideoCellDelegate>{
    NSMutableArray              *     _downloadObjectArr;
    MPMoviePlayerViewController *     playerViewController;
    NSString                    *     _plistPath;
}
@property (nonatomic , strong)IBOutlet  UITableView  * offLineTableView;
@end

@implementation WHC_OffLineVideoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"离线视频中心";
    [self initData];
    [self layoutUI];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [_offLineTableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [_offLineTableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

- (void)layoutUI{
    [_offLineTableView registerNib:[UINib nibWithNibName:kCellName bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kCellName];
}

- (void)initData{
    _downloadObjectArr = [NSMutableArray arrayWithArray:[WHC_DownloadObject readDiskAllCache]];
    [_offLineTableView reloadData];
}

#pragma mark - WHC_OffLineVideoCellDelegate
- (void)videoDownload:(NSError *)error index:(NSInteger)index strUrl:(NSString *)strUrl {
    if (error != nil) {
        [self.view toast:error.userInfo[NSLocalizedDescriptionKey]];
    }
    WHC_DownloadObject * downloadObject = _downloadObjectArr[index];
    [downloadObject removeFromDisk];
    [_downloadObjectArr removeObjectAtIndex:index];
    [_offLineTableView reloadData];
}

- (void)updateDownloadValue:(WHC_DownloadObject *)downloadObject index:(NSInteger)index {
    if (downloadObject != nil) {
        WHC_DownloadObject * tempDownloadObject = _downloadObjectArr[index];
        tempDownloadObject.currentDownloadLenght = downloadObject.currentDownloadLenght;
        tempDownloadObject.totalLenght = downloadObject.totalLenght;
        tempDownloadObject.downloadSpeed = downloadObject.downloadSpeed;
        tempDownloadObject.downloadState = downloadObject.downloadState;
    }
}

- (void)videoPlayerIndex:(NSInteger)index {
    
}

-(void) playMp4:(NSString*)url{
    WHC_FillScreenPlayerVC  * vc = [WHC_FillScreenPlayerVC new];
    vc.playUrl = [NSURL fileURLWithPath:url];
    [self.navigationController pushViewController:vc animated:NO];
}

- (void)movieFinishedCallback:(NSNotification *)notifiy{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    MPMoviePlayerController *player = [notifiy object];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:player];
    [player stop];
    [playerViewController.navigationController  popViewControllerAnimated:YES];
}

#pragma mark - UITableViewDelegate UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return kCellHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return [UIView new];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _downloadObjectArr.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath{
    return @"删除";
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger row = indexPath.row;
    WHC_DownloadObject * downloadObject = _downloadObjectArr[row];
#if WHC_BackgroundDownload
    [[WHC_SessionDownloadManager shared] cancelDownloadWithFileName:downloadObject.fileName deleteFile:YES];
#else
    [[WHC_HttpManager shared] cancelDownloadWithFileName:downloadObject.fileName deleteFile:YES];
#endif
    [downloadObject removeFromDisk];
    [_downloadObjectArr removeObjectAtIndex:row];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    WHC_OffLineVideoCell  * cell = [tableView dequeueReusableCellWithIdentifier:kCellName];
    NSInteger row = indexPath.row;
    cell.delegate = self;
    [cell displayCell:_downloadObjectArr[row] index:row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
//    DownloadObject * object = _videoObjectArr[indexPath.row];
//    WHC_Download * download = [WHCDownloadCenter downloadWithFileName:object.fileName];
//    if(download){
//        if(((CGFloat)download.totalLen) / kWHC_1MB >= kMinPlaySize){
//            if(((CGFloat)download.downloadLen) / kWHC_1MB >= kMinPlaySize){//允许播放
//                WHC_FillScreenPlayerVC * vc = [WHC_FillScreenPlayerVC new];
//                vc.playUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@",Account.videoFolder,download.saveFileName]];
//                vc.hidesBottomBarWhenPushed = YES;
//                [self.navigationController pushViewController:vc animated:YES];
//            }
//        }else{
//            [self.view toast:@"该文件尺寸大小无法播放"];
//        }
//    }else{
//        NSFileManager  * fm = [NSFileManager defaultManager];
//        uint64_t actualFileLen = [[fm attributesOfItemAtPath:[NSString stringWithFormat:@"%@%@",Account.videoFolder,object.fileName] error:nil] fileSize];
//        NSMutableDictionary * downloadRecordDict = [NSMutableDictionary dictionaryWithContentsOfFile:_plistPath];
//        NSDictionary * tempDict = downloadRecordDict[object.fileName];
//        DownloadState state = NoneState;
//        if(tempDict){
//            state = [tempDict[@"state"] integerValue];
//        }
//        if(((CGFloat)actualFileLen) / kWHC_1MB >= kMinPlaySize || state == DownloadCompleted){
//            WHC_FillScreenPlayerVC * vc = [WHC_FillScreenPlayerVC new];
//            NSString * playPath = [NSString stringWithFormat:@"%@%@",Account.videoFolder,object.fileName];
//            vc.playUrl = [NSURL fileURLWithPath:playPath];
//            vc.hidesBottomBarWhenPushed = YES;
//            [self.navigationController pushViewController:vc animated:YES];
//        }else{
//            [self.view toast:@"该文件尺寸大小无法播放请下载在播放"];
//        }
//    }
    
}


@end
