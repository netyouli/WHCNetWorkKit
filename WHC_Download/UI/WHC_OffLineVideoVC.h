//
//  WHC_OffLineVideoVC.h
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

#import <UIKit/UIKit.h>
#import "WHC_ClientAccount.h"

@interface DownloadObject : NSObject
@property (nonatomic , strong)NSString * fileName;
@property (nonatomic , strong)NSString * currentDownloadLen;
@property (nonatomic , strong)NSString * totalLen;
@property (nonatomic , strong)NSString * speed;
@property (nonatomic , strong)NSString * downPath;
@property (nonatomic , assign)float      processValue;
@property (nonatomic , assign)DownloadState state;
@end

@interface WHC_OffLineVideoCell : UITableViewCell

@end

@interface WHC_OffLineVideoVC : UIViewController

@end
