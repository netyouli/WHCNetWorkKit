//
//  WHC_DataModel.h
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
 * 说明: WHC_DataModel json/xml转模型类对象
 */

@interface WHC_DataModel : NSObject

/**
 * 说明: json/xml (data)数据对象转模型类对象数组
 * @param: data json/xml数据对象
 * @param: className 模型类
 */

+ (NSArray *)dataModelWithArrayData:(NSData *)data className:(Class)className;

/**
 * 说明: json/xml (array)数组对象转模型类对象数组
 * @param: array json/xml数组对象
 * @param: className 模型类
 */

+ (NSArray*)dataModelWithArray:(NSArray*)array className:(Class)className;

/**
 * 说明: json/xml (dictionary)字典对象转模型类对象
 * @param: data json/xml字典对象
 * @param: className 模型类
 */

+ (id)dataModelWithDictionary:(NSDictionary*)dictionary className:(Class)className;

/**
 * 说明: json/xml (data)字典对象转模型类对象
 * @param: data json/xml字典对象
 * @param: className 模型类
 */

+ (id)dataModelWithDictionaryData:(NSData *)data className:(Class)className;

@end
