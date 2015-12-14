//
//  UIView+WHC_Loading.m
//  UIView+WHC_Loading
//
//  Created by 吴海超 on 15/3/25.
//  Copyright (c) 2015年 吴海超. All rights reserved.
//

#import "UIView+WHC_Loading.h"
#define KWHC_LOADING_VIEW_SIZE (50.0)
#define KWHC_FONT_SIZE (15.0)
#define KWHC_LOADING_VIEW_SIZE_TXT (100.0)
#define KWHC_LOADING_LABLE_HEIGHT (15.0)
#define KWHC_LOADING_VIEW_CORNER (10.0)
#define KWHC_LOADING_VIEW_ALPHA (1.0)
#define KWHC_LOADING_VIEW_TAG (10000000)
#define KWHC_LOADING_PAD (15.0)
#define KWHC_LOADING_TXT (@"请稍等")
@implementation UIView (WHC_Loading)

- (UIView *)createLoadingViewWithIsTxt:(BOOL)isTxt customTitle:(NSString *)customTitle{
    CGSize  screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat backViewSize = KWHC_LOADING_VIEW_SIZE;
    if(isTxt){
        if(customTitle == nil){
            customTitle = KWHC_LOADING_TXT;
        }
        if(customTitle.length == 0){
            customTitle = KWHC_LOADING_TXT;
        }
        backViewSize = KWHC_LOADING_VIEW_SIZE_TXT;
    }
    UIView * backView = [[UIView alloc]initWithFrame:CGRectMake((screenSize.width - backViewSize) / 2.0, screenSize.height / 2.0, backViewSize, backViewSize)];
    backView.layer.cornerRadius = KWHC_LOADING_VIEW_CORNER;
    backView.backgroundColor = [UIColor blackColor];
    backView.alpha = KWHC_LOADING_VIEW_ALPHA;
    backView.clipsToBounds = YES;
    backView.tag = KWHC_LOADING_VIEW_TAG;
    
    UIActivityIndicatorView  * indicatorView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    if(isTxt){
        indicatorView.center = CGPointMake(CGRectGetWidth(backView.frame) / 2.0, (CGRectGetHeight(backView.frame) - KWHC_LOADING_LABLE_HEIGHT)/ 2.0);
    }else{
        indicatorView.center = CGPointMake(CGRectGetWidth(backView.frame) / 2.0, CGRectGetHeight(backView.frame) / 2.0);
    }
    [indicatorView startAnimating];
    [backView addSubview:indicatorView];
    
    if(isTxt){
        UILabel * labTxt = [[UILabel alloc]initWithFrame:CGRectMake(KWHC_LOADING_PAD, CGRectGetHeight(indicatorView.frame) + indicatorView.frame.origin.y+ 5.0, CGRectGetWidth(backView.frame) - KWHC_LOADING_PAD * 2.0, KWHC_LOADING_LABLE_HEIGHT)];
        labTxt.backgroundColor = [UIColor clearColor];
        labTxt.minimumScaleFactor = 0.2;
        labTxt.adjustsFontSizeToFitWidth = YES;
        labTxt.text = customTitle;
        labTxt.textAlignment = NSTextAlignmentCenter;
        labTxt.textColor = [UIColor whiteColor];
        [backView addSubview:labTxt];
    }
    return backView;
}

- (void)baseStartLoadingWithUser:(BOOL)isUser withIsTxt:(BOOL)isTxt customTitle:(NSString*)customTitle{
    UIView * loadingView = [self viewWithTag:KWHC_LOADING_VIEW_TAG];
    if(loadingView == nil){
        self.alpha = 1.0;
        self.userInteractionEnabled = isUser;
        [self addSubview:[self createLoadingViewWithIsTxt:isTxt customTitle:customTitle]];
    }
}

- (void)baseStopLoadingWithUser:(BOOL)isUser{
    UIView * clearView = [self viewWithTag:KWHC_LOADING_VIEW_TAG];
    if(clearView != nil){
        self.alpha = 1.0;
        self.userInteractionEnabled = isUser;
        [clearView removeFromSuperview];
        clearView = nil;
    }
}

- (void)startLoading{
    [self baseStartLoadingWithUser:NO withIsTxt:NO customTitle:nil];
}

- (void)stopLoading{
    [self baseStopLoadingWithUser:YES];
}

- (void)startLoadingWithTxt:(NSString*)customTitle{
    [self baseStartLoadingWithUser:NO withIsTxt:YES customTitle:customTitle];
}

- (void)stopLoadingWithTxt{
    [self stopLoading];
}

- (void)startLoadingWithTxtUser:(NSString*)customTitle{
    [self baseStartLoadingWithUser:YES withIsTxt:YES customTitle:customTitle];
}

- (void)stopLoadingWithTxtUser{
    [self stopLoading];
}

- (void)startLoadingWithUser{
    [self baseStartLoadingWithUser:YES withIsTxt:NO customTitle:nil];
}

- (void)stopLoadingWithUser{
    [self stopLoading];
}
@end
