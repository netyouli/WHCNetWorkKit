//
//  WHC_Json.h
//  WHCNetWorkKit
//
//  Created by 吴海超 on 15/4/29.
//  Copyright (c) 2015年 吴海超. All rights reserved.
//

/*
 *  qq:712641411
 *  gitHub:https://github.com/netyouli
 *  csdn:http://blog.csdn.net/windwhc/article/category/3117381
 */

#import <Foundation/Foundation.h>

/**
 * 说明: WHC_Json dictionary对象转换为json字符串
 */

@interface WHC_Json : NSObject


/**
 * 说明: dictionary对象转换为json字符串
 */
+ (NSString*)jsonWithDictionary:(NSDictionary*)dictionary;

@end
