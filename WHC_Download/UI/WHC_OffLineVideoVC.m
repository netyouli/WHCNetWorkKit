//
//  WHC_OffLineVideoVC.m
//  DingLibrary
//
//  Created by 吴海超 on 15/7/9.
//  Copyright (c) 2015年 Rudy. All rights reserved.
//

/*
 *  qq:712641411
 *  iOS大神qq群:460122071
 *  gitHub:https://github.com/netyouli
 *  csdn:http://blog.csdn.net/windwhc/article/category/3117381
 */

#import "WHC_OffLineVideoVC.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MediaPlayer/MPMoviePlayerViewController.h>
#import <MediaPlayer/MPMusicPlayerController.h>
#import "WHC_FillScreenPlayerVC.h"
#import "WHC_DownloadFileCenter.h"
#import "WHC_ClientAccount.h"
#import "UIView+WHC_Loading.h"
#import "UIView+WHC_ViewProperty.h"
#import "UIView+WHC_Toast.h"

#define kFontSize             (15.0)
#define kCellHeight           (57.0)                  //cell高度
#define kMinPlaySize          (10.0)                   //最小播放尺寸
#define kCellName             (@"WHC_OffLineVideoCell")   //cell名称
#define kDownloadPlistName    (@"DownloadRecord")     //保存下载记录文件
@implementation DownloadObject

@end

@interface WHC_OffLineVideoCell ()<WHCDownloadDelegate>{
    UIImageView                 * _downloadingArrowV;   //下载动画箭头
    DownloadObject              * _downloadObject;      //下载对象
    UIImage                     * _arrowImage;
    NSString                    * _plistPath;
}
@property (nonatomic , strong)IBOutlet UILabel          * fileNameLab;
@property (nonatomic , strong)IBOutlet UILabel          * downLenLab;
@property (nonatomic , strong)IBOutlet UILabel          * speedLab;
@property (nonatomic , strong)IBOutlet UIProgressView   * downProgressV;
@property (nonatomic , strong)IBOutlet UIButton         * downBtn;
@property (nonatomic , strong)NSMutableArray            * videoObjectArr;    //视频文件数组
@end

@implementation WHC_OffLineVideoCell

- (void)awakeFromNib{
    _plistPath = Account.videoFileRecordPath;
    [_downBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.contentView sendSubviewToBack:_downBtn];
}

- (UIImage *)makeDownloadArrowImage{
    UIImage * arrowImage = nil;
    UIGraphicsBeginImageContext(CGSizeMake(kFontSize, kFontSize));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, _downBtn.backgroundColor.CGColor);
    NSString * arrow = @"↓";
    [arrow drawInRect:CGRectMake(0, 0, kFontSize, kFontSize) withAttributes:@{NSForegroundColorAttributeName:[UIColor blueColor],NSFontAttributeName:[UIFont boldSystemFontOfSize:kFontSize]}];
    arrowImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return arrowImage;
}

- (void)addAnimation{
    if(_downloadingArrowV){
        __weak  typeof(self) sf = self;
        [UIView animateWithDuration:1.2 animations:^{
            _downloadingArrowV.y = _downBtn.maxY;
        }completion:^(BOOL finished) {
            _downloadingArrowV.y = _downBtn.y - _downloadingArrowV.height;
            [sf addAnimation];
        }];
    }
}

- (void)addDownloadAnimation{
    if(_downloadingArrowV == nil){
        if(_arrowImage == nil){
            _arrowImage = [self makeDownloadArrowImage];
        }
        _downloadingArrowV = [[UIImageView alloc]initWithImage:_arrowImage];
        _downloadingArrowV.size = _arrowImage.size;
        _downloadingArrowV.xy = CGPointMake(_downBtn.x + (_downBtn.width - kFontSize) / 2.0, _downBtn.y - _arrowImage.size.height);
        [_downBtn setTitle:@"" forState:UIControlStateNormal];
        [self.contentView addSubview:_downloadingArrowV];
        [self.contentView sendSubviewToBack:_downloadingArrowV];
        [self addAnimation];
    }
}
- (void)removeDownloadAnimation{
    if(_downloadingArrowV){
        [_downloadingArrowV removeFromSuperview];
        _downloadingArrowV = nil;
    }
}

