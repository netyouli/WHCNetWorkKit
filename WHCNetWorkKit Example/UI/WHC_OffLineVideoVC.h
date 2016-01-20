//
//  WHC_OffLineVideoVC.h
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

#import <UIKit/UIKit.h>
#import "WHC_DownloadObject.h"

@protocol WHC_OffLineVideoCellDelegate <NSObject>

- (void)videoDownload:(NSError *)error index:(NSInteger)index strUrl:(NSString *)strUrl;
- (void)updateDownloadValue:(WHC_DownloadObject *)downloadObject index:(NSInteger)index;
- (void)videoPlayerIndex:(NSInteger)index;

@end

@interface WHC_OffLineVideoCell : UITableViewCell
@property (nonatomic , weak)id<WHC_OffLineVideoCellDelegate> delegate;
@property (nonatomic , assign)NSInteger index;
@end

@interface WHC_OffLineVideoVC : UIViewController

@end
