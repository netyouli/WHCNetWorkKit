//
//  UIView+WHC_Toast.h
//  UIView+WHC_Toast
//
//  Created by 吴海超 on 15/3/24.
//  Copyright (c) 2015年 吴海超. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum{
    TOP,
    MIDDLE,
    BOTTOM
}WHC_TOAST_POSTION;

typedef enum {
    WHITE_FONT,
    BLACK_FONT,
}WHC_TOAST_TYPE;

@interface UIView (WHC_Toast)
- (void)toast:(NSString *)msg;
- (void)toast:(NSString *)msg postion:(WHC_TOAST_POSTION)postion;
- (void)toast:(NSString *)msg type:(WHC_TOAST_TYPE)type;
- (void)toast:(NSString *)msg postion:(WHC_TOAST_POSTION)postion type:(WHC_TOAST_TYPE)type;
- (void)toast:(NSString *)msg during:(NSTimeInterval)during;
- (void)toast:(NSString *)msg during:(NSTimeInterval)during postion:(WHC_TOAST_POSTION)postion;
- (void)toast:(NSString *)msg during:(NSTimeInterval)during postion:(WHC_TOAST_POSTION)postion type:(WHC_TOAST_TYPE)type;
@end
