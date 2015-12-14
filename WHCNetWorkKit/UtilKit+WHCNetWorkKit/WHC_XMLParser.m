//
//  WHC_XMLParse.m
//  WHCNetWorkKit
//
//  Created by 吴海超 on 15/4/28.
//  Copyright (c) 2015年 吴海超. All rights reserved.
//
/*
 *  qq:712641411
 *  gitHub:https://github.com/netyouli
 *  csdn:http://blog.csdn.net/windwhc/article/category/3117381
 */
#import "WHC_XMLParser.h"

#define kWHCXMLParserTextNodeKey		(@"WHC_TXT")
@interface WHC_XMLParser ()<NSXMLParserDelegate>{
    NSMutableArray            *     _dictArr;             //存放字典数组
    NSMutableString           *     _contentTxt;          //存放当前解析内容文字
    NSError                   *     _error;               //存放错误信息
    NSString                  *     _filterString;        //要过滤字符串
}

@end

@implementation WHC_XMLParser

- (instancetype)init{
    self = [super init];
    if(self){
        _error = [NSError new];
        _dictArr = [NSMutableArray new];
        _contentTxt = [NSMutableString new];
    }
    return self;
}

+ (NSDictionary *)dictionaryForXMLData:(NSData *)data{
    return [WHC_XMLParser dictionaryForXMLData:data options:0];
}

