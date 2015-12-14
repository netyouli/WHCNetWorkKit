//
//  UIButton+WHC_HttpButton.h
//  WHCNetWorkKit
//
//  Created by 吴海超 on 15/11/6.
//  Copyright © 2015年 吴海超. All rights reserved.
//
/*
 *  qq:712641411
 *  gitHub:https://github.com/netyouli
 *  csdn:http://blog.csdn.net/windwhc/article/category/3117381
 */
#import <UIKit/UIKit.h>

@interface UIButton (WHC_HttpButton)

/**
 * 说明: 给按钮设置网络图片 (没有默认图片)
 * @param strUrl 图片地址
 * @param state 图片对应的状态
 */

- (void)whc_setImageWithUrl:(nonnull NSString *)strUrl
                   forState:(UIControlState)state;

/**
 * 说明: 给按钮设置网络图片
 * @param strUrl 图片地址
 * @param state 图片对应的状态
 * @param placeholderImage 默认显示图片
 */

- (void)whc_setImageWithUrl:(nonnull NSString *)strUrl
                   forState:(UIControlState)state
           placeholderImage:(nullable UIImage *)image;


/**
 * 说明: 给按钮背景设置网络图片
 * @param strUrl 图片地址
 * @param state 图片对应的状态
 */

- (void)whc_setBackgroundImageWithURL:(nonnull NSString *)strUrl
                             forState:(UIControlState)state;

/**
 * 说明: 给按钮背景设置网络图片
 * @param strUrl 图片地址
 * @param state 图片对应的状态
 * @param placeholderImage 默认显示图片
 */

- (void)whc_setBackgroundImageWithURL:(nonnull NSString *)strUrl
                             forState:(UIControlState)state
                     placeholderImage:(nullable UIImage *)image;

@end
