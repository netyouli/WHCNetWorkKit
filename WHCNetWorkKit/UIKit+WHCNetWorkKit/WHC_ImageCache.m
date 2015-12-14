//
//  WHC_ImageCache.m
//  WHCNetWorkKit
//
//  Created by 吴海超 on 15/11/6.
//  Copyright © 2015年 吴海超. All rights reserved.
//
/*
 *  qq:712641411
 *  gitHub:https://github.com/netyouli
 *  csdn:http://blog.csdn.net/windwhc/article/category/3117381
 */
#import "WHC_ImageCache.h"
#import <CommonCrypto/CommonDigest.h>
#import "WHC_HttpManager.h"
#import <objc/runtime.h>

#define kWHCImageCachePath (@"WHCImageCache")



@interface WHC_Cache : NSCache

@end

@implementation WHC_Cache

- (id)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidReceiveMemoryWarningNotification
                                                  object:nil];
}

@end

@interface WHC_ImageCache (){
    NSFileManager  * _fileManager;
    dispatch_queue_t _fileQueue;
}
@property (nonatomic , strong) WHC_Cache * memCache;
@property (nonatomic , strong) NSString * diskCachePath;

@end

static inline NSUInteger WHCCacheCostForImage(UIImage *image) {
    return image.size.height * image.size.width * image.scale * image.scale;
}

@implementation WHC_ImageCache

+ (nonnull instancetype)shared {
    static WHC_ImageCache * imageCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageCache = [WHC_ImageCache new];
    });
    return imageCache;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _callBackDictionary = [NSMutableDictionary dictionary];
        _runningOperationArray = [NSMutableArray array];
        _fileQueue = dispatch_queue_create([NSStringFromClass(self.class) UTF8String], NULL);
        _failedUrls = [NSMutableSet set];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _diskCachePath = [paths[0] stringByAppendingPathComponent:kWHCImageCachePath];
        
        _memCache = [WHC_Cache new];
        _memCache.name = kWHCImageCachePath;
        
        dispatch_sync(_fileQueue, ^{
            _fileManager = [NSFileManager new];
            if (![_fileManager fileExistsAtPath:_diskCachePath]) {
                [_fileManager createDirectoryAtPath:_diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
            }
        });
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearMemory)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cleanDisk)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
    }
    return self;
}

- (NSString *)cachedImageFileNameForUrl:(NSString *)strUrl {
    NSMutableString * cachedFileName = [NSMutableString string];
    if (strUrl != nil) {
        const char * cStr = strUrl.UTF8String;
        unsigned char buffer[CC_MD5_DIGEST_LENGTH];
        memset(buffer, 0x00, CC_MD5_DIGEST_LENGTH);
        CC_MD5(cStr, (CC_LONG)(strlen(cStr)), buffer);
        for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
            [cachedFileName appendFormat:@"%02x",buffer[i]];
        }
        return cachedFileName;
    }
    return nil;
}

- (UIImage *)diskImageForUrl:(NSString *)strUrl {
    NSString * filePath = [_diskCachePath stringByAppendingPathComponent:[self cachedImageFileNameForUrl:strUrl]];
    BOOL isDirectory = NO;
    if ([_fileManager fileExistsAtPath:filePath isDirectory:&isDirectory]) {
        NSData * imageData = [NSData dataWithContentsOfFile:filePath];
        if (imageData){
            return [UIImage imageWithData:imageData];
        }else {
            return nil;
        }
    }
    return nil;
}

- (void)storeImage:(UIImage *)image forUrl:(NSString *)strUrl {
    if (!image || !strUrl){
        return;
    }
    [self.memCache setObject:image forKey:strUrl cost:WHCCacheCostForImage(image)];
    dispatch_async(_fileQueue, ^{
        NSString * filePath = [_diskCachePath stringByAppendingPathComponent:[self cachedImageFileNameForUrl:strUrl]];
        NSString * imageFormat = [[WHC_HttpManager shared] fileFormatWithUrl:strUrl];
        NSData * imageData = nil;
        if ([imageFormat isEqualToString:@".png"]) {
            imageData = UIImagePNGRepresentation(image);
        }else {
            imageData = UIImageJPEGRepresentation(image, 1.0);
        }
        [_fileManager createFileAtPath:filePath contents:imageData attributes:NULL];
    });
}

- (void)queryImageForUrl:(NSString *)strUrl state:(UIControlState)state didFinished:(WHCImageQueryFinished)finishedBlock {
    if (!finishedBlock) {
        return;
    }
    if (!strUrl) {
        finishedBlock(nil , state);
        return;
    }
    
    UIImage * image = [self.memCache objectForKey:strUrl];
    if (image) {
        finishedBlock(image , state);
    }else {
        dispatch_async(_fileQueue, ^{
            @autoreleasepool {
                UIImage *diskImage = [self diskImageForUrl:strUrl];
                if (diskImage) {
                    [self.memCache setObject:diskImage forKey:strUrl cost:WHCCacheCostForImage(diskImage)];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    finishedBlock(diskImage , state);
                });
            }
        });
    }
}

- (void)clearMemory {
    [self.memCache removeAllObjects];
}

- (void)cleanDisk {
    dispatch_async(_fileQueue, ^{
        [_fileManager removeItemAtPath:_diskCachePath error:nil];
        [_fileManager createDirectoryAtPath:self.diskCachePath
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:NULL];
    });
}
@end
