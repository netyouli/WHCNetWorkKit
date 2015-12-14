//
//  UIImageView+WHC_HttpImageView.m
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
#import "UIImageView+WHC_HttpImageView.h"
#import <objc/runtime.h>
#import "WHC_ImageCache.h"
#import "WHC_HttpManager.h"
#import <ImageIO/ImageIO.h>

@implementation UIImageView (WHC_HttpImageView)

- (NSMutableDictionary *)operationDictionary {
    NSMutableDictionary *operationDictionary = objc_getAssociatedObject([WHC_ImageCache shared], &loadOperationKey);
    if (!operationDictionary) {
        operationDictionary = [NSMutableDictionary dictionary];
        objc_setAssociatedObject([WHC_ImageCache shared], &loadOperationKey, operationDictionary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return operationDictionary;
}

- (void)cancelOperationWithUrl:(NSString *)strUrl {
    NSMutableDictionary * operationDictionary = [self operationDictionary];
    WHC_BaseOperation * operation = [operationDictionary objectForKey:strUrl];
    if (operation) {
        [[WHC_ImageCache shared].callBackDictionary removeObjectForKey:strUrl];
        [operation cancelledRequest];
        [operationDictionary removeObjectForKey:strUrl];
    }
}

- (void)addOperation:(WHC_BaseOperation *)operation url:(NSString *)strUrl{
    if (operation) {
        NSMutableDictionary * operationDict = [self operationDictionary];
        [operationDict setValue:operation forKey:strUrl];
    }
}

- (void)removeOperationForUrl:(NSString *)strUrl{
    NSMutableDictionary * operationDict = [self operationDictionary];
    [operationDict removeObjectForKey:strUrl];
    [[WHC_ImageCache shared].callBackDictionary removeObjectForKey:strUrl];
}

- (void)whc_setImageWithUrl:(nonnull NSString *)strUrl {
    [self whc_setImageWithUrl:strUrl placeholderImage:nil];
}

- (void)whc_setImageWithUrl:(nonnull NSString *)strUrl placeholderImage:(nullable UIImage *)image {
    if (!strUrl && !image){
        return;
    }
    [self cancelOperationWithUrl:strUrl];
    if (image) {
        [self setImage:image];
    }
    if (![[WHC_HttpManager shared].failedUrls containsObject:strUrl]){
        __weak typeof(self) weakSelf = self;
        [[WHC_ImageCache shared]queryImageForUrl:strUrl
                                           state:UIControlStateNormal
                                     didFinished:^(UIImage *image , UIControlState state) {
            if (!image) {
                if (![WHC_ImageCache shared].callBackDictionary[strUrl]) {
                    [WHC_ImageCache shared].callBackDictionary[strUrl] = [NSMutableArray array];
                    WHC_BaseOperation * operation = [[WHC_HttpManager shared] get:strUrl didFinished: ^(WHC_BaseOperation *operation, NSData *data, NSError *error, BOOL isSuccess) {
                        if (!isSuccess) {
                            if (operation) {
                                [[WHC_ImageCache shared].callBackDictionary removeObjectForKey:operation.strUrl];
                            }
                        }else {
                            UIImage * image = nil;
                            if ([[[WHC_HttpManager shared] fileFormatWithUrl:operation.strUrl] isEqualToString:@".gif"]) {
                                image = [self gifImageWithData:data];
                            }else {
                                image = [UIImage imageWithData:data];
                            }
                            [weakSelf setImage:image];
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
                    [weakSelf addOperation:operation url:strUrl];
                }
                NSMutableArray *callbacksForURL = [WHC_ImageCache shared].callBackDictionary[strUrl];
                NSMutableDictionary *callbacks = [NSMutableDictionary dictionary];
                callbacks[@"completed"] = ^(UIImage * image){
                    [weakSelf setImage:image];
                };
                [callbacksForURL addObject:callbacks];
                [WHC_ImageCache shared].callBackDictionary[strUrl] = callbacksForURL;
            }else {
                [self setImage:image];
            }
        }];
    }
}

- (void)setGifWithPath:(nonnull NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path];
    self.image = [self gifImageWithData:data];
}

- (UIImage *)gifImageWithData:(NSData *)gifData{
    NSMutableArray  * imageArr = [NSMutableArray array];
    CGImageSourceRef src = CGImageSourceCreateWithData((CFDataRef) gifData, NULL);
    NSTimeInterval animationDuration = 0.0;
    if (src) {
        NSUInteger frameCount = CGImageSourceGetCount(src);
        NSDictionary *gifProperties = (NSDictionary *) CFBridgingRelease(CGImageSourceCopyProperties(src, NULL));
        if(gifProperties) {
            NSDictionary *gifDictionary =[gifProperties objectForKey:(NSString*)kCGImagePropertyGIFDictionary];
            NSUInteger loopCount = [[gifDictionary objectForKey:(NSString*)kCGImagePropertyGIFLoopCount] integerValue];
            self.animationRepeatCount = loopCount;
            for (NSUInteger i = 0; i < frameCount; i++) {
                CGImageRef img = CGImageSourceCreateImageAtIndex(src, (size_t) i, NULL);
                if (img) {
                    UIImage *frameImage = [UIImage imageWithCGImage:img];
                    if(frameImage){
                        [imageArr addObject:frameImage];
                    }
                    NSDictionary *frameProperties = (NSDictionary *) CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(src, (size_t) i, NULL));
                    if (frameProperties) {
                        NSDictionary *frameDictionary = [frameProperties objectForKey:(NSString*)kCGImagePropertyGIFDictionary];
                        CGFloat delayTime = [[frameDictionary objectForKey:(NSString*)kCGImagePropertyGIFDelayTime] floatValue];
                        animationDuration += delayTime;
                    }
                    CGImageRelease(img);
                }
            }
        }
        CFRelease(src);
    }
    return [UIImage animatedImageWithImages:imageArr duration:animationDuration];
}

@end
