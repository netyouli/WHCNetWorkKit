//
//  WHC_Xml.h
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
 * 说明: WHC_Xml dictionary对象转换为xml字符串
 * 默认 xml 编码类型为utf-8
 */

@interface WHC_Xml : NSObject

/**
 * 说明: dictionary对象转换为xml字符串
 * @param: dictionary 字典对象
 * @param: encode xml编码类型
 * @param: rootAttribute xml 根属性
 */

+ (NSString*)xmlWithDictionary:(NSDictionary*)dictionary
                        encode:(NSString*)encode
                 rootAttribute:(NSString*)rootAttribute;

/**
 * 说明: dictionary对象转换为xml字符串
 * @param: dictionary 字典对象
 * @param: encode xml编码类型
 */

+ (NSString*)xmlWithDictionary:(NSDictionary*)dictionary
                        encode:(NSString*)encode;

/**
 * 说明: dictionary对象转换为xml字符串
 * @param: dictionary 字典对象
 */

+ (NSString*)xmlWithDictionary:(NSDictionary*)dictionary;

/**
 * 说明: dictionary对象转换为xml字符串
 * @param: rootAttribute xml 根属性
 */

+ (NSString*)xmlWithDictionary:(NSDictionary*)dictionary
                 rootAttribute:(NSString*)rootAttribute;
@end
