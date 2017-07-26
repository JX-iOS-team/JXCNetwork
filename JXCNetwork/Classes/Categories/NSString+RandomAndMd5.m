//
//  NSString+RandomAndMd5.m
//  JXCNetwork
//
//  Created by 任我行 on 2017/7/25.
//  Copyright © 2017年 Redata Team @ JX Cloud. All rights reserved.
//
#import <CommonCrypto/CommonDigest.h>
#import "NSString+RandomAndMd5.h"

@implementation NSString (RandomAndMd5)

+ (NSString *)randomString{
    NSInteger temstamp = [NSDate date].timeIntervalSince1970;
    NSString *randomString = [NSString stringWithFormat:@"%ld%d", temstamp, arc4random() % 100];
    return randomString;
}

- (NSString *)stringToMD5{
    // 1.首先将字符串转换成UTF-8编码, 因为MD5加密是基于C语言的,所以要先把字符串转化成C语言的字符串
    const char *chars = [self UTF8String];
    
    // 2.然后创建一个字符串数组,接收MD5的值
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    // 3.计算MD5的值, 这是官方封装好的加密方法:把我们输入的字符串转换成16进制的32位数,然后存储到result中
    // 第一个参数:要加密的字符串
    // 第二个参数: 获取要加密字符串的长度
    // 第三个参数: 接收结果的数组
    CC_MD5(chars, (CC_LONG)strlen(chars), result);
    
    // 4.创建一个字符串保存加密结果
    NSMutableString *saveResult = [NSMutableString string];
    
    // 5.从result 数组中获取加密结果并放到 saveResult中
    // X表示十六进制，%02X  意思是不足两位将用0补齐，如果多余两位则不影响
    // NSLog("%02X", 0x888);  //888
    // NSLog("%02X", 0x4); //04
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [saveResult appendFormat:@"%02x", result[i]];
    }
    return saveResult;
}

@end
