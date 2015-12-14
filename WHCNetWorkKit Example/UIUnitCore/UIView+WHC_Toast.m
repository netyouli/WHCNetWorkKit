//
//  UIView+WHC_Toast.m
//  UIView+WHC_Toast
//
//  Created by 吴海超 on 15/3/24.
//  Copyright (c) 2015年 吴海超. All rights reserved.
//

#import "UIView+WHC_Toast.h"
#define  KWHC_FONT_SIZE (14.0)
#define  KWHC_ANIMATION_TIME (0.1)
#define  KWHC_DURING (1.5)
@implementation UIView (WHC_Toast)
- (CATransform3D)loadTransform3D:(CGFloat)z{
    CATransform3D scale = CATransform3DIdentity;
    scale.m34 = -1.0 / 1000.0;
    CATransform3D transform = CATransform3DMakeTranslation(0.0, 0.0, z);
    return CATransform3DConcat(transform,scale);
}

- (void)toast:(NSString *)msg{
    [self toast:msg during:KWHC_DURING];
}

- (void)toast:(NSString *)msg postion:(WHC_TOAST_POSTION)postion{
    [self toast:msg during:KWHC_DURING postion:postion];
}

- (void)toast:(NSString *)msg type:(WHC_TOAST_TYPE)type{
    [self toast:msg during:KWHC_DURING postion:BOTTOM type:type];
}

- (void)toast:(NSString *)msg postion:(WHC_TOAST_POSTION)postion type:(WHC_TOAST_TYPE)type{
    [self toast:msg during:KWHC_DURING postion:postion type:type];
}

- (void)toast:(NSString *)msg during:(NSTimeInterval)during{
    [self toast:msg during:KWHC_DURING postion:BOTTOM];
}

- (void)toast:(NSString *)msg during:(NSTimeInterval)during postion:(WHC_TOAST_POSTION)postion{
    [self toast:msg during:KWHC_DURING postion:postion type:WHITE_FONT];
}

- (void)toast:(NSString *)msg during:(NSTimeInterval)during postion:(WHC_TOAST_POSTION)postion type:(WHC_TOAST_TYPE)type{
    [self createContentLabWithMessage:msg during:during postion:postion type:type];
}


- (UILabel*)createContentLabWithMessage:(NSString*)msg during:(NSTimeInterval)during postion:(WHC_TOAST_POSTION)postion type:(WHC_TOAST_TYPE)type{
    self.userInteractionEnabled = NO;
    CGSize      screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat     contentLabY = 0.0;
    UIColor   * fontColor = nil;
    UIColor   * backColor = nil;
    
    switch (postion) {
        case TOP:
            contentLabY = 100.0;
            break;
        case MIDDLE:
            contentLabY = screenSize.height / 2.0;
            break;
        case BOTTOM:
            contentLabY = screenSize.height - 100.0;
        break;
        default:
            break;
    }
    
    switch (type) {
        case WHITE_FONT:
            fontColor = [UIColor whiteColor];
            backColor = [UIColor blackColor];
            break;
        case BLACK_FONT:
            fontColor = [UIColor blackColor];
            backColor = [UIColor colorWithRed:240 / 255.0 green:240 / 255.0 blue:240 / 255.0 alpha:1.0];
        default:
            break;
    }
    
    CGFloat     pading = 10.0;
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    CGSize      msgSize = [msg sizeWithFont:[UIFont systemFontOfSize:KWHC_FONT_SIZE]
                          constrainedToSize:CGSizeMake(MAXFLOAT, 0)];
#pragma clang diagnostic pop
    CGFloat     contentLabWidth = msgSize.width + pading * 2.0;
    NSInteger   multiple = (NSInteger)(msgSize.width / (screenSize.width - pading * 2.0)) + 1;
    if(multiple > 1){
        contentLabWidth = screenSize.width - pading * 2.0;
    }
    UILabel * contentLab = [[UILabel alloc]initWithFrame:CGRectMake((screenSize.width - contentLabWidth) / 2.0,contentLabY,contentLabWidth,multiple * msgSize.height + pading)];
    contentLab.numberOfLines = 0;
    contentLab.backgroundColor = backColor;
    contentLab.textColor = fontColor;
    contentLab.font = [UIFont systemFontOfSize:KWHC_FONT_SIZE];
    contentLab.textAlignment = NSTextAlignmentCenter;
    contentLab.center = CGPointMake(screenSize.width / 2.0, contentLabY);
    contentLab.text = msg;
    contentLab.layer.cornerRadius = 8.0;
    contentLab.layer.masksToBounds = YES;
    contentLab.transform = CGAffineTransformMakeScale(0.5, 0.5);
    [self addSubview:contentLab];
    [UIView animateWithDuration:KWHC_ANIMATION_TIME animations:^{
        contentLab.transform = CGAffineTransformMakeScale(1.2, 1.2);
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            contentLab.transform = CGAffineTransformIdentity;
        }completion:^(BOOL finished) {
            [self performSelector:@selector(clearContentLab:) withObject:contentLab afterDelay:during];
        }];
        
    }];
    return contentLab;
}

- (void)clearContentLab:(UILabel *)contentLab{
    
    [UIView animateWithDuration:KWHC_ANIMATION_TIME animations:^{
        contentLab.transform = CGAffineTransformMakeScale(0.5, 0.5);
    } completion:^(BOOL finished) {
        [contentLab removeFromSuperview];
        self.userInteractionEnabled = YES;
    }];
}
@end
