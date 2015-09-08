//
//  UIScrollView+WHC_PullRefresh.h
//  PhoneBookBag
//
//  Created by 吴海超 on 14/8/20.
//  Copyright (c) 2014年 吴海超. All rights reserved.
//

/*
 *  qq:712641411
 *  iOS大神qq群:460122071
 *  gitHub:https://github.com/netyouli
 *  csdn:http://blog.csdn.net/windwhc/article/category/3117381
 */

#import <UIKit/UIKit.h>

typedef enum {
    HeaderStyle,
    FooterStyle,
    AllStyle,
    NoneStyle,
}WHCPullRefreshStyle;


@protocol  WHC_PullRefreshDelegate<NSObject>

@optional

//上拉刷新回调
- (void)WHCUpPullRequest;

//下拉刷新回调
- (void)WHCDownPullRequest;

@end


@interface UIScrollView (WHC_PullRefresh)
- (void)setWHCRefreshStyle:(WHCPullRefreshStyle)refreshStyle  delegate:(id<WHC_PullRefreshDelegate>)delegate;

- (void)WHCDidCompletedWithRefreshIsDownPull:(BOOL)isDown;
- (void)cancelledObsever;
- (void)addObserver;
@end