- (void)displayCell:(DownloadObject *)object{
    _downBtn.enabled = YES;
    _downloadObject = object;
    _fileNameLab.text = object.fileName;
    _downLenLab.text = [NSString stringWithFormat:@"%@/%@",object.currentDownloadLen,object.totalLen];
    _speedLab.text = object.speed;
    _downProgressV.progress = object.processValue;
    if(object.state == Downloading){
        [self addDownloadAnimation];
    }else{
        [self removeDownloadAnimation];
    }
    switch (object.state) {
        case Downloading:
            break;
        case DownloadCompleted:
            _speedLab.text = @"完成";
            _downBtn.enabled = NO;
            [_downBtn setTitle:@"▶" forState:UIControlStateNormal];
            break;
        case DownloadUncompleted:
            _speedLab.text = @"暂停";
            [_downBtn setTitle:@"■" forState:UIControlStateNormal];
            break;
        case DownloadWaitting:
            _speedLab.text = @"等待";
            [_downBtn setTitle:@"🕘" forState:UIControlStateNormal];
            break;
        default:
            break;
    }
}

- (IBAction)clickDownBtn:(UIButton *)sender{
    switch (_downloadObject.state) {
        case Downloading:{ //暂停操作
            WHC_Download * download = [WHCDownloadCenter downloadWithFileName:_downloadObject.fileName];
            _downloadObject.state = DownloadUncompleted;
            if(download){
                NSMutableDictionary * downloadRecordDict = [NSMutableDictionary dictionaryWithContentsOfFile:_plistPath];
                NSMutableDictionary * dict = downloadRecordDict[download.saveFileName];
                CGFloat  percent = (CGFloat)(download.downloadLen) / download.totalLen * 100.0;
                if(dict == nil){
                    [downloadRecordDict setObject:@{@"fileName":download.saveFileName,
                                                    @"currentDownloadLen":[NSString stringWithFormat:@"%.1fMB",((CGFloat)(download.downloadLen) / kWHC_1MB)],
                                                    @"totalLen":[NSString stringWithFormat:@"%.1fMB",((CGFloat)(download.totalLen) / kWHC_1MB)],
                                                    @"speed":@"0KB/S",
                                                    @"processValue":@(percent / 100.0),
                                                    @"downPath":download.downPath,
                                                    @"state":@(DownloadUncompleted)}.mutableCopy forKey:download.saveFileName];
                    [downloadRecordDict writeToFile:_plistPath atomically:YES];
                }else{
                    [dict setObject:([NSString stringWithFormat:@"%.1fMB",((CGFloat)(download.downloadLen) / kWHC_1MB)]).copy forKey:@"currentDownloadLen"];
                    [dict setObject:[NSString stringWithFormat:@"%.1fMB",((CGFloat)(download.totalLen) / kWHC_1MB)] forKey:@"totalLen"];
                    [dict setObject:@(percent / 100.0) forKey:@"processValue"];
                    [dict setObject:@(DownloadUncompleted) forKey:@"state"];
                    if([dict[@"downPath"] isEqualToString:@""]){
                        [dict setObject:download.downPath forKey:@"downPath"];
                    }
                    [downloadRecordDict setObject:dict forKey:download.saveFileName];
                    [downloadRecordDict writeToFile:_plistPath atomically:YES];
                }
            }
            [WHCDownloadCenter cancelDownloadWithFileName:_downloadObject.fileName delFile:NO];
        }
            break;
        case DownloadCompleted: //播放操作
            
            break;
        case DownloadUncompleted:{ //继续下载操作
            if([WHCDownloadCenter existCancelDownload]){
                [WHCDownloadCenter recoverDownloadWithName:_downloadObject.fileName delegate:self];
            }else{
                [WHCDownloadCenter startDownloadWithURL:[NSURL URLWithString:_downloadObject.downPath] savePath:Account.videoFolder savefileName:_downloadObject.fileName delegate:self];
            }
            _downloadObject.state = DownloadWaitting;
            WHC_Download * download = [WHCDownloadCenter downloadWithFileName:_downloadObject.fileName];
            NSMutableDictionary * downloadRecordDict = [NSMutableDictionary dictionaryWithContentsOfFile:_plistPath];
            NSMutableDictionary * dict = downloadRecordDict[download.saveFileName];
            if(dict){
                [dict setObject:@(DownloadWaitting) forKey:@"state"];
                [downloadRecordDict setObject:dict forKey:download.saveFileName];
                [downloadRecordDict writeToFile:_plistPath atomically:YES];
            }
        }
            break;
        case DownloadWaitting: //忽略
            break;
        default:
            break;

    }
    [self displayCell:_downloadObject];
}

