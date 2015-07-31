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

#define kWHC_DefaultDownloadUrl   (@"http://s.dingboshi.cn:8080/school/file/201507/resource/79e01f8be9db444291257b067ccffbc7.mp4")
@interface ViewController ()<WHCDownloadDelegate>{
    WHC_Download  * _download;            //当前下载对象
    NSString      * _filePath;            //保存下载文件路径
    NSString      * _fileName;            //自定义存储下载文件名
    BOOL            _isDownload;          //是否进行了下载
}
@property (nonatomic , strong)IBOutlet  UITextField     * downUrlTF;               //url编辑框
@property (nonatomic , strong)IBOutlet  UIProgressView  * downProgressV;           //下载进度条
@property (nonatomic , strong)IBOutlet  UILabel         * percentLab;              //下载百分比标签
@property (nonatomic , strong)IBOutlet  UILabel         * curDownloadSizeLab;      //当前下载文件大小标签
@property (nonatomic , strong)IBOutlet  UILabel         * downloadSpeedLab;        //当前下载速度标签
@property (nonatomic , strong)IBOutlet  UIButton        * startDownloadBtn;        //开始下载按钮
@property (nonatomic , strong)IBOutlet  UIButton        * cancelDownloadBtn;       //取消下载按钮
@property (nonatomic , strong)IBOutlet  UIButton        * cancelAndDelDownloadBtn; //取消下载和删除文件按钮
@property (nonatomic , strong)IBOutlet  UIButton        * restartDownloadBtn;      //继续下载按钮
@property (nonatomic , strong)IBOutlet  UIButton        * delDownloadBtn;          //删除文件按钮
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self layoutUI];
    _filePath = [NSString stringWithFormat:@"%@/Library/Caches/WHCFiles/",NSHomeDirectory()];
    _fileName = @"吴海超下载测试文件.mp4";
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)layoutUI{
    _downUrlTF.text = kWHC_DefaultDownloadUrl;
}

- (void)alert:(NSString *)msg{
    UIAlertView  * alert = [[UIAlertView alloc]initWithTitle:msg message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];
}

#pragma mark - action
- (IBAction)clickStartDownload:(UIButton *)sender{
    switch (sender.tag) {
        case 0:{//开始下载
            if(_downUrlTF.text && _downUrlTF.text.length > 0){
                if(_isDownload){
                    [self alert:@"正在下载"];
                }else{
                    NSURL * url = [NSURL URLWithString:kWHC_DefaultDownloadUrl];
                    _download = [WHCDownloadCenter startDownloadWithURL:url savePath:_filePath  savefileName:_fileName delegate:self];
                    _isDownload = YES;
                }
            }else{
                UIAlertView  * alert = [[UIAlertView alloc]initWithTitle:@"下载地址错误" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                [alert show];
            }
        }
            break;
        case 1:{//取消下载
            [WHCDownloadCenter cancelDownloadWithFileName:_fileName delFile:NO];
            _isDownload = NO;
        }
            break;
        case 2:{//取消下载并删除文件
            [WHCDownloadCenter cancelDownloadWithFileName:_fileName delFile:YES];
            _isDownload = NO;
        }
            break;
        case 3:{//继续下载
            if(_isDownload){
                [self alert:@"正在下载"];
            }else{
                _download = [WHCDownloadCenter recoverDownloadWithName:_fileName];
                _isDownload = YES;
            }
        }
            break;
        case 4:{//删除文件
            if(_isDownload){
                [self alert:@"正在下载"];
            }else{
                __autoreleasing NSError  * error = nil;
                NSString  *  strError = nil;
                NSFileManager  * fm = [NSFileManager defaultManager];
                NSString  * filePath = [NSString stringWithFormat:@"%@%@",_filePath , _fileName];
                if([fm fileExistsAtPath:filePath]){
                    [fm removeItemAtPath:filePath error:&error];
                }
                if(error){
                    strError = @"文件删除失败";
                }else{
                    strError = @"文件删除成功";
                }
                UIAlertView  * alert = [[UIAlertView alloc]initWithTitle:strError message:error.description delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                [alert show];
            }
        }
        default:
            break;
    }
    }

- (IBAction)exitKeyborad:(UITextField *)sender{
    [sender resignFirstResponder];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex == 0){//覆盖下载
        __autoreleasing NSError  * error = nil;
        NSFileManager  * fm = [NSFileManager defaultManager];
        [fm removeItemAtPath:[NSString stringWithFormat:@"%@%@",_filePath,_fileName] error:&error];
        if(error){
            UIAlertView  * alert = [[UIAlertView alloc]initWithTitle:@"文件删除失败" message:error.description delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
        }else{
            if(_isDownload){
                [self alert:@"正在下载"];
            }else{
                NSURL * url = [NSURL URLWithString:kWHC_DefaultDownloadUrl];
                _download = [WHCDownloadCenter startDownloadWithURL:url savePath:_filePath  savefileName:_fileName delegate:self];
                _isDownload = YES;
            }
        }
    }
}

#pragma mark - WHCDownloadDelegate
//得到第一响应
- (void)WHCDownload:(WHC_Download *)download filePath:(NSString *)filePath hasACompleteDownload:(BOOL)has{
    NSLog(@"filePath = %@",filePath);
    if(has){
        [self alert:@"该文件已经完整下载了"];
        _isDownload = NO;
    }else{
        NSLog(@"下载开始");
    }
}

//接受下载数据处理下载显示进度以及下载速度
- (void)WHCDownload:(WHC_Download *)download didReceivedLen:(uint64_t)receivedLen totalLen:(uint64_t)totalLen networkSpeed:(NSString *)networkSpeed{
    CGFloat  percent = (CGFloat)receivedLen / totalLen * 100.0;
    _percentLab.text = [NSString stringWithFormat:@"%.1f%%",percent];  //显示下载百分比
    _downProgressV.progress = percent / 100.0;                         //显示下载进度
    //显示下载文件大小
    _curDownloadSizeLab.text = [NSString stringWithFormat:@"%.1fMB/%.1fMB",((CGFloat)receivedLen / 1024.0) / 1024.0 ,((CGFloat)totalLen / 1024.0) / 1024.0];
    _downloadSpeedLab.text = networkSpeed;                            //显示当前下载速度
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
        UIAlertView  * alert = [[UIAlertView alloc]initWithTitle:@"下载出错误" message:strError delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
    }
    _isDownload = NO;
}

//下载结束处理
- (void)WHCDownload:(WHC_Download *)download filePath:(NSString *)filePath isSuccess:(BOOL)success{
    NSLog(@"filePath = %@",filePath);
    if(success){
        UIAlertView  * alert = [[UIAlertView alloc]initWithTitle:@"阿超已经帮你下载完成" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
    }
    _isDownload = NO;
}
@end