+ (NSDictionary *)dictionaryForXMLString:(NSString *)string{
    return [WHC_XMLParser dictionaryForXMLData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSDictionary *)dictionaryForXMLData:(NSData *)data options:(WHC_XMLParserOptions)options{
    WHC_XMLParser  * whc_xmlParser = [WHC_XMLParser new];
   return [whc_xmlParser startParserXML:data options:options];
}

+ (NSDictionary *)dictionaryForXMLString:(NSString *)string options:(WHC_XMLParserOptions)options{
    return [WHC_XMLParser dictionaryForXMLData:[string dataUsingEncoding:NSUTF8StringEncoding] options:options];
}

+ (NSDictionary *)dictionaryForXMLData:(NSData *)data filterString:(NSString *)filterString{
    return [WHC_XMLParser dictionaryForXMLData:data filterString:filterString options:0];
}

+ (NSDictionary *)dictionaryForXMLString:(NSString *)string filterString:(NSString *)filterString{
    return [WHC_XMLParser dictionaryForXMLString:string filterString:filterString options:0];
}

+ (NSDictionary *)dictionaryForXMLData:(NSData *)data filterString:(NSString *)filterString options:(WHC_XMLParserOptions)options{
    WHC_XMLParser  * whc_xmlParser = [WHC_XMLParser new];
    [whc_xmlParser setFilterString:filterString];
    return [whc_xmlParser startParserXML:data options:options];
}

+ (NSDictionary *)dictionaryForXMLString:(NSString *)string filterString:(NSString *)filterString options:(WHC_XMLParserOptions)options{
    return [WHC_XMLParser dictionaryForXMLData:[string dataUsingEncoding:NSUTF8StringEncoding] filterString:filterString options:options];
}

- (void)setFilterString:(NSString*)filterString{
    if(filterString){
        _filterString = [filterString copy];
    }
}


- (NSDictionary*)startParserXML:(NSData*)data options:(WHC_XMLParserOptions)options{
    [_dictArr addObject:[NSMutableDictionary new]];
    NSXMLParser  * xmlParser = [[NSXMLParser alloc]initWithData:data];
    xmlParser.delegate = self;
    xmlParser.shouldProcessNamespaces = (options & WHC_XMLParserOptionsProcessNamespaces);
    xmlParser.shouldReportNamespacePrefixes = (options & WHC_XMLParserOptionsReportNamespacePrefixes);
    xmlParser.shouldResolveExternalEntities = (options & WHC_XMLParserOptionsResolveExternalEntities);
    if([xmlParser parse]){
        [self XMLDataHandleEngine:_dictArr[0]];
        return _dictArr[0];
    }
    return nil;
}

/// xml数据处理引擎 清除多余无用key
- (void)XMLDataHandleEngine:(id)object{
    if([object isKindOfClass:[NSDictionary class]]){
        NSMutableDictionary * dict = object;
        NSInteger               count = dict.count;
        NSArray              * keyArr = [dict allKeys];
        for (NSInteger i = 0; i < count; i++) {
            NSString  * key = keyArr[i];
            id   subObject = dict[key];
            if([subObject isKindOfClass:[NSDictionary class]]){
                [self handleTopData:dict subDict:subObject index:i];
                [self XMLDataHandleEngine:subObject];
            }else if([subObject isKindOfClass:[NSArray class]]){
                [self XMLDataHandleEngine:subObject];
            }
        }
    }else if ([object isKindOfClass:[NSArray class]]){
        NSMutableArray * arrs = object;
        for (NSInteger i = 0; i < arrs.count; i++) {
            id subObject = arrs[i];
            [self XMLDataHandleEngine:subObject];
        }
    }
}

- (void)handleTopData:(NSMutableDictionary *)dict subDict:(NSDictionary*)subDict index:(NSInteger)index{
    NSArray  * subKeyArr = [subDict allKeys];
    NSArray  * keyArr = [dict allKeys];
    if(subKeyArr.count == 1 && [subKeyArr[0] isEqualToString:kWHCXMLParserTextNodeKey]){
        [dict setObject:subDict[kWHCXMLParserTextNodeKey] forKey:keyArr[index]];
    }else if(subKeyArr.count == 0){
        [dict setObject:@"" forKey:keyArr[index]];
    }
}

- (NSString*)getAvailableElementName:(NSString*)elementName{
    NSString  *   handleElementName = [elementName copy];
    if(_filterString){
        if([handleElementName containsString:_filterString]){
            return [handleElementName stringByReplacingOccurrencesOfString:_filterString withString:@""];
        }
    }
    return handleElementName;
}

- (NSDictionary*)getAvailableAttributeDict:(NSDictionary *)attributeDict{
    NSMutableDictionary  * dict = [attributeDict mutableCopy];
    NSArray  * keyArr = [dict allKeys];
    for (NSString * key in keyArr) {
        if([key containsString:kWHCCanFilterString]){
            NSString * nKey = nil;
            nKey = [key stringByReplacingOccurrencesOfString:kWHCCanFilterString withString:@"_"];
            id value = dict[key];
            [dict setObject:value forKey:nKey];
            [dict removeObjectForKey:key];
        }
    }
    return dict;
}

#pragma mark - NSXMLParserDelegate
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    NSString  *   handleElementName = [self getAvailableElementName:elementName];
    attributeDict = [self getAvailableAttributeDict:attributeDict];
    NSMutableDictionary  * parentDict = [_dictArr lastObject];
    NSMutableDictionary  * childDict = [NSMutableDictionary new];
    [childDict addEntriesFromDictionary:attributeDict];
    id existingValue = [parentDict objectForKey:handleElementName];
    if (existingValue){
        NSMutableArray *array = nil;
        if ([existingValue isKindOfClass:[NSMutableArray class]]){
            //使用存在的数组
            array = (NSMutableArray *) existingValue;
        }else{
            //不存在创建数组
            array = [NSMutableArray new];
            [array addObject:existingValue];
            // 替换子字典用数组
            [parentDict setObject:array forKey:handleElementName];
        }
        // 添加一个新的子字典
        [array addObject:childDict];
    }else{
        // 不存在插入新元素
        [parentDict setObject:childDict forKey:handleElementName];
    }
    
    // 跟新数组
    [_dictArr addObject:childDict];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    NSMutableDictionary *dictInProgress = [_dictArr lastObject];
    void (^saveValue)() = ^(){
        // 存储值
        NSString *valueTxt = [_contentTxt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if(valueTxt.length){
            [dictInProgress setObject:[valueTxt mutableCopy] forKey:kWHCXMLParserTextNodeKey];
        }
    };
    if (_contentTxt.length > 0){
        // 检测内容是否为json
        if(([_contentTxt hasPrefix:@"{"] && [_contentTxt hasSuffix:@"}"]) ||
           ([_contentTxt hasPrefix:@"["] && [_contentTxt hasSuffix:@"]"])){
            NSError  * err = nil;
            NSData * contentData = [_contentTxt dataUsingEncoding:NSUTF8StringEncoding];
            id contentObject = [NSJSONSerialization JSONObjectWithData:contentData options:NSJSONReadingMutableLeaves error:&err];
            if(err == nil){
                [dictInProgress setObject:contentObject forKey:kWHCXMLParserTextNodeKey];
            }else{
                saveValue();
            }
        }else{
            saveValue();
        }
        _contentTxt = [NSMutableString new];
    }
    // 移除当前
    [_dictArr removeLastObject];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    [_contentTxt appendString:string];
    
}
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError{
    if(parseError){
        NSLog(@"WHC_XMLParserError :%@",parseError);
    }
}
@end