- (DownloadObject *)currentDownloadObjectFileName:(NSString *)fileName{
    for (DownloadObject * tempObject in _videoObjectArr) {
        if([tempObject.fileName isEqualToString:fileName]){
            return tempObject;
        }
    }
    return nil;
}

#pragma mark - WHCDownloadDelegate
//得到第一相应并判断要下载的文件是否已经完整下载了
- (void)WHCDownload:(WHC_Download *)download filePath:(NSString *)filePath hasACompleteDownload:(BOOL)has{
    
}

//接受下载数据处理下载显示进度和网速
- (void)WHCDownload:(WHC_Download *)download didReceivedLen:(uint64_t)receivedLen totalLen:(uint64_t)totalLen networkSpeed:(NSString *)networkSpeed{
    NSMutableDictionary * downloadRecordDict = [NSMutableDictionary dictionaryWithContentsOfFile:_plistPath];
    for (NSInteger i = 0; i < downloadRecordDict.count; i++) {
        NSMutableDictionary * tempDict = downloadRecordDict[download.saveFileName];
        if(tempDict == nil){
            [downloadRecordDict setObject:@{@"fileName":download.saveFileName,
                                            @"currentDownloadLen":[NSString stringWithFormat:@"%.1fMB",((CGFloat)(download.downloadLen) / kWHC_1MB)],
                                            @"totalLen":[NSString stringWithFormat:@"%.1fMB",((CGFloat)(download.totalLen) / kWHC_1MB)],
                                            @"speed":@"0KB/S",
                                            @"processValue":@(((CGFloat)receivedLen / totalLen * 100.0) / 100.0),
                                            @"downPath":download.downPath,
                                            @"state":@(Downloading)}.mutableCopy forKey:download.saveFileName];
            [downloadRecordDict writeToFile:_plistPath atomically:YES];
        }else{
            if([tempDict[@"downPath"] isEqualToString:@""]){
                [tempDict setObject:download.downPath forKey:@"downPath"];
            WHC:
                [downloadRecordDict setObject:tempDict forKey:download.saveFileName];
                [downloadRecordDict writeToFile:_plistPath atomically:YES];
            }else if ([tempDict[@"state"] integerValue] == DownloadWaitting){
                [tempDict setObject:@(Downloading) forKey:@"state"];
                goto WHC;
            }
        }
    }
    DownloadObject * object = [self currentDownloadObjectFileName:download.saveFileName];
    if(object){
        CGFloat  percent = (CGFloat)receivedLen / totalLen * 100.0;
        object.processValue = percent / 100.0;
        object.currentDownloadLen = [NSString stringWithFormat:@"%.1fMB",((CGFloat)receivedLen / kWHC_1MB)];
        object.totalLen = [NSString stringWithFormat:@"%.1fMB",((CGFloat)totalLen / kWHC_1MB)];
        object.speed = networkSpeed;
        object.state = Downloading;
        object.downPath = download.downPath;
        [self displayCell:object];
    }
}

