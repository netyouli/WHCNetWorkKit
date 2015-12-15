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
+ (NSString *)jsonWithDictionary:(NSDictionary*)dictionary;

/**
 * 说明: jsonData对象转换为NSDictionary对象
 */
+ (NSDictionary *)dictionaryWithJsonData:(NSData *)jsonData;

/**
 * 说明: json字符串对象转换为NSDictionary对象
 */
+ (NSDictionary *)dictionaryWithJson:(NSString *)json;

/**
 * 说明: jsonData对象转换为NSArray对象
 */
+ (NSArray *)arrayWithJsonData:(NSData *)jsonData;

/**
 * 说明: json字符串对象转换为NSArray对象
 */
+ (NSArray *)arrayWithJson:(NSString *)json;

@end
