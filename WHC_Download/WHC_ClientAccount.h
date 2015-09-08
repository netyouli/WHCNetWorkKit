//
//  ClientAccount.h
//  PhoneBookBag
//
//  Created by 吴海超 on 15/7/6.
//  Copyright (c) 2015年 吴海超. All rights reserved.
//

/*
 *  qq:712641411
 *  iOS大神qq群:460122071
 *  gitHub:https://github.com/netyouli
 *  csdn:http://blog.csdn.net/windwhc/article/category/3117381
 */

#import <UIKit/UIKit.h>

#define kGrade            (@"Grade")
#define kClazz            (@"Clazz")
#define kAccount          (@"Account")
#define kPassword         (@"Password")

#define Account             ([WHC_ClientAccount sharedClientAccount])                  //账户对象

typedef enum _DownloadState:NSInteger{
    
    NoneState = 1,
    Downloading ,           //正在下载
    DownloadCompleted,      //下载完成
    DownloadUncompleted,    //下载未完成
    DownloadWaitting        //等待下载
    
}DownloadState;

@interface WHC_ClientAccount : NSObject

+ (instancetype)sharedClientAccount;

@property (nonatomic , strong , readonly)NSString * videoFolder;         //视频文件夹
@property (nonatomic , strong , readonly)NSString * videoFileRecordPath; //视频下载记录文件
- (BOOL)existFileName:(NSString *)fileName;

- (BOOL)downloadStateVoideFile:(NSString *)fileName;

- (void)saveDownloadRecord;
@end
