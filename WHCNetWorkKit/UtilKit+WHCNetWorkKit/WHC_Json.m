//
//  WHC_Json.m
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

#import "WHC_Json.h"

@interface WHC_Json (){
    NSMutableString            * _jsonString;     //存放json字符串
}

@end

@implementation WHC_Json

- (instancetype)init{
    self = [super init];
    if(self){
        _jsonString  = [NSMutableString new];
        [_jsonString appendString:@"{"];
    }
    return self;
}

+ (NSString*)jsonWithDictionary:(NSDictionary *)dictionary{
    assert(dictionary);
    WHC_Json  * whcJson = [WHC_Json new];
    return [NSString stringWithFormat:@"%@}",[whcJson handleDictionaryEngine:dictionary]];
}

+ (NSDictionary *)dictionaryWithJsonData:(NSData *)jsonData {
    assert(jsonData);
    return [NSJSONSerialization JSONObjectWithData:jsonData
                                           options:NSJSONReadingAllowFragments error:nil];
}

+ (NSDictionary *)dictionaryWithJson:(NSString *)json {
    assert(json);
    return [WHC_Json dictionaryWithJsonData:[json dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSArray *)arrayWithJsonData:(NSData *)jsonData {
    assert(jsonData);
    return [NSJSONSerialization JSONObjectWithData:jsonData
                                           options:NSJSONReadingAllowFragments error:nil];
}

+ (NSArray *)arrayWithJson:(NSString *)json {
    assert(json);
    return [WHC_Json arrayWithJsonData:[json dataUsingEncoding:NSUTF8StringEncoding]];
}


- (NSString*)handleDictionaryEngine:(id)object{
    if([object isKindOfClass:[NSDictionary class]]){
        NSDictionary  * dict = object;
        NSInteger       count = dict.count;
        NSArray       * keyArr = [dict allKeys];
        for (NSInteger i = 0; i < count; i++) {
            id subObject = dict[keyArr[i]];
            if([subObject isKindOfClass:[NSDictionary class]]){
                [_jsonString appendFormat:@"\"%@\":{",keyArr[i]];
                [self handleDictionaryEngine:subObject];
                [_jsonString appendString:@"}"];
                if(i < count - 1){
                    [_jsonString appendString:@","];
                }
            }else if ([subObject isKindOfClass:[NSArray class]]){
                [_jsonString appendFormat:@"\"%@\":[",keyArr[i]];
                [self handleDictionaryEngine:subObject];
                [_jsonString appendString:@"]"];
                if(i < count - 1){
                    [_jsonString appendString:@","];
                }
            }else if([subObject isKindOfClass:[NSString class]]){
                [_jsonString appendFormat:@"\"%@\":\"%@\"",keyArr[i],subObject];
                if(i < count - 1){
                    [_jsonString appendString:@","];
                }
            }else if([subObject isKindOfClass:[NSNumber class]]){
                [_jsonString appendFormat:@"\"%@\":%@",keyArr[i],subObject];
                if(i < count - 1){
                    [_jsonString appendString:@","];
                }
            }
        }
    }else if([object isKindOfClass:[NSArray class]]){
        NSArray  * dictArr = object;
        NSInteger  count = dictArr.count;
        for (NSInteger i = 0; i < count; i++) {
            [_jsonString appendString:@"{"];
            [self handleDictionaryEngine:dictArr[i]];
            [_jsonString appendString:@"}"];
            if(i < count - 1){
                [_jsonString appendString:@","];
            }
        }
    }
    return _jsonString;
}

- (void)checkIsAddComma:(id)object{
    if(![object isKindOfClass:[NSArray class]] &&
       ![object isKindOfClass:[NSDictionary class]]){
        [_jsonString appendString:@","];
    }
}
@end