//下载出错
- (void)WHCDownload:(WHC_Download *)download error:(NSError *)error{
    _downloadObject.state = DownloadUncompleted;
    NSMutableDictionary * downloadRecordDict = [NSMutableDictionary dictionaryWithContentsOfFile:_plistPath];
    NSMutableDictionary * dict = downloadRecordDict[download.saveFileName];
    if(dict){
        [dict setObject:@(DownloadUncompleted) forKey:@"state"];
        [downloadRecordDict setObject:dict forKey:download.saveFileName];
        [downloadRecordDict writeToFile:_plistPath atomically:YES];
    }
    [self toast:[NSString stringWithFormat:@"%@",error.description]];
    [self displayCell:_downloadObject];
}

//下载结束
- (void)WHCDownload:(WHC_Download *)download filePath:(NSString *)filePath isSuccess:(BOOL)success{
    DownloadObject * object = [self currentDownloadObjectFileName:download.saveFileName];
    if(success){
        NSMutableDictionary * downloadRecordDict = [NSMutableDictionary dictionaryWithContentsOfFile:_plistPath];
        for (NSInteger i = 0; i < downloadRecordDict.count; i++) {
            NSMutableDictionary * tempDict = downloadRecordDict[download.saveFileName];
            if(tempDict){
                [tempDict setObject:((NSString *)tempDict[@"totalLen"]).copy forKey:@"currentDownloadLen"];
                [tempDict setObject:@(1.0) forKey:@"processValue"];
                [tempDict setObject:@(DownloadCompleted) forKey:@"state"];
                if([tempDict[@"downPath"] isEqualToString:@""]){
                    [tempDict setObject:download.downPath forKey:@"downPath"];
                }
                [downloadRecordDict setObject:tempDict forKey:download.saveFileName];
                [downloadRecordDict writeToFile:_plistPath atomically:YES];
                break;
            }
        }
        NSMutableDictionary * dict = downloadRecordDict[download.saveFileName];
        if(dict == nil){
            [downloadRecordDict setObject:@{@"fileName":download.saveFileName,
                                            @"currentDownloadLen":[NSString stringWithFormat:@"%.1fMB",((CGFloat)(download.downloadLen) / kWHC_1MB)],
                                            @"totalLen":[NSString stringWithFormat:@"%.1fMB",((CGFloat)(download.totalLen) / kWHC_1MB)],
                                            @"speed":@"0KB/S",
                                            @"processValue":@(1.0),
                                            @"downPath":download.downPath,
                                            @"state":@(DownloadCompleted)}.mutableCopy forKey:download.saveFileName];
            [downloadRecordDict writeToFile:_plistPath atomically:YES];
        }else{
            [dict setObject:([NSString stringWithFormat:@"%.1fMB",((CGFloat)(download.downloadLen) / kWHC_1MB)]).copy forKey:@"currentDownloadLen"];
            [dict setObject:[NSString stringWithFormat:@"%.1fMB",((CGFloat)(download.totalLen) / kWHC_1MB)] forKey:@"totalLen"];
            [dict setObject:@(1.0) forKey:@"processValue"];
            [dict setObject:@(DownloadCompleted) forKey:@"state"];
            if([dict[@"downPath"] isEqualToString:@""]){
                [dict setObject:download.downPath forKey:@"downPath"];
            }
            [downloadRecordDict setObject:dict forKey:download.saveFileName];
            [downloadRecordDict writeToFile:_plistPath atomically:YES];
        }
        if(object){
            object.processValue = 1.0;
            object.currentDownloadLen = object.totalLen;
            object.state = DownloadCompleted;
            object.speed = @"完成";
        }
    }
    if(object){
        [self displayCell:object];
    }
}

@end

#pragma mark - 控制器部分

