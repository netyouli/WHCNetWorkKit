//
//  UIImageView+WHC_HttpImageView.h
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

@interface UIImageView (WHC_HttpImageView)

/**
 * 说明: 给UIImageView背景设置网络图片
 * @param strUrl 图片地址
 */

- (void)whc_setImageWithUrl:(nonnull NSString *)strUrl ;

/**
 * 说明: 给UIImageView背景设置网络图片
 * @param strUrl 图片地址
 * @param placeholderImage 默认显示图片
 */

- (void)whc_setImageWithUrl:(nonnull NSString *)strUrl placeholderImage:(nullable UIImage *)image;

/**
 * 说明: 给UIImageView 设置本地git图片
 * @param path gif本地路径
 */
- (void)setGifWithPath:(nonnull NSString *)path;

@end
