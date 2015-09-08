//
//  UIView+WHC_Loading.h
//  UIView+WHC_Loading
//
//  Created by 吴海超 on 15/3/25.
//  Copyright (c) 2015年 吴海超. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (WHC_Loading)

- (void)startLoading;
- (void)stopLoading;
- (void)startLoadingWithTxt:(NSString*)customTitle;
- (void)stopLoadingWithTxt;
- (void)startLoadingWithTxtUser:(NSString*)customTitle;
- (void)stopLoadingWithTxtUser;
- (void)startLoadingWithUser;
- (void)stopLoadingWithUser;
@end