@interface WHC_OffLineVideoVC (){
    NSMutableArray              *     _videoObjectArr;    //视频文件数组
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
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [_offLineTableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [Account saveDownloadRecord];
}

- (void)layoutUI{
    [_offLineTableView registerNib:[UINib nibWithNibName:kCellName bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kCellName];
}

- (void)initData{
    _plistPath = Account.videoFileRecordPath;
    NSFileManager  * fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:_plistPath]){
        [fm createFileAtPath:_plistPath contents:nil attributes:nil];
        [@{}.mutableCopy writeToFile:_plistPath atomically:YES];
    }
    [WHCDownloadCenter replaceCurrentDownloadDelegate:self];
    _videoObjectArr = [NSMutableArray array];
    NSMutableDictionary   * downloadRecordDict = [NSMutableDictionary dictionaryWithContentsOfFile:_plistPath];
    
    NSFileManager  * fileManager = [NSFileManager defaultManager];
    NSError        * error = nil;
    NSArray * fileArr = [[fileManager contentsOfDirectoryAtPath:Account.videoFolder error:&error] mutableCopy];
    if(fileArr){
        for (NSInteger i = 0; i < fileArr.count; i++){
            NSString  * fileName = fileArr[i];
            if(![fileName isEqualToString:@".DS_Store"]){
                DownloadObject * object = [DownloadObject new];
                NSMutableDictionary * tempDict = downloadRecordDict[fileName];
                uint64_t fileSize = [[fileManager attributesOfItemAtPath:[NSString stringWithFormat:@"%@%@",Account.videoFolder,fileName] error:&error] fileSize];
                NSString  * strCurrentLen = [NSString stringWithFormat:@"%.1fMB",((CGFloat)(fileSize) / kWHC_1MB)];
                if(tempDict){
                    object.fileName = tempDict[@"fileName"];
                    object.processValue = [[strCurrentLen componentsSeparatedByString:@"MB"].firstObject doubleValue] / [(NSString *)[tempDict[@"totalLen"] componentsSeparatedByString:@"MB"].firstObject doubleValue];
                    object.currentDownloadLen = [NSString stringWithFormat:@"%.1fMB",((CGFloat)(fileSize) / kWHC_1MB)];
                    object.totalLen = tempDict[@"totalLen"];
                    object.speed = [tempDict[@"totalLen"] isEqualToString:tempDict[@"currentDownloadLen"]] ? @"完成" : @"暂停";
                    object.downPath = tempDict[@"downPath"];
                    object.state = [tempDict[@"totalLen"] isEqualToString:strCurrentLen] ? DownloadCompleted : DownloadUncompleted;
                    [tempDict setObject:@(object.processValue) forKey:@"processValue"];
                    [tempDict setObject:strCurrentLen forKey:@"currentDownloadLen"];
                    [tempDict setObject:@(object.state) forKey:@"state"];
                    [downloadRecordDict setObject:tempDict forKey:fileName];
                }else{
                    object.fileName = fileName;
                    object.processValue = 0;
                    object.currentDownloadLen = strCurrentLen;
                    object.totalLen = [NSString stringWithFormat:@"%.1fMB",((CGFloat)(fileSize) / kWHC_1MB)];
                    object.speed = @"暂停";
                    object.state = DownloadCompleted;
                    object.downPath = @"";
                    [downloadRecordDict setObject:@{@"fileName":fileName,
                                                    @"currentDownloadLen":object.currentDownloadLen,
                                                    @"totalLen":object.totalLen,
                                                    @"speed":@"0KB/S",
                                                    @"processValue":@(1.0),
                                                    @"downPath":object.downPath,
                                                    @"state":@(DownloadCompleted)}.mutableCopy forKey:fileName];
                }
                [downloadRecordDict writeToFile:_plistPath atomically:YES];
                [_videoObjectArr addObject:object];
            }
        }
    }
    NSArray * downloadArr = [WHCDownloadCenter downloadList];
    for (WHC_Download * download in downloadArr) {
        if(download.downloading == NO){//等待下载
            DownloadObject * object = [DownloadObject new];
            object.fileName = download.saveFileName;
            object.processValue = 0.0;
            object.currentDownloadLen = @"0MB";
            object.totalLen = @"0MB";
            object.speed = @"等待";
            object.state = DownloadWaitting;
            object.downPath = download.downPath;
            [_videoObjectArr addObject:object];
        }
    }
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

- (DownloadObject *)currentDownloadObjectFileName:(NSString *)fileName{
    for (DownloadObject * tempObject in _videoObjectArr) {
        if([tempObject.fileName isEqualToString:fileName]){
            return tempObject;
        }
    }
    return nil;
}

#pragma mark - UITableViewDelegate UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return kCellHeight;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return [UIView new];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _videoObjectArr.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath{
    return @"删除";
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    DownloadObject * object = _videoObjectArr[indexPath.row];
    NSString       * videoFilePath = [NSString stringWithFormat:@"%@%@",Account.videoFolder,object.fileName];
    NSFileManager  * fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:videoFilePath error:nil];
    [_videoObjectArr removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    NSMutableDictionary * downloadRecordDict = [NSMutableDictionary dictionaryWithContentsOfFile:_plistPath];
    NSDictionary * tempDict = downloadRecordDict[object.fileName];
    if(tempDict){
        [downloadRecordDict removeObjectForKey:object.fileName];
        [downloadRecordDict writeToFile:_plistPath atomically:YES];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    WHC_OffLineVideoCell  * cell = [tableView dequeueReusableCellWithIdentifier:kCellName];
    cell.selectedBackgroundView = [UIView new];
    cell.selectedBackgroundView.backgroundColor = [UIColor whiteColor];
    DownloadObject * object = _videoObjectArr[indexPath.row];
    [WHCDownloadCenter replaceCurrentDownloadDelegate:cell fileName:object.fileName];
    cell.videoObjectArr = _videoObjectArr;
    [cell displayCell:_videoObjectArr[indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    DownloadObject * object = _videoObjectArr[indexPath.row];
    WHC_Download * download = [WHCDownloadCenter downloadWithFileName:object.fileName];
    if(download){
        if(((CGFloat)download.totalLen) / kWHC_1MB >= kMinPlaySize){
            if(((CGFloat)download.downloadLen) / kWHC_1MB >= kMinPlaySize){//允许播放
                WHC_FillScreenPlayerVC * vc = [WHC_FillScreenPlayerVC new];
                vc.playUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@",Account.videoFolder,download.saveFileName]];
                vc.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:vc animated:YES];
            }
        }else{
            [self.view toast:@"该文件尺寸大小无法播放"];
        }
    }else{
        NSFileManager  * fm = [NSFileManager defaultManager];
        uint64_t actualFileLen = [[fm attributesOfItemAtPath:[NSString stringWithFormat:@"%@%@",Account.videoFolder,object.fileName] error:nil] fileSize];
        NSMutableDictionary * downloadRecordDict = [NSMutableDictionary dictionaryWithContentsOfFile:_plistPath];
        NSDictionary * tempDict = downloadRecordDict[object.fileName];
        DownloadState state = NoneState;
        if(tempDict){
            state = [tempDict[@"state"] integerValue];
        }
        if(((CGFloat)actualFileLen) / kWHC_1MB >= kMinPlaySize || state == DownloadCompleted){
            WHC_FillScreenPlayerVC * vc = [WHC_FillScreenPlayerVC new];
            NSString * playPath = [NSString stringWithFormat:@"%@%@",Account.videoFolder,object.fileName];
            vc.playUrl = [NSURL fileURLWithPath:playPath];
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }else{
            [self.view toast:@"该文件尺寸大小无法播放请下载在播放"];
        }
    }
    
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
