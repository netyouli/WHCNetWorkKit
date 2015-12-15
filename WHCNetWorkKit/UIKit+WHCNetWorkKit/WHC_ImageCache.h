//
//  WHC_ImageCache.h
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
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * 读取当前图片下载操作key
 */

static char loadOperationKey;

/**
 * 查询本地磁盘缓存和内存缓存结束回调块
 * @param: image 查询获取的图片对象
 * @param: state 图片显示对应的状态(这个只针对UIButton)
 */

typedef void(^WHCImageQueryFinished)(UIImage * _Nullable image , UIControlState state);

/**
 * 说明: WHC_ImageCache 网络下载图片缓存类
 */

@interface WHC_ImageCache : NSObject

/**
 * 说明: WHC_ImageCache 单例对象
 */

+ (nonnull instancetype)shared;

/**
 * 网络请求404错误集合(下次再遇到则不请求)
 */

@property (nonatomic , strong , nonnull) NSMutableSet * failedUrls;

/**
 * 异步图片下载回调块字典集合
 */

@property (nonatomic , strong , nonnull) NSMutableDictionary * callBackDictionary;

/**
 * 正在进行异步图片下载操作对象数组集合
 */

@property (nonatomic , strong , nonnull) NSMutableArray * runningOperationArray;

/**
 * 存储图片对象
 * @param: image 图片对象
 * @param: strUrl 图片下载地址
 */

- (void)storeImage:(nonnull UIImage *)image
            forUrl:(nonnull NSString *)strUrl;

/**
 * 查询本地磁盘缓存和内存缓存图片(异步查询)
 * @param: strUrl 图片下载地址
 * @param: state 图片对应得按钮状态(这个只针对UIButton)
 * @param: finishedBlock 查询完成回调块
 */

- (void)queryImageForUrl:(nonnull NSString *)strUrl
                   state:(UIControlState)state
             didFinished:(nullable WHCImageQueryFinished)finishedBlock;
@end
