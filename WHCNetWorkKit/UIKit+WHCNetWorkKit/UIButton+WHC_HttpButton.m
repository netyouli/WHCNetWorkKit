//
//  UIButton+WHC_HttpButton.m
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
#import "UIButton+WHC_HttpButton.h"
#import <objc/runtime.h>
#import "WHC_ImageCache.h"
#import "WHC_HttpManager.h"


@implementation UIButton (WHC_HttpButton)

- (NSMutableDictionary *)operationDictionary {
    NSMutableDictionary *operationDictionary = objc_getAssociatedObject([WHC_ImageCache shared], &loadOperationKey);
    if (!operationDictionary) {
        operationDictionary = [NSMutableDictionary dictionary];
        objc_setAssociatedObject([WHC_ImageCache shared],
                                 &loadOperationKey,
                                 operationDictionary,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return operationDictionary;
}

- (void)cancelOperationWithState:(UIControlState)state url:(NSString *)strUrl {
    NSMutableDictionary * operationDict = [self operationDictionary];
    WHC_BaseOperation * operation = [operationDict objectForKey:@(state).stringValue];
    if (operation) {
        if ([operation.strUrl isEqualToString:strUrl]){
            [[WHC_ImageCache shared].callBackDictionary removeObjectForKey:strUrl];
        }
        [operation cancelledRequest];
        [operationDict removeObjectForKey:@(state).stringValue];
    }
}

- (void)addOperation:(WHC_BaseOperation *)operation forState:(UIControlState)state {
    if (operation) {
        NSMutableDictionary * operationDict = [self operationDictionary];
        [operationDict setValue:operation forKey:@(state).stringValue];
    }
}

- (void)removeOperationForState:(UIControlState)state url:(NSString *)strUrl{
    NSMutableDictionary * operationDict = [self operationDictionary];
    [operationDict removeObjectForKey:@(state).stringValue];
    if ([operationDict.allKeys containsObject:@(state).stringValue]) {
        [[WHC_ImageCache shared].callBackDictionary removeObjectForKey:strUrl];
    }
}

- (void)whc_setImageWithUrl:(nonnull NSString *)strUrl
                   forState:(UIControlState)state {
    [self whc_setImageWithUrl:strUrl
                     forState:state placeholderImage:nil];
}

- (void)whc_setImageWithUrl:(nonnull NSString *)strUrl
                   forState:(UIControlState)state
           placeholderImage:(nullable UIImage *)image {
    if (!strUrl && !image){
        return;
    }
    [self cancelOperationWithState:state url:strUrl];
    if (image) {
        [self setImage:image forState:state];
    }
    if (![[WHC_HttpManager shared].failedUrls containsObject:strUrl]){
        __weak typeof(self) weakSelf = self;
        [[WHC_ImageCache shared]queryImageForUrl:strUrl state:state didFinished:^(UIImage *image , UIControlState state) {
            if (!image) {
                if (![WHC_ImageCache shared].callBackDictionary[strUrl]) {
                    [WHC_ImageCache shared].callBackDictionary[strUrl] = [NSMutableArray array];
                   WHC_BaseOperation * operation = [[WHC_HttpManager shared] get:strUrl didFinished: ^(WHC_BaseOperation *operation, NSData *data, NSError *error, BOOL isSuccess) {
                             if (!isSuccess) {
                                 if (operation) {
                                     [[WHC_ImageCache shared].callBackDictionary removeObjectForKey:operation.strUrl];
                                 }
                             }else {
                                 UIImage * image = [UIImage imageWithData:data];
                                 [weakSelf setImage:image forState:state];
                                 [[WHC_ImageCache shared] storeImage:image forUrl:operation.strUrl];
                                 NSMutableArray * urlCallBackArr = [[WHC_ImageCache shared].callBackDictionary[operation.strUrl] copy];
                                 [[WHC_ImageCache shared].callBackDictionary removeObjectForKey:operation.strUrl];
                                 typedef  void (^callBack)(UIImage * image);
                                 for (NSMutableDictionary * dict in urlCallBackArr) {
                                     callBack cb = dict[@"completed"];
                                     cb(image);
                                 }
                             }
                         }];
                    [weakSelf addOperation:operation forState:state];
                }
                NSMutableArray *callbacksForURL = [WHC_ImageCache shared].callBackDictionary[strUrl];
                NSMutableDictionary *callbacks = [NSMutableDictionary dictionary];
                callbacks[@"completed"] = ^(UIImage * image){
                    [weakSelf setImage:image forState:state];
                };
                [callbacksForURL addObject:callbacks];
                [WHC_ImageCache shared].callBackDictionary[strUrl] = callbacksForURL;
            }else {
                [self setImage:image forState:state];
            }
        }];
    }
}


- (void)whc_setBackgroundImageWithURL:(nonnull NSString *)strUrl
                             forState:(UIControlState)state {
    [self whc_setBackgroundImageWithURL:strUrl
                               forState:state placeholderImage:nil];
}

- (void)whc_setBackgroundImageWithURL:(nonnull NSString *)strUrl
                             forState:(UIControlState)state
                     placeholderImage:(nullable UIImage *)image {
    if (!strUrl && !image){
        return;
    }
    [self cancelOperationWithState:state url:strUrl];
    if (image) {
        [self setBackgroundImage:image forState:state];
    }
    if (![[WHC_HttpManager shared].failedUrls containsObject:strUrl]){
        __weak typeof(self) weakSelf = self;
        [[WHC_ImageCache shared]queryImageForUrl:strUrl state:state didFinished:^(UIImage *image , UIControlState state) {
            if (!image) {
                if (![WHC_ImageCache shared].callBackDictionary[strUrl]) {
                    [WHC_ImageCache shared].callBackDictionary[strUrl] = [NSMutableArray array];
                    WHC_BaseOperation * operation = [[WHC_HttpManager shared] get:strUrl didFinished: ^(WHC_BaseOperation *operation, NSData *data, NSError *error, BOOL isSuccess) {
                        if (!isSuccess) {
                            if (operation) {
                                [[WHC_ImageCache shared].callBackDictionary removeObjectForKey:operation.strUrl];
                            }
                        }else {
                            UIImage * image = [UIImage imageWithData:data];
                            [weakSelf setBackgroundImage:image forState:state];
                            [[WHC_ImageCache shared] storeImage:image forUrl:operation.strUrl];
                            NSMutableArray * urlCallBackArr = [[WHC_ImageCache shared].callBackDictionary[operation.strUrl] copy];
                            [[WHC_ImageCache shared].callBackDictionary removeObjectForKey:operation.strUrl];
                            typedef  void (^callBack)(UIImage * image);
                            for (NSMutableDictionary * dict in urlCallBackArr) {
                                callBack cb = dict[@"completed"];
                                cb(image);
                            }
                        }
                    }];
                    [weakSelf addOperation:operation forState:state];
                }
                NSMutableArray *callbacksForURL = [WHC_ImageCache shared].callBackDictionary[strUrl];
                NSMutableDictionary *callbacks = [NSMutableDictionary dictionary];
                callbacks[@"completed"] = ^(UIImage * image){
                    [weakSelf setBackgroundImage:image forState:state];
                };
                [callbacksForURL addObject:callbacks];
                [WHC_ImageCache shared].callBackDictionary[strUrl] = callbacksForURL;
            }else {
                [weakSelf setBackgroundImage:image forState:state];
            }
        }];
    }
}


@end
